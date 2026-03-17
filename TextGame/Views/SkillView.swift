//
//  SkillView.swift
//  TextGame
//
//  Created by ant on 2026/3/5.
//

import SwiftUI

/// 技能頁面，顯示角色所有技能與熟練度
struct SkillView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("戰鬥技能") {
                    Text("尚未實作")
                        .foregroundColor(.secondary)
                }

                Section("生存技能") {
                    Text("尚未實作")
                        .foregroundColor(.secondary)
                }

                Section("魔法技能") {
                    Text("尚未實作")
                        .foregroundColor(.secondary)
                }

                Section("知識技能") {
                    Text("尚未實作")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("技能")
        }
    }
}

#Preview {
    SkillView()
}
