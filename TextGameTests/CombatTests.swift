//
//  CombatTests.swift
//  TextGameTests
//
//  Created by Claude on 2026/3/23.
//

import Testing
@testable import TextGame

struct CombatTests {

    // MARK: - CombatCalculator 命中率測試

    @Test("命中率在 0.3 ~ 0.95 之間")
    func hitChanceClamped() {
        // 極低值
        let low = CombatCalculator.calculateHitChance(agility: 0, weaponSkillRank: 0, monsterLevel: 100)
        #expect(low >= 0.3)

        // 極高值
        let high = CombatCalculator.calculateHitChance(agility: 100, weaponSkillRank: 50, monsterLevel: 0)
        #expect(high <= 0.95)
    }

    @Test("高敏捷提升命中率")
    func agilityIncreasesHitChance() {
        let low = CombatCalculator.calculateHitChance(agility: 5, weaponSkillRank: 0, monsterLevel: 1)
        let high = CombatCalculator.calculateHitChance(agility: 20, weaponSkillRank: 0, monsterLevel: 1)
        #expect(high > low)
    }

    @Test("武器技能等級提升命中率")
    func weaponSkillIncreasesHitChance() {
        let low = CombatCalculator.calculateHitChance(agility: 10, weaponSkillRank: 0, monsterLevel: 1)
        let high = CombatCalculator.calculateHitChance(agility: 10, weaponSkillRank: 5, monsterLevel: 1)
        #expect(high > low)
    }

    @Test("怪物等級降低命中率")
    func monsterLevelDecreasesHitChance() {
        let low = CombatCalculator.calculateHitChance(agility: 10, weaponSkillRank: 0, monsterLevel: 5)
        let high = CombatCalculator.calculateHitChance(agility: 10, weaponSkillRank: 0, monsterLevel: 1)
        #expect(high > low)
    }

    @Test("無業遊民 vs 兔子命中率約 77%")
    func defaultHitChanceVsRabbit() {
        let chance = CombatCalculator.calculateHitChance(agility: 10, weaponSkillRank: 0, monsterLevel: 1)
        // 0.7 + 0.10 - 0.03 = 0.77
        #expect(abs(chance - 0.77) < 0.001)
    }

    // MARK: - CombatCalculator 閃避率測試

    @Test("閃避率在 0.02 ~ 0.50 之間")
    func dodgeChanceClamped() {
        let low = CombatCalculator.calculateDodgeChance(agility: 0, evasionRank: 0, monsterLevel: 100)
        #expect(low >= 0.02)

        let high = CombatCalculator.calculateDodgeChance(agility: 100, evasionRank: 50, monsterLevel: 0)
        #expect(high <= 0.50)
    }

    @Test("閃避技能等級提升閃避率")
    func evasionSkillIncreasesDodgeChance() {
        let low = CombatCalculator.calculateDodgeChance(agility: 10, evasionRank: 0, monsterLevel: 1)
        let high = CombatCalculator.calculateDodgeChance(agility: 10, evasionRank: 5, monsterLevel: 1)
        #expect(high > low)
    }

    @Test("無業遊民 vs 兔子閃避率約 9%")
    func defaultDodgeChanceVsRabbit() {
        let chance = CombatCalculator.calculateDodgeChance(agility: 10, evasionRank: 0, monsterLevel: 1)
        // 0.05 + 0.05 - 0.01 = 0.09
        #expect(abs(chance - 0.09) < 0.001)
    }

    // MARK: - CombatCalculator 傷害計算測試

    @Test("基礎傷害 = 攻擊力 - 防禦力")
    func baseDamageFormula() {
        let damage = CombatCalculator.calculateBaseDamage(attackPower: 10, defense: 3)
        #expect(damage == 7)
    }

    @Test("傷害最低為 1")
    func minimumDamageIsOne() {
        let damage = CombatCalculator.calculateBaseDamage(attackPower: 1, defense: 100)
        #expect(damage == 1)
    }

    @Test("隨機浮動結果最低為 1")
    func randomVarianceMinimumOne() {
        // 即使基礎值為 1，套用浮動後仍應 >= 1
        for _ in 0..<100 {
            let result = CombatCalculator.applyRandomVariance(1)
            #expect(result >= 1)
        }
    }

