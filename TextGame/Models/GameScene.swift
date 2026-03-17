//
//  GameScene.swift
//  TextGame
//
//  Created by ant on 2026/3/5.
//

import Foundation

/// 遊戲場景，定義場景的描述與可前往的地點
struct GameScene: Identifiable, Codable {
    let id: String              // 場景唯一識別碼
    let name: String            // 場景名稱
    let description: String     // 場景描述文字
    let exits: [SceneExit]      // 可前往的出口列表
    let monsters: [String]      // 此場景可能出現的怪物 ID 列表
    let isRestArea: Bool        // 是否為休息區域（可恢復狀態）
}

/// 場景出口，描述可前往的目的地
struct SceneExit: Identifiable, Codable {
    var id: String { destinationId }
    let label: String           // 出口顯示文字（如「前往市集」）
    let destinationId: String   // 目的地場景 ID
}
