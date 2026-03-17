//
//  PlayerCharacter.swift
//  TextGame
//
//  Created by ant on 2026/3/5.
//

import Foundation
import SwiftData

/// 玩家角色，儲存角色的基本資訊、屬性、技能與背包
@Model
final class PlayerCharacter {
    // MARK: - 基本資訊
    var name: String
    var guildRawValue: String  // 職業（儲存 rawValue）
    var circle: Int  // 等階（類似等級）

    /// 職業（計算屬性，對應 Guild 列舉）
    @Transient
    var guild: Guild {
        get { Guild(rawValue: guildRawValue) ?? .none }
        set { guildRawValue = newValue.rawValue }
    }

    // MARK: - 基本屬性（參考 DragonRealms 六大屬性）
    var strength: Int       // 力量
    var agility: Int        // 敏捷
    var constitution: Int   // 體質
    var intelligence: Int   // 智力
    var wisdom: Int         // 智慧
    var charisma: Int       // 魅力

    // MARK: - 狀態值
    var currentHealth: Int  // 目前生命值
    var maxHealth: Int      // 最大生命值
    var currentMana: Int    // 目前魔力值
    var maxMana: Int        // 最大魔力值
    var currentStamina: Int // 目前體力值
    var maxStamina: Int     // 最大體力值

    // MARK: - 關聯
    @Relationship(deleteRule: .cascade)
    var skills: [Skill] = []

    @Relationship(deleteRule: .cascade)
    var inventory: [GameItem] = []

    // MARK: - 目前位置
    var currentSceneId: String

    // MARK: - 初始化

    init(name: String, guild: Guild) {
        self.name = name
        self.guildRawValue = guild.rawValue
        self.circle = 1
        self.currentSceneId = "village"

        // 根據職業設定初始屬性
        switch guild {
        case .none:
            self.strength = 10
            self.agility = 10
            self.constitution = 10
            self.intelligence = 10
            self.wisdom = 10
            self.charisma = 10
        case .warrior:
            self.strength = 14
            self.agility = 12
            self.constitution = 14
            self.intelligence = 8
            self.wisdom = 8
            self.charisma = 10
        case .mage:
            self.strength = 8
            self.agility = 10
            self.constitution = 8
            self.intelligence = 16
            self.wisdom = 14
            self.charisma = 10
        case .thief:
            self.strength = 10
            self.agility = 16
            self.constitution = 10
            self.intelligence = 12
            self.wisdom = 8
            self.charisma = 10
        case .cleric:
            self.strength = 10
            self.agility = 8
            self.constitution = 12
            self.intelligence = 10
            self.wisdom = 16
            self.charisma = 10
        }

        // 初始狀態值（先設定預設值，再計算）
        self.maxHealth = 0
        self.currentHealth = 0
        self.maxMana = 0
        self.currentMana = 0
        self.maxStamina = 0
        self.currentStamina = 0

        // 根據屬性計算狀態值
        self.maxHealth = 50 + self.constitution * 5
        self.currentHealth = self.maxHealth
        self.maxMana = 20 + self.intelligence * 3
        self.currentMana = self.maxMana
        self.maxStamina = 30 + self.strength * 2
        self.currentStamina = self.maxStamina
    }
}