    @Test("隨機浮動結果在合理範圍內")
    func randomVarianceRange() {
        // 基礎值 10，浮動後應在 8~12 之間
        for _ in 0..<100 {
            let result = CombatCalculator.applyRandomVariance(10)
            #expect(result >= 8 && result <= 12)
        }
    }

    // MARK: - CombatCalculator 逃跑率測試

    @Test("逃跑率在 0.15 ~ 0.80 之間")
    func fleeChanceClamped() {
        let low = CombatCalculator.calculateFleeChance(agility: 0, monsterLevel: 100)
        #expect(low >= 0.15)

        let high = CombatCalculator.calculateFleeChance(agility: 100, monsterLevel: 0)
        #expect(high <= 0.80)
    }

    @Test("高敏捷提升逃跑率")
    func agilityIncreasesFleeChance() {
        let low = CombatCalculator.calculateFleeChance(agility: 5, monsterLevel: 3)
        let high = CombatCalculator.calculateFleeChance(agility: 20, monsterLevel: 3)
        #expect(high > low)
    }

    // MARK: - CombatMonster 測試

    @Test("CombatMonster 初始 HP 等於模板 HP")
    func combatMonsterInitialHealth() {
        let template = MonsterTemplate(
            id: "test", name: "測試怪", description: "", icon: "hare",
            level: 1, health: 25, attack: 5, defense: 2, experience: 10,
            lootTableId: nil, spawnScenes: []
        )
        let monster = CombatMonster(template: template)
        #expect(monster.currentHealth == 25)
        #expect(!monster.isDead)
    }

    @Test("CombatMonster HP 扣至 0 以下為 isDead")
    func combatMonsterIsDead() {
        let template = MonsterTemplate(
            id: "test", name: "測試怪", description: "", icon: "hare",
            level: 1, health: 5, attack: 1, defense: 0, experience: 3,
            lootTableId: nil, spawnScenes: []
        )
        var monster = CombatMonster(template: template)
        monster.currentHealth = 0
        #expect(monster.isDead)

        monster.currentHealth = -5
        #expect(monster.isDead)
    }

    // MARK: - PlayerCharacter 戰鬥輔助屬性測試

    @Test("totalAttackPower 裸手為力量值")
    func totalAttackBareHanded() {
        let character = PlayerCharacter(name: "測試", guild: .none)
        #expect(character.totalAttackPower == character.strength)
    }

    @Test("totalDefensePower 無裝備為 0")
    func totalDefenseNoArmor() {
        let character = PlayerCharacter(name: "測試", guild: .none)
        #expect(character.totalDefensePower == 0)
    }

    @Test("equippedWeapon 初始為 nil")
    func noEquippedWeaponInitially() {
        let character = PlayerCharacter(name: "測試", guild: .none)
        #expect(character.equippedWeapon == nil)
    }

    @Test("weaponSkillType 無武器時為 nil")
    func weaponSkillTypeNilWithoutWeapon() {
        let character = PlayerCharacter(name: "測試", guild: .none)
        #expect(character.weaponSkillType == nil)
    }

    // MARK: - SkillType 武器映射測試

    @Test("鐵劍對應劍術技能")
    func ironSwordMapsToSword() {
        #expect(SkillType.weaponSkillType(for: "01_01_iron_sword") == .sword)
    }

    @Test("戰士巨劍對應劍術技能")
    func warriorGreatswordMapsToSword() {
        #expect(SkillType.weaponSkillType(for: "01_12_warrior_greatsword") == .sword)
    }

    @Test("短弓對應弓術技能")
    func shortBowMapsToBow() {
        #expect(SkillType.weaponSkillType(for: "01_03_short_bow") == .bow)
    }

    @Test("木杖對應杖術技能")
    func woodenStaffMapsToStaff() {
        #expect(SkillType.weaponSkillType(for: "01_02_wooden_staff") == .staff)
    }

    @Test("生鏽匕首對應匕首技能")
    func rustyDaggerMapsToDagger() {
        #expect(SkillType.weaponSkillType(for: "01_04_rusty_dagger") == .dagger)
    }

    @Test("未知武器回傳 nil")
    func unknownWeaponReturnsNil() {
        #expect(SkillType.weaponSkillType(for: "unknown_weapon") == nil)
    }
}
