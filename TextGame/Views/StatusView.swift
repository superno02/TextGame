//
//  StatusView.swift
//  TextGame
//
//  Created by ant on 2026/3/5.
//

import SwiftUI
import SwiftData

/// 屬性頁面，顯示角色基本屬性與狀態
struct StatusView: View {
    let character: PlayerCharacter

    var body: some View {
        List {
            Section("基本資訊") {
                HStack {
                    Text("名稱")
                    Spacer()
                    Text(character.name)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("職業")
                    Spacer()
                    Text(character.guild.displayName)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("等階")
                    Spacer()
                    Text("\(character.circle)")
                        .foregroundColor(.secondary)
                }
                VStack(spacing: 4) {
                    HStack {
                        Text("經驗值")
                        Spacer()
                        Text("\(character.experience) / \(character.experienceToNextCircle)")
                            .foregroundColor(.secondary)
                    }
                    ProgressView(
                        value: Double(character.experience),
                        total: Double(character.experienceToNextCircle)
                    )
                    .tint(.yellow)
                }
                HStack {
                    Text("金幣")
                    Spacer()
                    Text("\(character.gold)")
                        .foregroundColor(.yellow)
                }
            }

            Section("屬性") {
                statusRow("力量", value: character.strength)
                statusRow("敏捷", value: character.agility)
                statusRow("體質", value: character.constitution)
                statusRow("智力", value: character.intelligence)
                statusRow("智慧", value: character.wisdom)
                statusRow("魅力", value: character.charisma)
            }

            Section("狀態") {
                statusRow("生命", value: character.currentHealth, max: character.maxHealth)
                statusRow("魔力", value: character.currentMana, max: character.maxMana)
                statusRow("體力", value: character.currentStamina, max: character.maxStamina)
            }
        }
        .navigationTitle("屬性")
    }

    private func statusRow(_ label: String, value: Int) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(value)")
                .foregroundColor(.secondary)
        }
    }

    private func statusRow(_ label: String, value: Int, max: Int) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(value) / \(max)")
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        StatusView(character: PlayerCharacter(name: "預覽角色", guild: .warrior))
    }
    .modelContainer(for: [PlayerCharacter.self, Skill.self, GameItem.self, SaveSlot.self], inMemory: true)
}
