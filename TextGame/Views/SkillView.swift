//
//  SkillView.swift
//  TextGame
//
//  Created by ant on 2026/3/5.
//

import SwiftUI
import SwiftData

/// 技能頁面，顯示角色所有技能與熟練度
struct SkillView: View {
    let character: PlayerCharacter

    /// 戰鬥技能（武器 + 防具）
    private var combatSkills: [Skill] {
        character.skills.filter {
            $0.category == .weapon || $0.category == .armor
        }.sorted { $0.displayName < $1.displayName }
    }

    /// 生存技能
    private var survivalSkills: [Skill] {
        character.skills.filter { $0.category == .survival }
            .sorted { $0.displayName < $1.displayName }
    }

    /// 知識技能
    private var loreSkills: [Skill] {
        character.skills.filter { $0.category == .lore }
            .sorted { $0.displayName < $1.displayName }
    }

    /// 魔法技能
    private var magicSkills: [Skill] {
        character.skills.filter { $0.category == .magic }
            .sorted { $0.displayName < $1.displayName }
    }

    var body: some View {
        List {
            skillSection("戰鬥技能", skills: combatSkills)
            skillSection("生存技能", skills: survivalSkills)
            skillSection("知識技能", skills: loreSkills)
            skillSection("魔法技能", skills: magicSkills)
        }
        .navigationTitle("技能")
    }

    // MARK: - 技能分區

    @ViewBuilder
    private func skillSection(_ title: String, skills: [Skill]) -> some View {
        Section(title) {
            if skills.isEmpty {
                Text("尚未習得此類技能")
                    .foregroundColor(.secondary)
            } else {
                ForEach(skills, id: \.type) { skill in
                    skillRow(skill)
                }
            }
        }
    }

    // MARK: - 技能列

    private func skillRow(_ skill: Skill) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(skill.displayName)
                Spacer()
                Text("等級 \(skill.rank)")
                    .foregroundColor(.secondary)
            }
            ProgressView(value: skill.experience, total: skill.experienceToNextRank)
                .tint(.blue)
            if skill.fieldExperience > 0 {
                Text("待吸收：\(Int(skill.fieldExperience))")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        SkillView(character: PlayerCharacter(name: "預覽角色", guild: .warrior))
    }
    .modelContainer(for: [PlayerCharacter.self, Skill.self, GameItem.self, SaveSlot.self], inMemory: true)
}
