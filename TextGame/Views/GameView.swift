//
//  GameView.swift
//  TextGame
//
//  Created by ant on 2026/3/5.
//

import SwiftUI
import SwiftData

/// 遊戲主畫面，上半部為訊息輸出區域，下半部為使用者操作按鈕
struct GameView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \SaveSlot.slotIndex) private var saveSlots: [SaveSlot]

    // MARK: - 存檔槽位
    let slotIndex: Int

    // MARK: - 訊息列表（上限 50 筆）
    @State private var messages: [String] = ["歡迎來到 TextGame 的世界。"]

    // MARK: - 場景狀態
    @State private var currentSceneId: String = "village"

    // MARK: - 彈窗控制
    @State private var showMoveSheet = false
    @State private var showAttackSheet = false
    @State private var showTalkSheet = false

    // MARK: - 場景與怪物資料（從 JSON 載入）

    private let scenes: [String: GameScene] = SceneTemplateLoader.shared.allGameScenes()
    private let sceneLoader = SceneTemplateLoader.shared
    private let monsterLoader = MonsterTemplateLoader.shared
    private let npcLoader = NPCTemplateLoader.shared

    // MARK: - 計算屬性

    private var currentScene: GameScene {
        scenes[currentSceneId] ?? scenes["village"]!
    }

    private var currentSaveSlot: SaveSlot? {
        saveSlots.first { $0.slotIndex == slotIndex }
    }

    /// 目前場景中可攻擊的怪物列表
    private var availableMonsters: [MonsterTemplate] {
        monsterLoader.monstersInScene(currentSceneId)
    }

    /// 目前場景可前往的地點
    private var availableExits: [SceneExit] {
        currentScene.exits
    }

    /// 目前場景中可談話的 NPC 列表
    private var availableNPCs: [NPCTemplate] {
        let npcIds = sceneLoader.npcIdsInScene(currentSceneId)
        return npcLoader.templates(for: npcIds)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // 上半部：訊息輸出區域
            messageListView

            Divider()

            // 下半部：操作按鈕區域
            actionButtonsView
        }
        .navigationTitle(currentScene.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showMoveSheet) {
            moveSheet
        }
        .sheet(isPresented: $showAttackSheet) {
            attackSheet
        }
        .sheet(isPresented: $showTalkSheet) {
            talkSheet
        }
        .onAppear {
            appendMessage(currentScene.description)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .inactive {
                saveGame()
            }
        }
    }

    // MARK: - 訊息列表

    private var messageListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                        Text(message)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(messageColor(for: message))
                            .id(index)
                    }
                }
                .padding()
            }
            .onChange(of: messages.count) {
                withAnimation {
                    if let lastIndex = messages.indices.last {
                        proxy.scrollTo(lastIndex, anchor: .bottom)
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - 操作按鈕

    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            // 第一排：移動、攻擊、談話
            HStack(spacing: 12) {
                actionButton(icon: "figure.walk", title: "移動") {
                    showMoveSheet = true
                }

                actionButton(icon: "burst.fill", title: "攻擊") {
                    if availableMonsters.isEmpty {
                        appendMessage("這裡沒有可以攻擊的目標。")
                    } else {
                        showAttackSheet = true
                    }
                }

                actionButton(icon: "bubble.left.fill", title: "談話") {
                    if availableNPCs.isEmpty {
                        appendMessage("這裡沒有可以交談的對象。")
                    } else {
                        showTalkSheet = true
                    }
                }
            }

            // 第二排：技能、物品、屬性
            HStack(spacing: 12) {
                NavigationLink {
                    SkillView()
                } label: {
                    actionButtonLabel(icon: "flame.fill", title: "技能")
                }

                NavigationLink {
                    InventoryView()
                } label: {
                    actionButtonLabel(icon: "bag.fill", title: "物品")
                }

                NavigationLink {
                    StatusView()
                } label: {
                    actionButtonLabel(icon: "person.fill", title: "屬性")
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - 按鈕元件

    private func actionButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            actionButtonLabel(icon: icon, title: title)
        }
    }

    private func actionButtonLabel(icon: String, title: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .foregroundColor(.primary)
        .cornerRadius(10)
    }

    // MARK: - 移動彈窗

    private var moveSheet: some View {
        NavigationStack {
            List(availableExits) { exit in
                Button {
                    moveToScene(exit.destinationId)
                    showMoveSheet = false
                } label: {
                    Label(exit.label, systemImage: "arrow.right.circle")
                }
            }
            .navigationTitle("移動")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        showMoveSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - 攻擊彈窗

    private var attackSheet: some View {
        NavigationStack {
            List(availableMonsters) { monster in
                Button {
                    attackMonster(monster)
                    showAttackSheet = false
                } label: {
                    Label(monster.name, systemImage: monster.icon)
                }
            }
            .navigationTitle("選擇目標")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        showAttackSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - 談話彈窗

    private var talkSheet: some View {
        NavigationStack {
            List(availableNPCs) { npc in
                Button {
                    talkToNPC(npc)
                    showTalkSheet = false
                } label: {
                    HStack {
                        Label(npc.name, systemImage: npc.icon)
                        Spacer()
                        Text(npc.title)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("談話")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        showTalkSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - 動作處理

    private func moveToScene(_ sceneId: String) {
        guard let scene = scenes[sceneId] else { return }
        currentSceneId = sceneId
        // 同步更新角色位置
        if let character = currentSaveSlot?.character {
            character.currentSceneId = sceneId
        }
        appendMessage("——————————")
        appendMessage("你來到了【\(scene.name)】")
        appendMessage(scene.description)
    }

    private func attackMonster(_ monster: MonsterTemplate) {
        appendMessage("你對\(monster.name)發起了攻擊！")
        // TODO: 接入戰鬥系統
        appendMessage("\(monster.name)受到了傷害。")
    }

    private func talkToNPC(_ npc: NPCTemplate) {
        let playerGuild = currentSaveSlot?.character?.guild
        let dialogues = npc.availableDialogues(playerGuild: playerGuild)

        appendMessage("——————————")
        appendMessage("你向【\(npc.name)】搭話。")

        if dialogues.isEmpty {
            appendMessage("\(npc.name)看了你一眼，沒有說話。")
        } else {
            // 隨機選擇一段符合條件的對話
            if let dialogue = dialogues.randomElement() {
                appendMessage("「\(dialogue.text)」")
            }
        }
    }

    // MARK: - 存檔

    private func saveGame() {
        guard let slot = currentSaveSlot, let character = slot.character else { return }
        slot.updateSaveInfo(character: character, playTime: slot.playTime)
        try? modelContext.save()
    }

    // MARK: - 訊息管理

    /// 添加訊息，超過 50 筆時移除最舊的
    private func appendMessage(_ text: String) {
        messages.append(text)
        if messages.count > 50 {
            messages.removeFirst(messages.count - 50)
        }
    }

    /// 根據訊息內容決定文字顏色
    private func messageColor(for message: String) -> Color {
        if message.hasPrefix("你對") || message.contains("攻擊") {
            return .red
        } else if message.hasPrefix("你來到了") {
            return .blue
        } else if message.hasPrefix("你向【") {
            return .cyan
        } else if message.hasPrefix("「") {
            return .green
        } else if message.hasPrefix("——") {
            return .secondary
        }
        return .primary
    }
}

#Preview {
    NavigationStack {
        GameView(slotIndex: 1)
    }
    .modelContainer(for: [PlayerCharacter.self, Skill.self, GameItem.self, SaveSlot.self], inMemory: true)
}
