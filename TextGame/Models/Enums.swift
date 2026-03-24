//
//  Enums.swift
//  TextGame
//
//  Created by ant on 2026/3/5.
//

import Foundation

// MARK: - 職業

/// 玩家可選擇的職業類型
enum Guild: String, Codable, CaseIterable {
    case none = "none"
    case warrior = "warrior"
    case mage = "mage"
    case thief = "thief"
    case cleric = "cleric"

    /// 中文顯示名稱
    var displayName: String {
        switch self {
        case .none: return "無業遊民"
        case .warrior: return "戰士"
        case .mage: return "法師"
        case .thief: return "盜賊"
        case .cleric: return "牧師"
        }
    }
}

// MARK: - 技能分類

/// 技能五大分類
enum SkillCategory: String, Codable, CaseIterable {
    case weapon = "武器"
    case armor = "防具"
    case survival = "生存"
    case lore = "知識"
    case magic = "魔法"
}

// MARK: - 技能類型

/// 所有技能的詳細類型
enum SkillType: String, Codable, CaseIterable {
    // 武器
    case sword = "劍術"
    case axe = "斧術"
    case bow = "弓術"
    case staff = "杖術"
    case dagger = "匕首"

    // 防具
    case lightArmor = "輕甲"
    case heavyArmor = "重甲"
    case shield = "盾牌"
    case evasion = "閃避"

    // 生存
    case forage = "採集"
    case firstAid = "急救"
    case stealth = "潛行"
    case lockpick = "開鎖"
    case perception = "感知"

    // 知識
    case appraisal = "鑑定"
    case scholarship = "學識"
    case teaching = "教導"
    case trading = "交易"

    // 魔法
    case primaryMagic = "基礎魔法"
    case harness = "聚能"
    case attunement = "調諧"

    /// 根據武器 itemId 推導對應的武器技能類型
    static func weaponSkillType(for itemId: String) -> SkillType? {
        switch itemId {
        case "iron_sword", "warrior_greatsword":
            return .sword
        case "short_bow":
            return .bow
        case "wooden_staff":
            return .staff
        case "rusty_dagger":
            return .dagger
        default:
            return nil
        }
    }

    /// 此技能所屬的分類
    var category: SkillCategory {
        switch self {
        case .sword, .axe, .bow, .staff, .dagger:
            return .weapon
        case .lightArmor, .heavyArmor, .shield, .evasion:
            return .armor
        case .forage, .firstAid, .stealth, .lockpick, .perception:
            return .survival
        case .appraisal, .scholarship, .teaching, .trading:
            return .lore
        case .primaryMagic, .harness, .attunement:
            return .magic
        }
    }
}

// MARK: - 裝備欄位

/// 裝備可穿戴的部位
enum EquipmentSlot: String, Codable, CaseIterable {
    case head = "head"
    case body = "body"
    case hands = "hands"
    case legs = "legs"
    case feet = "feet"
    case mainHand = "mainHand"
    case offHand = "offHand"

    /// 中文顯示名稱
    var displayName: String {
        switch self {
        case .head: return "頭部"
        case .body: return "身體"
        case .hands: return "手部"
        case .legs: return "腿部"
        case .feet: return "足部"
        case .mainHand: return "主手"
        case .offHand: return "副手"
        }
    }
}
