//
//  MonsterTemplate.swift
//  TextGame
//
//  Created by ant on 2026/3/16.
//

import Foundation

// MARK: - 怪物掉落物

/// 怪物掉落物品定義
struct MonsterLoot: Codable {
    let itemId: String      // 掉落物品模板 ID
    let dropRate: Double    // 掉落機率（0.0 ~ 1.0）
}

// MARK: - 怪物模板

/// 從 JSON 載入的怪物模板定義
struct MonsterTemplate: Codable, Identifiable {
    let id: String              // 怪物唯一識別碼
    let name: String            // 怪物名稱
    let description: String     // 怪物描述
    let icon: String            // SF Symbol 圖示名稱
    let level: Int              // 怪物等級
    let health: Int             // 生命值
    let attack: Int             // 攻擊力
    let defense: Int            // 防禦力
    let experience: Int         // 擊殺獲得經驗值
    let loot: [MonsterLoot]     // 掉落物列表
    let spawnScenes: [String]   // 可出現的場景 ID 列表
}

// MARK: - JSON 容器

/// monsters.json 的根結構
private struct MonsterTemplateContainer: Codable {
    let monsters: [MonsterTemplate]
}

// MARK: - 怪物模板載入器

/// 負責從 Bundle 中載入 monsters.json 並提供查詢功能
final class MonsterTemplateLoader {
    static let shared = MonsterTemplateLoader()

    /// 所有怪物模板，以 id 為 key
    private(set) var templates: [String: MonsterTemplate] = [:]

    private init() {
        loadTemplates()
    }

    /// 從 Bundle 載入 monsters.json
    private func loadTemplates() {
        guard let url = Bundle.main.url(forResource: "monsters", withExtension: "json") else {
            print("[MonsterTemplateLoader] 找不到 monsters.json")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let container = try decoder.decode(MonsterTemplateContainer.self, from: data)
            templates = Dictionary(uniqueKeysWithValues: container.monsters.map { ($0.id, $0) })
            print("[MonsterTemplateLoader] 已載入 \(templates.count) 個怪物模板")
        } catch {
            print("[MonsterTemplateLoader] 載入 monsters.json 失敗：\(error)")
        }
    }

    /// 根據 ID 查詢怪物模板
    func template(for id: String) -> MonsterTemplate? {
        templates[id]
    }

    /// 取得所有怪物模板列表
    func allTemplates() -> [MonsterTemplate] {
        Array(templates.values).sorted { $0.id < $1.id }
    }

    /// 根據 ID 列表取得怪物模板
    func templates(for ids: [String]) -> [MonsterTemplate] {
        ids.compactMap { templates[$0] }
    }

    /// 取得指定場景中可出現的怪物
    func monstersInScene(_ sceneId: String) -> [MonsterTemplate] {
        allTemplates().filter { $0.spawnScenes.contains(sceneId) }
    }

    /// 根據等級範圍篩選怪物
    func templates(levelRange: ClosedRange<Int>) -> [MonsterTemplate] {
        allTemplates().filter { levelRange.contains($0.level) }
    }

    /// 重新載入
    func reload() {
        templates.removeAll()
        loadTemplates()
    }
}
