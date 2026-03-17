//
//  SaveSlot.swift
//  TextGame
//
//  Created by ant on 2026/3/5.
//

import Foundation
import SwiftData

/// 存檔槽位，記錄存檔的基本資訊與對應角色
@Model
final class SaveSlot {
    var slotIndex: Int              // 槽位編號（1, 2, 3...）
    var characterName: String       // 角色名稱（快速顯示用）
    var characterGuildRawValue: String  // 角色職業（儲存 rawValue）

    /// 角色職業（計算屬性）
    @Transient
    var characterGuild: Guild {
        get { Guild(rawValue: characterGuildRawValue) ?? .none }
        set { characterGuildRawValue = newValue.rawValue }
    }
    var characterCircle: Int        // 角色等階
    var savedAt: Date               // 存檔時間
    var playTime: TimeInterval      // 累計遊戲時間（秒）

    @Relationship(deleteRule: .cascade)
    var character: PlayerCharacter?

    init(
        slotIndex: Int,
        character: PlayerCharacter,
        playTime: TimeInterval = 0
    ) {
        self.slotIndex = slotIndex
        self.characterName = character.name
        self.characterGuildRawValue = character.guildRawValue
        self.characterCircle = character.circle
        self.savedAt = Date()
        self.playTime = playTime
        self.character = character
    }

    /// 更新存檔資訊
    func updateSaveInfo(character: PlayerCharacter, playTime: TimeInterval) {
        self.characterName = character.name
        self.characterGuildRawValue = character.guildRawValue
        self.characterCircle = character.circle
        self.savedAt = Date()
        self.playTime = playTime
        self.character = character
    }
}
