//
//  SkillTests.swift
//  TextGameTests
//
//  Created by ant on 2026/3/18.
//

import Testing
import Foundation
@testable import TextGame

struct SkillTests {

    @Test("初始技能等級應為 0")
    func initialRank() {
        let skill = Skill(type: .sword)
        #expect(skill.rank == 0)
        #expect(skill.experience == 0)
        #expect(skill.fieldExperience == 0)
    }

    @Test("獲得實戰經驗")
    func gainFieldExperience() {
        let skill = Skill(type: .sword)
        skill.gainFieldExperience(25.0)
        #expect(skill.fieldExperience == 25.0)
    }

    @Test("吸收經驗每次最多 10 點")
    func absorbExperienceCap() {
        let skill = Skill(type: .sword)
        skill.gainFieldExperience(25.0)
        skill.absorbExperience()
        #expect(skill.experience == 10.0)
        #expect(skill.fieldExperience == 15.0)
    }

    @Test("經驗足夠時應升級")
    func rankUp() {
        // rank 0 時，experienceToNextRank = 0 * 100 + 50 = 50
        let skill = Skill(type: .sword, rank: 0, experience: 45.0)
        skill.gainFieldExperience(10.0)
        skill.absorbExperience()
        // experience = 45 + 10 = 55, >= 50 → 升級
        #expect(skill.rank == 1)
        #expect(skill.experience == 5.0)
    }

    @Test("連續升級")
    func multipleRankUp() {
        // rank 0, experienceToNextRank = 50
        // 直接給大量經驗
        let skill = Skill(type: .sword, rank: 0, experience: 45.0, fieldExperience: 0)
        // 手動設定大量經驗來測試連續升級
        skill.gainFieldExperience(200.0)
        // 吸收 20 次（每次 10），共 200 經驗
        for _ in 0..<20 {
            skill.absorbExperience()
        }
        #expect(skill.rank > 0)
    }

    @Test("技能分類正確")
    func skillCategory() {
        #expect(SkillType.sword.category == .weapon)
        #expect(SkillType.axe.category == .weapon)
        #expect(SkillType.bow.category == .weapon)
        #expect(SkillType.staff.category == .weapon)
        #expect(SkillType.dagger.category == .weapon)

        #expect(SkillType.lightArmor.category == .armor)
        #expect(SkillType.heavyArmor.category == .armor)
        #expect(SkillType.shield.category == .armor)
        #expect(SkillType.evasion.category == .armor)

        #expect(SkillType.forage.category == .survival)
        #expect(SkillType.firstAid.category == .survival)
        #expect(SkillType.stealth.category == .survival)
        #expect(SkillType.lockpick.category == .survival)
        #expect(SkillType.perception.category == .survival)

        #expect(SkillType.appraisal.category == .lore)
        #expect(SkillType.scholarship.category == .lore)
        #expect(SkillType.teaching.category == .lore)
        #expect(SkillType.trading.category == .lore)

        #expect(SkillType.primaryMagic.category == .magic)
        #expect(SkillType.harness.category == .magic)
        #expect(SkillType.attunement.category == .magic)
    }

    @Test("技能顯示名稱應為中文")
    func displayName() {
        let skill = Skill(type: .sword)
        #expect(skill.displayName == "劍術")
    }

    @Test("升級所需經驗值公式正確")
    func experienceToNextRank() {
        let skill0 = Skill(type: .sword, rank: 0)
        #expect(skill0.experienceToNextRank == 50.0)  // 0 * 100 + 50

        let skill1 = Skill(type: .sword, rank: 1)
        #expect(skill1.experienceToNextRank == 150.0)  // 1 * 100 + 50

        let skill5 = Skill(type: .sword, rank: 5)
        #expect(skill5.experienceToNextRank == 550.0)  // 5 * 100 + 50
    }

    @Test("無實戰經驗時吸收不會改變狀態")
    func absorbWithNoFieldExperience() {
        let skill = Skill(type: .sword, rank: 0, experience: 20.0)
        skill.absorbExperience()
        #expect(skill.experience == 20.0)
        #expect(skill.rank == 0)
    }
}
