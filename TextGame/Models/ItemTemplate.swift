//
//  ItemTemplate.swift
//  TextGame
//
//  Created by ant on 2026/3/13.
//

import Foundation

// MARK: - 素質修正

/// 物品裝備後對角色素質的修正值
struct StatModifiers: Codable, Equatable {
    var strength: Int = 0       // 力量
    var agility: Int = 0        // 敏捷
    var constitution: Int = 0   // 體質
    var intelligence: Int = 0   // 智力
    var wisdom: Int = 0         // 智慧
    var charisma: Int = 0       // 魅力
    var maxHealth: Int = 0      // 最大生命值
    var maxMana: Int = 0        // 最大魔力值
    var maxStamina: Int = 0     // 最大體力值

    /// 空修正（全部為 0）
    static let zero = StatModifiers()
}

// MARK: - 使用/裝備條件

/// 物品的使用與裝備條件
struct ItemRequirements: Codable, Equatable {
    var circle: Int = 0         // 等階需求，0 表示無限制
    var guilds: [String] = []   // 職業限制（空陣列 = 全職業可用）
    var strength: Int = 0       // 力量需求
    var agility: Int = 0        // 敏捷需求
    var constitution: Int = 0   // 體質需求
    var intelligence: Int = 0   // 智力需求
    var wisdom: Int = 0         // 智慧需求
    var charisma: Int = 0       // 魅力需求

    /// 無條件限制
    static let none = ItemRequirements()
}

// MARK: - 物品模板

/// 從 JSON 載入的物品模板定義，作為建立 GameItem 實例的藍圖
struct ItemTemplate: Codable, Identifiable {
    let id: String              // 物品唯一識別碼
    let name: String            // 物品名稱
    let description: String     // 物品描述
    let type: String            // 物品類型（對應 ItemType rawValue）
    let equipSlot: String?      // 可裝備部位（對應 EquipmentSlot rawValue，非裝備類為 nil）
    let rarity: Int             // 稀有度（數字，越大越稀有）
    let maxStack: Int           // 最大堆疊數量
    let value: Int              // 交易價值
    let attackPower: Int        // 攻擊力
    let defensePower: Int       // 防禦力
    let healAmount: Int         // 回復量
    let statModifiers: StatModifiers    // 素質修正
    let requirements: ItemRequirements  // 使用/裝備條件

    /// 取得對應的 ItemType 列舉
    var itemType: ItemType? {
        ItemType(rawValue: type)
    }

    /// 取得對應的 EquipmentSlot 列舉
    var equipmentSlot: EquipmentSlot? {
        guard let slot = equipSlot else { return nil }
        return EquipmentSlot(rawValue: slot)
    }
}

// MARK: - JSON 容器

/// items.json 的根結構
private struct ItemTemplateContainer: Codable {
    let items: [ItemTemplate]
}

// MARK: - 物品模板載入器

/// 負責從 Bundle 中載入 items.json 並提供查詢功能
final class ItemTemplateLoader {
    static let shared = ItemTemplateLoader()

    /// 所有物品模板，以 id 為 key
    private(set) var templates: [String: ItemTemplate] = [:]

    private init() {
        loadTemplates()
    }

    /// 從 Bundle 載入 items.json
    private func loadTemplates() {
        guard let url = Bundle.main.url(forResource: "items", withExtension: "json") else {
            print("[ItemTemplateLoader] 找不到 items.json")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let container = try decoder.decode(ItemTemplateContainer.self, from: data)
            templates = Dictionary(uniqueKeysWithValues: container.items.map { ($0.id, $0) })
            print("[ItemTemplateLoader] 已載入 \(templates.count) 個物品模板")
        } catch {
            print("[ItemTemplateLoader] 載入 items.json 失敗：\(error)")
        }
    }

    /// 根據 ID 查詢物品模板
    func template(for id: String) -> ItemTemplate? {
        templates[id]
    }

    /// 取得所有物品模板列表
    func allTemplates() -> [ItemTemplate] {
        Array(templates.values).sorted { $0.id < $1.id }
    }

    /// 根據類型篩選物品模板
    func templates(ofType type: String) -> [ItemTemplate] {
        allTemplates().filter { $0.type == type }
    }

    /// 重新載入模板（供除錯或熱更新使用）
    func reload() {
        templates.removeAll()
        loadTemplates()
    }
}
