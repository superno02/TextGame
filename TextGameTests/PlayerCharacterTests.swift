//
//  PlayerCharacterTests.swift
//  TextGameTests
//
//  Created by ant on 2026/3/18.
//

import Testing
import Foundation
@testable import TextGame

struct PlayerCharacterTests {

    @Test("無業遊民初始屬性應為全 10")
    func noneGuildBaseStats() {
        let character = PlayerCharacter(name: "測試", guild: .none)
        #expect(character.strength == 10)
        #expect(character.agility == 10)
        #expect(character.constitution == 10)
        #expect(character.intelligence == 10)
        #expect(character.wisdom == 10)
        #expect(character.charisma == 10)
    }

    @Test("戰士初始力量應為 14、體質應為 14")
    func warriorBaseStats() {
        let character = PlayerCharacter(name: "測試戰士", guild: .warrior)
        #expect(character.strength == 14)
        #expect(character.constitution == 14)
        #expect(character.agility == 12)
    }

    @Test("法師初始智力應為 16、智慧應為 14")
    func mageBaseStats() {
        let character = PlayerCharacter(name: "測試法師", guild: .mage)
        #expect(character.intelligence == 16)
        #expect(character.wisdom == 14)
    }

    @Test("盜賊初始敏捷應為 16")
    func thiefBaseStats() {
        let character = PlayerCharacter(name: "測試盜賊", guild: .thief)
        #expect(character.agility == 16)
    }

    @Test("牧師初始智慧應為 16")
    func clericBaseStats() {
        let character = PlayerCharacter(name: "測試牧師", guild: .cleric)
        #expect(character.wisdom == 16)
    }

    @Test("角色初始等階應為 1")
    func initialCircle() {
        let character = PlayerCharacter(name: "測試", guild: .none)
        #expect(character.circle == 1)
    }

    @Test("角色初始位置應為 village")
    func initialScene() {
        let character = PlayerCharacter(name: "測試", guild: .none)
        #expect(character.currentSceneId == "03_01_village")
    }

    @Test("當前生命值應等於最大生命值")
    func healthInitialization() {
        let character = PlayerCharacter(name: "測試", guild: .none)
        #expect(character.currentHealth == character.maxHealth)
        #expect(character.maxHealth > 0)
    }

    @Test("當前魔力值應等於最大魔力值")
    func manaInitialization() {
        let character = PlayerCharacter(name: "測試", guild: .none)
        #expect(character.currentMana == character.maxMana)
        #expect(character.maxMana > 0)
    }

    @Test("當前體力值應等於最大體力值")
    func staminaInitialization() {
        let character = PlayerCharacter(name: "測試", guild: .none)
        #expect(character.currentStamina == character.maxStamina)
        #expect(character.maxStamina > 0)
    }

    @Test("職業計算屬性應正確對應 rawValue")
    func guildComputedProperty() {
        let character = PlayerCharacter(name: "測試", guild: .warrior)
        #expect(character.guild == .warrior)
        #expect(character.guildRawValue == "05_02_warrior")
    }

    @Test("初始技能列表應為空")
    func initialSkillsEmpty() {
        let character = PlayerCharacter(name: "測試", guild: .none)
        #expect(character.skills.isEmpty)
    }

    @Test("初始背包應為空")
    func initialInventoryEmpty() {
        let character = PlayerCharacter(name: "測試", guild: .none)
        #expect(character.inventory.isEmpty)
    }

    // MARK: - 經驗值與升級測試

    @Test("角色初始經驗值應為 0")
    func initialExperience() {
        let character = PlayerCharacter(name: "測試", guild: .none)
        #expect(character.experience == 0)
    }

    @Test("升級門檻公式：circle * 50 + 50")
    func experienceToNextCircleFormula() {
        let character = PlayerCharacter(name: "測試", guild: .none)
        // circle 1 → 需要 100 經驗
        #expect(character.experienceToNextCircle == 100)
    }

    @Test("獲得經驗值後應正確累積")
    func gainExperienceAccumulation() {
        let character = PlayerCharacter(name: "測試", guild: .none)
        let didLevelUp = character.gainExperience(50)
        #expect(character.experience == 50)
        #expect(!didLevelUp)
        #expect(character.circle == 1)
    }

    @Test("經驗值達到門檻時應升級")
    func levelUpOnThreshold() {
        let character = PlayerCharacter(name: "測試戰士", guild: .warrior)
        let previousStrength = character.strength
        let didLevelUp = character.gainExperience(100)
        #expect(didLevelUp)
        #expect(character.circle == 2)
        // 戰士力量成長 +2
        #expect(character.strength == previousStrength + 2)
    }

    @Test("升級後經驗值應正確扣除，溢出保留")
    func experienceOverflow() {
        let character = PlayerCharacter(name: "測試", guild: .none)
        // circle 1 需要 100 經驗，給 120
        character.gainExperience(120)
        #expect(character.circle == 2)
        #expect(character.experience == 20)
    }

    @Test("升級後狀態值應全回復至新上限")
    func levelUpFullRestore() {
        let character = PlayerCharacter(name: "測試戰士", guild: .warrior)
        // 先損血
        character.currentHealth = 10
        character.currentMana = 5
        character.currentStamina = 5
        character.gainExperience(100)
        // 升級後應全回復
        #expect(character.currentHealth == character.maxHealth)
        #expect(character.currentMana == character.maxMana)
        #expect(character.currentStamina == character.maxStamina)
    }

    @Test("升級後狀態值上限應依新屬性重算")
    func levelUpRecalculatesMaxStats() {
        let character = PlayerCharacter(name: "測試戰士", guild: .warrior)
        let previousMaxHealth = character.maxHealth
        character.gainExperience(100)
        // 戰士體質成長 +2，healthFormula: base 60 + perConstitution 6
        // 新 maxHealth = 60 + 6 * (14 + 2) = 60 + 96 = 156
        #expect(character.maxHealth > previousMaxHealth)
        #expect(character.maxHealth == 60 + 6 * character.constitution)
    }

    @Test("一次獲得大量經驗可連升多級")
    func multiLevelUp() {
        let character = PlayerCharacter(name: "測試", guild: .none)
        // circle 1→2 需要 100，circle 2→3 需要 150，合計 250
        character.gainExperience(250)
        #expect(character.circle == 3)
        #expect(character.experience == 0)
    }
}
