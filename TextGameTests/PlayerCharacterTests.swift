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
        #expect(character.currentSceneId == "village")
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
        #expect(character.guildRawValue == "warrior")
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
}
