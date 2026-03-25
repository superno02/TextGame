//
//  GuildTemplate.swift
//  TextGame
//
//  Created by ant on 2026/3/13.
//

import Foundation

// MARK: - 職業基礎屬性

/// 職業的基礎六大屬性
struct GuildBaseStats: Codable, Equatable {
    let strength: Int       // 力量
    let agility: Int        // 敏捷
    let constitution: Int   // 體質
    let intelligence: Int   // 智力
    let wisdom: Int         // 智慧
    let charisma: Int       // 魅力
}

// MARK: - 狀態值公式

/// 狀態值計算公式：base + perAttribute * 屬性值
struct StatusFormula: Codable, Equatable {
    let base: Int

    // 各公式使用不同的屬性名
    var perConstitution: Int?
    var perIntelligence: Int?
    var perStrength: Int?

    /// 根據屬性值計算狀態值
    func calculate(attributeValue: Int) -> Int {
        let per = perConstitution ?? perIntelligence ?? perStrength ?? 0
        return base + per * attributeValue
    }
}

// MARK: - 等階成長屬性

/// 每次等階提升時各屬性的成長值
struct CircleGrowth: Codable, Equatable {
    let strength: Int       // 力量成長
    let agility: Int        // 敏捷成長
    let constitution: Int   // 體質成長
    let intelligence: Int   // 智力成長
    let wisdom: Int         // 智慧成長
    let charisma: Int       // 魅力成長
}

// MARK: - 職業模板

/// 從 JSON 載入的職業模板定義
struct GuildTemplate: Codable, Identifiable {
    let id: String                  // 職業識別碼（對應 Guild rawValue）
    let name: String                // 職業中文名稱
    let description: String         // 職業描述
    let baseStats: GuildBaseStats   // 基礎屬性
    let primarySkills: [String]     // 主要技能（升級較快）
    let secondarySkills: [String]   // 次要技能
    let forbiddenSkills: [String]   // 禁止技能（無法學習）
    let circleGrowth: CircleGrowth      // 等階提升時的屬性成長
    let healthFormula: StatusFormula    // 生命值計算公式
    let manaFormula: StatusFormula      // 魔力值計算公式
    let staminaFormula: StatusFormula   // 體力值計算公式

    /// 取得對應的 Guild 列舉
    var guild: Guild? {
        Guild(rawValue: id)
    }
}

// MARK: - JSON 容器

/// guilds.json 的根結構
private struct GuildTemplateContainer: Codable {
    let guilds: [GuildTemplate]
}

// MARK: - 職業模板載入器

/// 負責從 Bundle 中載入 guilds.json 並提供查詢功能
final class GuildTemplateLoader {
    static let shared = GuildTemplateLoader()

    /// 所有職業模板，以 id 為 key
    private(set) var templates: [String: GuildTemplate] = [:]

    /// 載入錯誤訊息（nil 表示載入成功）
    private(set) var loadError: String?

    private init() {
        loadTemplates()
    }

    /// 從 Bundle 載入 guilds.json
    private func loadTemplates() {
        loadError = nil
        guard let url = Bundle.main.url(forResource: "guilds", withExtension: "json") else {
            loadError = "找不到 guilds.json"
            print("[GuildTemplateLoader] \(loadError!)")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let container = try decoder.decode(GuildTemplateContainer.self, from: data)
            templates = Dictionary(uniqueKeysWithValues: container.guilds.map { ($0.id, $0) })
            print("[GuildTemplateLoader] 已載入 \(templates.count) 個職業模板")
        } catch {
            loadError = "載入 guilds.json 失敗：\(error.localizedDescription)"
            print("[GuildTemplateLoader] \(loadError!)")
        }
    }

    /// 根據 ID 查詢職業模板
    func template(for id: String) -> GuildTemplate? {
        templates[id]
    }

    /// 根據 Guild 列舉查詢
    func template(for guild: Guild) -> GuildTemplate? {
        templates[guild.rawValue]
    }

    /// 取得所有職業模板列表
    func allTemplates() -> [GuildTemplate] {
        Array(templates.values).sorted { $0.id < $1.id }
    }

    /// 取得可選擇的職業列表（排除 none）
    func selectableGuilds() -> [GuildTemplate] {
        allTemplates().filter { $0.id != "none" }
    }

    /// 重新載入
    func reload() {
        templates.removeAll()
        loadTemplates()
    }
}
