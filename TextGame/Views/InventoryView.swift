//
//  InventoryView.swift
//  TextGame
//
//  Created by ant on 2026/3/5.
//

import SwiftUI
import SwiftData

/// 背包頁面，顯示角色攜帶的物品與裝備
struct InventoryView: View {
    let character: PlayerCharacter

    /// 已裝備的物品
    private var equippedItems: [GameItem] {
        character.inventory.filter { $0.isEquipped }
    }

    /// 背包中未裝備的物品
    private var backpackItems: [GameItem] {
        character.inventory.filter { !$0.isEquipped }
    }

    var body: some View {
        List {
            Section("裝備中") {
                ForEach(EquipmentSlot.allCases, id: \.self) { slot in
                    let item = equippedItems.first { $0.equipSlot == slot }
                    equipmentRow(slot: slot, item: item)
                }
            }

            Section("背包物品") {
                if backpackItems.isEmpty {
                    Text("背包中沒有物品")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(backpackItems) { item in
                        itemRow(item)
                    }
                }
            }
        }
        .navigationTitle("背包")
    }

    // MARK: - 裝備列

    private func equipmentRow(slot: EquipmentSlot, item: GameItem?) -> some View {
        HStack {
            Text(slot.displayName)
                .frame(width: 50, alignment: .leading)
            if let item {
                Text(item.name)
                Spacer()
                if item.attackPower > 0 {
                    Text("攻擊 +\(item.attackPower)")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                if item.defensePower > 0 {
                    Text("防禦 +\(item.defensePower)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            } else {
                Text("—")
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
    }

    // MARK: - 物品列

    private func itemRow(_ item: GameItem) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.name)
                Text(item.itemDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if item.isStackable {
                Text("x\(item.stackCount)")
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        InventoryView(character: PlayerCharacter(name: "預覽角色", guild: .warrior))
    }
    .modelContainer(for: [PlayerCharacter.self, Skill.self, GameItem.self, SaveSlot.self], inMemory: true)
}
