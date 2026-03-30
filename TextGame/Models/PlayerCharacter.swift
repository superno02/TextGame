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
    var experience: Int  // 目前累積的角色經驗值

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

    // MARK: - 金幣
    var gold: Int           // 持有金幣

    // MARK: - 關聯
    @Relationship(deleteRule: .cascade)
    var skills: [Skill] = []

    @Relationship(deleteRule: .cascade)
    var inventory: [GameItem] = []

    // MARK: - 目前位置
    var currentSceneId: String

    // MARK: - NPC 好感度
    var npcAffinity: [String: Int] = [:]   // [NPC ID: 好感度值]

    /// 取得對指定 NPC 的好感度
    func affinity(for npcId: String) -> Int {
        npcAffinity[npcId] ?? 0
    }

    /// 增減指定 NPC 的好感度
    func changeAffinity(for npcId: String, by amount: Int) {
        npcAffinity[npcId, default: 0] += amount
    }

    // MARK: - 戰鬥輔助屬性

    /// 目前裝備的武器
    @Transient
    var equippedWeapon: GameItem? {
        inventory.first { $0.isEquipped && $0.itemType == .weapon }
    }

    /// 目前裝備的所有防具
    @Transient
    var equippedArmor: [GameItem] {
        inventory.filter { $0.isEquipped && $0.itemType == .armor }
    }

    /// 總攻擊力 = 力量 + 武器攻擊力
    @Transient
    var totalAttackPower: Int {
        strength + (equippedWeapon?.attackPower ?? 0)
    }

    /// 總防禦力 = 所有已裝備防具的防禦力之和
    @Transient
    var totalDefensePower: Int {
        equippedArmor.reduce(0) { $0 + $1.defensePower }
    }

    /// 根據裝備武器推導對應的武器技能類型
    @Transient
    var weaponSkillType: SkillType? {
        guard let weapon = equippedWeapon else { return nil }
        return SkillType.weaponSkillType(for: weapon.itemId)
    }

    /// 查找特定技能
    func skill(for type: SkillType) -> Skill? {
        skills.first { $0.type == type }
    }

    // MARK: - 經驗值與升級

    /// 升級所需的經驗值
    @Transient
    var experienceToNextCircle: Int {
        circle * 50 + 50
    }

    /// 獲得經驗值，若達到門檻則升級
    /// - Returns: 是否發生了升級
    @discardableResult
    func gainExperience(_ amount: Int) -> Bool {
        experience += amount
        var didLevelUp = false
        while experience >= experienceToNextCircle {
            performLevelUp()
            didLevelUp = true
        }
        return didLevelUp
    }

    /// 執行升級邏輯
    private func performLevelUp() {
        experience -= experienceToNextCircle
        circle += 1

        // 取得職業成長值
        let template = GuildTemplateLoader.shared.template(for: guild)
        if let growth = template?.circleGrowth {
            strength += growth.strength
            agility += growth.agility
            constitution += growth.constitution
            intelligence += growth.intelligence
            wisdom += growth.wisdom
            charisma += growth.charisma
        }

        // 重新計算狀態值上限
        if let template {
            maxHealth = template.healthFormula.calculate(attributeValue: constitution)
            maxMana = template.manaFormula.calculate(attributeValue: intelligence)
            maxStamina = template.staminaFormula.calculate(attributeValue: strength)
        } else {
            maxHealth = 50 + constitution * 5
            maxMana = 20 + intelligence * 3
            maxStamina = 30 + strength * 2
        }

        // 升級全回復
        currentHealth = maxHealth
        currentMana = maxMana
        currentStamina = maxStamina
    }

    // MARK: - 初始化

    init(name: String, guild: Guild) {
        self.name = name
        self.guildRawValue = guild.rawValue
        self.circle = 1
        self.experience = 0
        self.gold = 100
        self.currentSceneId = "03_01_village"

        // 從職業模板取得基礎屬性，找不到時使用 fallback 預設值
        let template = GuildTemplateLoader.shared.template(for: guild)
        let stats = template?.baseStats ?? GuildBaseStats(
            strength: 10, agility: 10, constitution: 10,
            intelligence: 10, wisdom: 10, charisma: 10
        )

        self.strength = stats.strength
        self.agility = stats.agility
        self.constitution = stats.constitution
        self.intelligence = stats.intelligence
        self.wisdom = stats.wisdom
        self.charisma = stats.charisma

        // 初始狀態值（先設定預設值，再計算）
        self.maxHealth = 0
        self.currentHealth = 0
        self.maxMana = 0
        self.currentMana = 0
        self.maxStamina = 0
        self.currentStamina = 0

        // 使用職業公式計算狀態值，找不到模板時使用 fallback 公式
        if let template {
            self.maxHealth = template.healthFormula.calculate(attributeValue: self.constitution)
            self.maxMana = template.manaFormula.calculate(attributeValue: self.intelligence)
            self.maxStamina = template.staminaFormula.calculate(attributeValue: self.strength)
        } else {
            self.maxHealth = 50 + self.constitution * 5
            self.maxMana = 20 + self.intelligence * 3
            self.maxStamina = 30 + self.strength * 2
        }

        self.currentHealth = self.maxHealth
        self.currentMana = self.maxMana
        self.currentStamina = self.maxStamina
    }
}
