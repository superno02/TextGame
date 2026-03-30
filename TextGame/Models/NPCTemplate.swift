//
//  NPCTemplate.swift
//  TextGame
//
//  Created by ant on 2026/3/13.
//

import Foundation

// MARK: - 對話節點

/// 對話樹節點，支援巢狀選項與條件觸發
struct DialogueNode: Codable, Identifiable {
    let id: String              // 節點識別碼
    let label: String           // 玩家看到的選項文字
    let response: String        // NPC 的回應文字
    let condition: String?      // 觸發條件（nil = 無條件）
    let action: String?         // 特殊動作："openShop" / "endDialogue"
    let goto: String?           // 跳轉到指定節點 ID
    let options: [DialogueNode] // 子選項（空陣列 = 葉節點）

    enum CodingKeys: String, CodingKey {
        case id, label, response, condition, action, goto, options
    }

    init(id: String, label: String, response: String, condition: String? = nil,
         action: String? = nil, goto: String? = nil, options: [DialogueNode] = []) {
        self.id = id
        self.label = label
        self.response = response
        self.condition = condition
        self.action = action
        self.goto = goto
        self.options = options
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        label = try container.decode(String.self, forKey: .label)
        response = try container.decode(String.self, forKey: .response)
        condition = try container.decodeIfPresent(String.self, forKey: .condition)
        action = try container.decodeIfPresent(String.self, forKey: .action)
        goto = try container.decodeIfPresent(String.self, forKey: .goto)
        options = try container.decodeIfPresent([DialogueNode].self, forKey: .options) ?? []
    }
}

// MARK: - 對話特殊動作

/// 對話中可觸發的特殊動作
enum DialogueAction: String {
    case openShop = "openShop"
    case endDialogue = "endDialogue"
}

// MARK: - 對話條件評估上下文

/// 對話條件評估所需的玩家狀態
struct DialogueContext {
    let playerGuild: Guild?
    let playerCircle: Int
    let inventoryItemIds: Set<String>
    let npcAffinity: Int

    init(character: PlayerCharacter?, npcId: String) {
        self.playerGuild = character?.guild
        self.playerCircle = character?.circle ?? 0
        self.inventoryItemIds = Set(character?.inventory.map(\.itemId) ?? [])
        self.npcAffinity = character?.affinity(for: npcId) ?? 0
    }

    init(playerGuild: Guild? = nil, playerCircle: Int = 0,
         inventoryItemIds: Set<String> = [], npcAffinity: Int = 0) {
        self.playerGuild = playerGuild
        self.playerCircle = playerCircle
        self.inventoryItemIds = inventoryItemIds
        self.npcAffinity = npcAffinity
    }
}

/// 評估對話條件是否滿足
func evaluateCondition(_ condition: String?, context: DialogueContext) -> Bool {
    guard let condition else { return true }

    let parts = condition.split(separator: ":")
    guard parts.count == 2 else { return false }

    let key = String(parts[0])
    let value = String(parts[1])

    switch key {
    case "guild":
        return context.playerGuild?.rawValue == value
    case "circle":
        guard let requiredCircle = Int(value) else { return false }
        return context.playerCircle >= requiredCircle
    case "item":
        return context.inventoryItemIds.contains(value)
    case "affinity":
        guard let requiredAffinity = Int(value) else { return false }
        return context.npcAffinity >= requiredAffinity
    default:
        return false
    }
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
    let dialogueRoot: [DialogueNode]   // 對話樹根節點
    let shopItems: [NPCShopItem]       // 商店物品列表（非商人則為空）
    let services: [String]             // 提供的服務：buy / sell / quest / train / info

    /// 是否為商人（有販售物品）
    var isMerchant: Bool {
        !shopItems.isEmpty
    }

    /// 取得符合條件的根選項
    func availableRootOptions(context: DialogueContext) -> [DialogueNode] {
        dialogueRoot.filter { node in
            evaluateCondition(node.condition, context: context)
        }
    }

    /// 取得某節點下符合條件的子選項
    func availableOptions(for node: DialogueNode, context: DialogueContext) -> [DialogueNode] {
        node.options.filter { child in
            evaluateCondition(child.condition, context: context)
        }
    }

    /// 在整棵對話樹中遞迴查找指定 ID 的節點（用於 goto 跳轉）
    func findNode(byId targetId: String) -> DialogueNode? {
        for root in dialogueRoot {
            if let found = findNodeRecursive(in: root, targetId: targetId) {
                return found
            }
        }
        return nil
    }

    private func findNodeRecursive(in node: DialogueNode, targetId: String) -> DialogueNode? {
        if node.id == targetId { return node }
        for child in node.options {
            if let found = findNodeRecursive(in: child, targetId: targetId) {
                return found
            }
        }
        return nil
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

    /// 載入錯誤訊息（nil 表示載入成功）
    private(set) var loadError: String?

    private init() {
        loadTemplates()
    }

    /// 從 Bundle 載入 npcs.json
    private func loadTemplates() {
        loadError = nil
        guard let url = Bundle.main.url(forResource: "npcs", withExtension: "json") else {
            loadError = "找不到 npcs.json"
            print("[NPCTemplateLoader] \(loadError!)")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let container = try decoder.decode(NPCTemplateContainer.self, from: data)
            templates = Dictionary(uniqueKeysWithValues: container.npcs.map { ($0.id, $0) })
            print("[NPCTemplateLoader] 已載入 \(templates.count) 個 NPC 模板")
        } catch {
            loadError = "載入 npcs.json 失敗：\(error.localizedDescription)"
            print("[NPCTemplateLoader] \(loadError!)")
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
