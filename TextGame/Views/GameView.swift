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

    // MARK: - 存檔槽位

    let slotIndex: Int

    // MARK: - 遊戲引擎

    @State private var engine: GameEngine?

    // MARK: - Body

    var body: some View {
        Group {
            if let engine {
                gameContent(engine: engine)
            } else {
                ProgressView("載入中…")
            }
        }
        .task {
            if engine == nil {
                engine = GameEngine(slotIndex: slotIndex, modelContext: modelContext)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .inactive {
                engine?.saveGame()
            }
        }
    }

    // MARK: - 遊戲主內容

    @ViewBuilder
    private func gameContent(engine: GameEngine) -> some View {
        VStack(spacing: 0) {
            // 上半部：訊息輸出區域
            messageListView(engine: engine)

            Divider()

            // 下半部：操作按鈕區域
            actionButtonsView(engine: engine)
        }
        .navigationTitle(engine.currentScene.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: Binding(
            get: { engine.showMoveSheet },
            set: { engine.showMoveSheet = $0 }
        )) {
            moveSheet(engine: engine)
        }
        .sheet(isPresented: Binding(
            get: { engine.showAttackSheet },
            set: { engine.showAttackSheet = $0 }
        )) {
            attackSheet(engine: engine)
        }
        .sheet(isPresented: Binding(
            get: { engine.showTalkSheet },
            set: { engine.showTalkSheet = $0 }
        )) {
            talkSheet(engine: engine)
        }
        .onAppear {
            engine.onAppear()
        }
    }

    // MARK: - 訊息列表

    private func messageListView(engine: GameEngine) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(engine.messages.enumerated()), id: \.offset) { index, message in
                        Text(message)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(messageColor(for: message))
                            .id(index)
                    }
                }
                .padding()
            }
            .onChange(of: engine.messages.count) {
                withAnimation {
                    if let lastIndex = engine.messages.indices.last {
                        proxy.scrollTo(lastIndex, anchor: .bottom)
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - 操作按鈕

    private func actionButtonsView(engine: GameEngine) -> some View {
        VStack(spacing: 12) {
            // 第一排：移動、攻擊、談話
            HStack(spacing: 12) {
                actionButton(icon: "figure.walk", title: "移動") {
                    if engine.isInCombat {
                        engine.appendMessage("戰鬥中無法移動！")
                    } else {
                        engine.showMoveSheet = true
                    }
                }

                actionButton(icon: "burst.fill", title: "攻擊") {
                    if engine.isInCombat {
                        engine.appendMessage("你正在戰鬥中！")
                    } else if engine.availableMonsters.isEmpty {
                        engine.appendMessage("這裡沒有可以攻擊的目標。")
                    } else {
                        engine.showAttackSheet = true
                    }
                }

                actionButton(icon: "bubble.left.fill", title: "談話") {
                    if engine.availableNPCs.isEmpty {
                        engine.appendMessage("這裡沒有可以交談的對象。")
                    } else {
                        engine.showTalkSheet = true
                    }
                }
            }

            // 第二排：技能、物品、屬性
            HStack(spacing: 12) {
                if let character = engine.currentSaveSlot?.character {
                    NavigationLink {
                        SkillView(character: character)
                    } label: {
                        actionButtonLabel(icon: "flame.fill", title: "技能")
                    }

                    NavigationLink {
                        InventoryView(character: character)
                    } label: {
                        actionButtonLabel(icon: "bag.fill", title: "物品")
                    }

                    NavigationLink {
                        StatusView(character: character)
                    } label: {
                        actionButtonLabel(icon: "person.fill", title: "屬性")
                    }
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

    private func moveSheet(engine: GameEngine) -> some View {
        NavigationStack {
            List(engine.availableExits) { exit in
                Button {
                    engine.moveToScene(exit.destinationId)
                    engine.showMoveSheet = false
                } label: {
                    Label(exit.label, systemImage: "arrow.right.circle")
                }
            }
            .navigationTitle("移動")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        engine.showMoveSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - 攻擊彈窗

    private func attackSheet(engine: GameEngine) -> some View {
        NavigationStack {
            List(engine.availableMonsters) { monster in
                Button {
                    engine.attackMonster(monster)
                    engine.showAttackSheet = false
                } label: {
                    Label {
                        VStack(alignment: .leading) {
                            Text(monster.name)
                            Text("等級 \(monster.level) | HP \(monster.health)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: monster.icon)
                    }
                }
            }
            .navigationTitle("選擇目標")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        engine.showAttackSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - 談話彈窗

    private func talkSheet(engine: GameEngine) -> some View {
        NavigationStack {
            List(engine.availableNPCs) { npc in
                Button {
                    engine.talkToNPC(npc)
                    engine.showTalkSheet = false
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
                        engine.showTalkSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - 訊息顏色（純 UI 邏輯）

    /// 根據訊息內容決定文字顏色
    private func messageColor(for message: String) -> Color {
        if message.hasPrefix("[系統錯誤]") {
            return .red
        } else if message.contains("等階提升") || message.hasPrefix("屬性成長：") || message.contains("已完全回復") {
            return .yellow
        } else if message.contains("倒下了") {
            return .orange
        } else if message.contains("擊敗了") || message.contains("意識逐漸模糊") || message.contains("醒來") {
            return .purple
        } else if message.hasPrefix("你獲得了") {
            return .yellow
        } else if message.contains("閃開了") {
            return .mint
        } else if message.hasPrefix("你對") || message.contains("發起了攻擊") {
            return .red
        } else if message.contains("造成了") && message.contains("點傷害") {
            return .red
        } else if message.contains("攻擊被") || message.contains("攻擊落空") {
            return .orange
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
