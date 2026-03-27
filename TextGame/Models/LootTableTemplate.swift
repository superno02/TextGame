//
//  LootTableTemplate.swift
//  TextGame
//

import Foundation

// MARK: - 掉落項目

/// 掉落表中的單項物品定義
struct LootEntry: Codable {
    let itemId: String          // 掉落物品模板 ID
    let dropRate: Double        // 掉落機率（0.0 ~ 1.0）
    let minQuantity: Int        // 最小掉落數量
    let maxQuantity: Int        // 最大掉落數量
}

// MARK: - 掉落表模板

/// 從 JSON 載入的掉落表定義
struct LootTableTemplate: Codable, Identifiable {
    let id: String              // 掉落表唯一識別碼
    let name: String            // 掉落表名稱（方便辨識）
    let entries: [LootEntry]    // 掉落項目列表
}

// MARK: - JSON 容器

/// loot_tables.json 的根結構
private struct LootTableTemplateContainer: Codable {
    let lootTables: [LootTableTemplate]
}

// MARK: - 掉落表載入器

/// 負責從 Bundle 中載入 loot_tables.json 並提供查詢功能
final class LootTableLoader {
    static let shared = LootTableLoader()

    /// 所有掉落表模板，以 id 為 key
    private(set) var templates: [String: LootTableTemplate] = [:]

    /// 載入錯誤訊息（nil 表示載入成功）
    private(set) var loadError: String?

    private init() {
        loadTemplates()
    }

    /// 從 Bundle 載入 loot_tables.json
    private func loadTemplates() {
        loadError = nil
        guard let url = Bundle.main.url(forResource: "loot_tables", withExtension: "json") else {
            loadError = "找不到 loot_tables.json"
            print("[LootTableLoader] \(loadError!)")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let container = try decoder.decode(LootTableTemplateContainer.self, from: data)
            templates = Dictionary(uniqueKeysWithValues: container.lootTables.map { ($0.id, $0) })
            print("[LootTableLoader] 已載入 \(templates.count) 個掉落表")
        } catch {
            loadError = "載入 loot_tables.json 失敗：\(error.localizedDescription)"
            print("[LootTableLoader] \(loadError!)")
        }
    }

    /// 根據 ID 查詢掉落表
    func template(for id: String) -> LootTableTemplate? {
        templates[id]
    }

    /// 取得所有掉落表列表
    func allTemplates() -> [LootTableTemplate] {
        Array(templates.values).sorted { $0.id < $1.id }
    }

    /// 重新載入
    func reload() {
        templates.removeAll()
        loadTemplates()
    }
}
