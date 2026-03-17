//
//  SceneTemplate.swift
//  TextGame
//
//  Created by ant on 2026/3/13.
//

import Foundation

// MARK: - 場景出口模板

/// 場景出口定義（對應 JSON 結構）
struct SceneExitTemplate: Codable {
    let label: String           // 出口顯示文字
    let destinationId: String   // 目的地場景 ID
}

// MARK: - 場景模板

/// 從 JSON 載入的場景模板定義
struct SceneTemplate: Codable, Identifiable {
    let id: String                  // 場景唯一識別碼
    let name: String                // 場景名稱
    let description: String         // 場景描述文字
    let exits: [SceneExitTemplate]  // 可前往的出口列表
    let monsters: [String]          // 此場景可能出現的怪物 ID 列表
    let npcs: [String]              // 此場景中的 NPC ID 列表
    let isRestArea: Bool            // 是否為休息區域

    /// 轉換為 GameScene
    func toGameScene() -> GameScene {
        GameScene(
            id: id,
            name: name,
            description: description,
            exits: exits.map { SceneExit(label: $0.label, destinationId: $0.destinationId) },
            monsters: monsters,
            isRestArea: isRestArea
        )
    }
}

// MARK: - JSON 容器

/// scenes.json 的根結構
private struct SceneDataContainer: Codable {
    let scenes: [SceneTemplate]
}

// MARK: - 場景資料載入器

/// 負責從 Bundle 中載入 scenes.json 並提供查詢功能
final class SceneTemplateLoader {
    static let shared = SceneTemplateLoader()

    /// 所有場景模板，以 id 為 key
    private(set) var sceneTemplates: [String: SceneTemplate] = [:]

    private init() {
        loadData()
    }

    /// 從 Bundle 載入 scenes.json
    private func loadData() {
        guard let url = Bundle.main.url(forResource: "scenes", withExtension: "json") else {
            print("[SceneTemplateLoader] 找不到 scenes.json")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let container = try decoder.decode(SceneDataContainer.self, from: data)
            sceneTemplates = Dictionary(uniqueKeysWithValues: container.scenes.map { ($0.id, $0) })
            print("[SceneTemplateLoader] 已載入 \(sceneTemplates.count) 個場景")
        } catch {
            print("[SceneTemplateLoader] 載入 scenes.json 失敗：\(error)")
        }
    }

    // MARK: - 場景查詢

    /// 根據 ID 查詢場景模板
    func scene(for id: String) -> SceneTemplate? {
        sceneTemplates[id]
    }

    /// 取得所有場景模板
    func allScenes() -> [SceneTemplate] {
        Array(sceneTemplates.values).sorted { $0.id < $1.id }
    }

    /// 取得轉換後的 GameScene 字典（供 GameView 使用）
    func allGameScenes() -> [String: GameScene] {
        Dictionary(uniqueKeysWithValues: sceneTemplates.map { ($0.key, $0.value.toGameScene()) })
    }

    /// 取得指定場景中的 NPC ID 列表
    func npcIdsInScene(_ sceneId: String) -> [String] {
        sceneTemplates[sceneId]?.npcs ?? []
    }

    /// 重新載入
    func reload() {
        sceneTemplates.removeAll()
        loadData()
    }
}
