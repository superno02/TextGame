//
//  InventoryView.swift
//  TextGame
//
//  Created by ant on 2026/3/5.
//

import SwiftUI

/// 背包頁面，顯示角色攜帶的物品
struct InventoryView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("裝備中") {
                    Text("尚未實作")
                        .foregroundColor(.secondary)
                }

                Section("背包物品") {
                    Text("尚未實作")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("背包")
        }
    }
}

#Preview {
    InventoryView()
}
