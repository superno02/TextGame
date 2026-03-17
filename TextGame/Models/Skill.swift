//
//  Skill.swift
//  TextGame
//
//  Created by ant on 2026/3/5.
//

import Foundation
import SwiftData

/// 角色技能，記錄技能類型、等級與經驗值
@Model
final class Skill {
    var type: SkillType
    var rank: Int            // 技能等級
    var experience: Double   // 目前累積經驗值
    var fieldExperience: Double  // 尚未吸收的實戰經驗

    /// 升級所需經驗值（隨等級遞增）
    var experienceToNextRank: Double {
        return Double(rank) * 100.0 + 50.0
    }

    /// 技能所屬的分類
    var category: SkillCategory {
        return type.category
    }

    /// 技能顯示名稱
    var displayName: String {
        return type.rawValue
    }

    init(type: SkillType, rank: Int = 0, experience: Double = 0, fieldExperience: Double = 0) {
        self.type = type
        self.rank = rank
        self.experience = experience
        self.fieldExperience = fieldExperience
    }

    /// 獲得實戰經驗
    func gainFieldExperience(_ amount: Double) {
        fieldExperience += amount
    }

    /// 吸收實戰經驗轉為正式經驗，若足夠則升級
    func absorbExperience() {
        guard fieldExperience > 0 else { return }

        let absorbed = min(fieldExperience, 10.0)  // 每次最多吸收 10 點
        fieldExperience -= absorbed
        experience += absorbed

        // 檢查是否升級
        while experience >= experienceToNextRank {
            experience -= experienceToNextRank
            rank += 1
        }
    }
}
