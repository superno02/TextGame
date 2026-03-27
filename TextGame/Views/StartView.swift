//
//  StartView.swift
//  TextGame
//
//  Created by ant on 2026/3/5.
//

import SwiftUI
import SwiftData

/// 遊戲開始頁面，提供「開始遊戲」與「讀取存檔」兩個選項
struct StartView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SaveSlot.slotIndex) private var saveSlots: [SaveSlot]

    @State private var isGameStarted = false
    @State private var showLoadSheet = false
    @State private var activeSlotIndex: Int = 0
    @State private var slotToDelete: SaveSlot?
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()

                // 遊戲標題
                Text("TextGame")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Spacer()

                // 選單按鈕
                VStack(spacing: 16) {
                    Button {
                        startNewGame()
                    } label: {
                        Text("開始遊戲")
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }

                    Button {
                        showLoadSheet = true
                    } label: {
                        Text("讀取存檔")
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.secondary.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 40)

                Spacer()
            }
            .navigationDestination(isPresented: $isGameStarted) {
                GameView(slotIndex: activeSlotIndex)
            }
            .sheet(isPresented: $showLoadSheet) {
                loadSaveSheet
            }
        }
    }

    // MARK: - 讀取存檔彈窗

    private var loadSaveSheet: some View {
        NavigationStack {
            List {
                ForEach(1...5, id: \.self) { slotIndex in
                    let slot = saveSlots.first { $0.slotIndex == slotIndex }
                    Button {
                        if slot != nil {
                            activeSlotIndex = slotIndex
                            showLoadSheet = false
                            isGameStarted = true
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("槽位 \(slotIndex)")
                                    .font(.headline)
                                if let slot {
                                    Text(slot.characterName)
                                        .font(.subheadline)
                                    Text(slot.savedAt, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("空")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            if slot != nil {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .disabled(slot == nil)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if let slot {
                            Button(role: .destructive) {
                                slotToDelete = slot
                                showDeleteConfirmation = true
                            } label: {
                                Label("刪除", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("讀取存檔")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        showLoadSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .alert("確認刪除", isPresented: $showDeleteConfirmation) {
            Button("刪除", role: .destructive) {
                if let slot = slotToDelete {
                    deleteSaveSlot(slot)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            if let slot = slotToDelete {
                Text("確定要刪除槽位 \(slot.slotIndex) 的存檔「\(slot.characterName)」嗎？此操作無法復原。")
            }
        }
    }

    // MARK: - 刪除存檔

    private func deleteSaveSlot(_ slot: SaveSlot) {
        modelContext.delete(slot)
        try? modelContext.save()
        slotToDelete = nil
    }

    // MARK: - 開始新遊戲

    private func startNewGame() {
        // 找第一個空的槽位
        let usedSlots = Set(saveSlots.map(\.slotIndex))
        guard let emptySlot = (1...5).first(where: { !usedSlots.contains($0) }) else {
            // 五個槽位都滿了，暫不處理
            return
        }

        let character = PlayerCharacter(name: "路人甲", guild: .none)
        modelContext.insert(character)

        let saveSlot = SaveSlot(slotIndex: emptySlot, character: character)
        modelContext.insert(saveSlot)

        activeSlotIndex = emptySlot
        isGameStarted = true
    }
}

#Preview {
    StartView()
        .modelContainer(for: [
            PlayerCharacter.self,
            Skill.self,
            GameItem.self,
            SaveSlot.self
        ], inMemory: true)
}
