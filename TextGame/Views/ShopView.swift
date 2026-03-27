//
//  ShopView.swift
//  TextGame
//
//  Created by ant on 2026/3/27.
//

import SwiftUI

/// 商店頁面，以 .sheet 彈窗呈現
struct ShopView: View {
    let npc: NPCTemplate
    let character: PlayerCharacter
    let engine: GameEngine

    @State private var selectedTab = 0  // 0 = 購買, 1 = 出售

    /// NPC 是否提供購買服務（玩家向 NPC 購買）
    private var canBuy: Bool {
        npc.services.contains("buy")
    }

    /// NPC 是否提供收購服務（玩家向 NPC 出售）
    private var canSell: Bool {
        npc.services.contains("sell")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 金幣顯示
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.yellow)
                    Text("\(character.gold) 金幣")
                        .font(.headline)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                // 分頁選擇（僅當同時有 buy/sell 時顯示）
                if canBuy && canSell {
                    Picker("", selection: $selectedTab) {
                        Text("購買").tag(0)
                        Text("出售").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }

                // 內容
                if selectedTab == 0 && canBuy {
                    buyListView
                } else if canSell {
                    sellListView
                } else {
                    buyListView
                }
            }
            .navigationTitle("\(npc.name)的商店")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("離開") {
                        engine.showShopSheet = false
                        engine.currentShopNPC = nil
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            if !canBuy && canSell {
                selectedTab = 1
            }
        }
    }

    // MARK: - 購買列表

    private var buyListView: some View {
        let items = engine.shopItemsForNPC(npc)
        return List {
            if items.isEmpty {
                Text("這裡沒有販售的商品")
                    .foregroundColor(.secondary)
            } else {
                ForEach(items, id: \.template.id) { entry in
                    Button {
                        engine.buyItem(from: npc, shopItem: entry.shopItem)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.template.name)
                                Text(entry.template.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(entry.price) 金")
                                    .font(.subheadline)
                                    .foregroundColor(.yellow)
                                if entry.stock == -1 {
                                    Text("庫存: ∞")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("庫存: \(entry.stock)")
                                        .font(.caption2)
                                        .foregroundColor(entry.stock > 0 ? .secondary : .red)
                                }
                            }
                        }
                    }
                    .disabled(entry.stock == 0 || character.gold < entry.price)
                }
            }
        }
    }

    // MARK: - 出售列表

    private var sellListView: some View {
        let items = engine.sellableItems()
        let tradingRank = character.skill(for: .trading)?.rank ?? 0
        return List {
            if items.isEmpty {
                Text("沒有可出售的物品")
                    .foregroundColor(.secondary)
            } else {
                ForEach(items) { item in
                    Button {
                        engine.sellItem(to: npc, item: item)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                Text(item.itemDescription)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            if item.isStackable && item.stackCount > 1 {
                                Text("x\(item.stackCount)")
                                    .foregroundColor(.secondary)
                                    .padding(.trailing, 4)
                            }
                            Text("\(TradeCalculator.sellPrice(baseValue: item.value, tradingRank: tradingRank)) 金")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
        }
    }
}
