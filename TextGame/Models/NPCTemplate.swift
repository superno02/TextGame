//
//  NPCTemplate.swift
//  TextGame
//
//  Created by ant on 2026/3/13.
//

import Foundation

// MARK: - NPC 對話

/// NPC 的一段對話
struct NPCDialogue: Codable, Identifiable {
    let id: String          // 對話識別碼
    let text: String        // 對話文字
    let condition: String?  // 觸發條件（如 "guild:warrior"），nil 表示無條件
}

// MARK: - NPC 商店物品

/// NPC 商店中的商品定義
struct NPCShopItem: Codable {
    let itemId: String          // 物品模板 ID
    let stock: Int              // 庫存數量（-1 表示無限）
    let priceMultiplier: Double // 價格倍率（1.0 為原價）
}

// MARK: - NPC 模板

/// 從 JSON 載入的 NPC 模板定義
struct NPCTemplate: Codable, Identifiable {
    let id: String              // NPC 唯一識別碼
    let name: String            // NPC 名稱
    let title: String           // NPC 頭銜
    let description: String     // NPC 描述
    let icon: String            // SF Symbol 圖示名稱
    let type: String            // NPC 類型：merchant / questGiver / trainer / guard
    let dialogues: [NPCDialogue]   // 對話列表
    let shopItems: [NPCShopItem]   // 商店物品列表（非商人則為空）
    let services: [String]         // 提供的服務：buy / sell / quest / train / info

    /// 是否為商人（有販售物品）
    var isMerchant: Bool {
        !shopItems.isEmpty
    }

    /// 取得符合條件的對話
    func availableDialogues(playerGuild: Guild?) -> [NPCDialogue] {
        dialogues.filter { dialogue in
            guard let condition = dialogue.condition else { return true }

            // 解析條件格式：key:value
            let parts = condition.split(separator: ":")
            guard parts.count == 2 else { return false }

            let key = String(parts[0])
            let value = String(parts[1])

            switch key {
            case "guild":
                return playerGuild?.rawValue == value
            default:
                return false
            }
        }
    }
}

// MARK: - JSON 容器

/// npcs.json 的根結構
private struct NPCTemplateContainer: Codable {
    let npcs: [NPCTemplate]
}

// MARK: - NPC 模板載入器

/// 負責從 Bundle 中載入 npcs.json 並提供查詢功能
final class NPCTemplateLoader {
    static let shared = NPCTemplateLoader()

    /// 所有 NPC 模板，以 id 為 key
    private(set) var templates: [String: NPCTemplate] = [:]

    private init() {
        loadTemplates()
    }

    /// 從 Bundle 載入 npcs.json
    private func loadTemplates() {
        guard let url = Bundle.main.url(forResource: "npcs", withExtension: "json") else {
            print("[NPCTemplateLoader] 找不到 npcs.json")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let container = try decoder.decode(NPCTemplateContainer.self, from: data)
            templates = Dictionary(uniqueKeysWithValues: container.npcs.map { ($0.id, $0) })
            print("[NPCTemplateLoader] 已載入 \(templates.count) 個 NPC 模板")
        } catch {
            print("[NPCTemplateLoader] 載入 npcs.json 失敗：\(error)")
        }
    }

    /// 根據 ID 查詢 NPC 模板
    func template(for id: String) -> NPCTemplate? {
        templates[id]
    }

    /// 取得所有 NPC 模板列表
    func allTemplates() -> [NPCTemplate] {
        Array(templates.values).sorted { $0.id < $1.id }
    }

    /// 取得指定 NPC ID 列表對應的模板
    func templates(for ids: [String]) -> [NPCTemplate] {
        ids.compactMap { templates[$0] }
    }

    /// 取得所有商人類型 NPC
    func merchants() -> [NPCTemplate] {
        allTemplates().filter { $0.isMerchant }
    }

    /// 重新載入
    func reload() {
        templates.removeAll()
        loadTemplates()
    }
}
