//
//  GameItem.swift
//  TextGame
//
//  Created by ant on 2026/3/5.
//

import Foundation
import SwiftData

/// 物品類型
enum ItemType: String, Codable {
    case weapon = "weapon"
    case armor = "armor"
    case consumable = "consumable"
    case material = "material"
    case quest = "quest"
    case misc = "misc"

    /// 中文顯示名稱
    var displayName: String {
        switch self {
        case .weapon: return "武器"
        case .armor: return "防具"
        case .consumable: return "消耗品"
        case .material: return "素材"
        case .quest: return "任務物品"
        case .misc: return "雜物"
        }
    }
}

/// 遊戲物品，可放在背包中或裝備在角色身上
@Model
final class GameItem {
    var itemId: String          // 物品模板 ID
    var name: String            // 物品名稱
    var itemDescription: String // 物品描述
    var itemTypeRawValue: String   // 物品類型（儲存 rawValue）
    var isEquipped: Bool        // 是否已裝備
    var equipSlotRawValue: String? // 可裝備的部位（儲存 rawValue）

    /// 物品類型（計算屬性）
    @Transient
    var itemType: ItemType {
        get { ItemType(rawValue: itemTypeRawValue) ?? .misc }
        set { itemTypeRawValue = newValue.rawValue }
    }

    /// 裝備部位（計算屬性）
    @Transient
    var equipSlot: EquipmentSlot? {
        get {
            guard let raw = equipSlotRawValue else { return nil }
            return EquipmentSlot(rawValue: raw)
        }
        set { equipSlotRawValue = newValue?.rawValue }
    }

    // MARK: - 數值屬性
    var attackPower: Int        // 攻擊力（武器用）
    var defensePower: Int       // 防禦力（防具用）
    var healAmount: Int         // 回復量（消耗品用）
    var value: Int              // 價值（交易用）

    // MARK: - 稀有度
    var rarity: Int             // 稀有度（數字，越大越稀有）

    // MARK: - 堆疊
    var stackCount: Int         // 目前堆疊數量
    var maxStack: Int           // 最大堆疊數量

    // MARK: - 素質修正（裝備時生效）
    var modStrength: Int        // 力量修正
    var modAgility: Int         // 敏捷修正
    var modConstitution: Int    // 體質修正
    var modIntelligence: Int    // 智力修正
    var modWisdom: Int          // 智慧修正
    var modCharisma: Int        // 魅力修正
    var modMaxHealth: Int       // 最大生命值修正
    var modMaxMana: Int         // 最大魔力值修正
    var modMaxStamina: Int      // 最大體力值修正

    // MARK: - 使用/裝備條件
    var reqCircle: Int          // 等階需求
    var reqGuilds: [String]     // 職業限制（空 = 全職業可用）
    var reqStrength: Int        // 力量需求
    var reqAgility: Int         // 敏捷需求
    var reqConstitution: Int    // 體質需求
    var reqIntelligence: Int    // 智力需求
    var reqWisdom: Int          // 智慧需求
    var reqCharisma: Int        // 魅力需求

    // MARK: - 初始化（完整參數）

    init(
        itemId: String,
        name: String,
        itemDescription: String,
        itemType: ItemType,
        equipSlot: EquipmentSlot? = nil,
        attackPower: Int = 0,
        defensePower: Int = 0,
        healAmount: Int = 0,
        value: Int = 0,
        rarity: Int = 0,
        stackCount: Int = 1,
        maxStack: Int = 1,
        modStrength: Int = 0,
        modAgility: Int = 0,
        modConstitution: Int = 0,
        modIntelligence: Int = 0,
        modWisdom: Int = 0,
        modCharisma: Int = 0,
        modMaxHealth: Int = 0,
        modMaxMana: Int = 0,
        modMaxStamina: Int = 0,
        reqCircle: Int = 0,
        reqGuilds: [String] = [],
        reqStrength: Int = 0,
        reqAgility: Int = 0,
        reqConstitution: Int = 0,
        reqIntelligence: Int = 0,
        reqWisdom: Int = 0,
        reqCharisma: Int = 0
    ) {
        self.itemId = itemId
        self.name = name
        self.itemDescription = itemDescription
        self.itemTypeRawValue = itemType.rawValue
        self.isEquipped = false
        self.equipSlotRawValue = equipSlot?.rawValue
        self.attackPower = attackPower
        self.defensePower = defensePower
        self.healAmount = healAmount
        self.value = value
        self.rarity = rarity
        self.stackCount = stackCount
        self.maxStack = maxStack
        self.modStrength = modStrength
        self.modAgility = modAgility
        self.modConstitution = modConstitution
        self.modIntelligence = modIntelligence
        self.modWisdom = modWisdom
        self.modCharisma = modCharisma
        self.modMaxHealth = modMaxHealth
        self.modMaxMana = modMaxMana
        self.modMaxStamina = modMaxStamina
        self.reqCircle = reqCircle
        self.reqGuilds = reqGuilds
        self.reqStrength = reqStrength
        self.reqAgility = reqAgility
        self.reqConstitution = reqConstitution
        self.reqIntelligence = reqIntelligence
        self.reqWisdom = reqWisdom
        self.reqCharisma = reqCharisma
    }

    // MARK: - 從模板建立

    /// 從 ItemTemplate 建立 GameItem 實例
    convenience init(from template: ItemTemplate) {
        self.init(
            itemId: template.id,
            name: template.name,
            itemDescription: template.description,
            itemType: template.itemType ?? .misc,
            equipSlot: template.equipmentSlot,
            attackPower: template.attackPower,
            defensePower: template.defensePower,
            healAmount: template.healAmount,
            value: template.value,
            rarity: template.rarity,
            stackCount: 1,
            maxStack: template.maxStack,
            modStrength: template.statModifiers.strength,
            modAgility: template.statModifiers.agility,
            modConstitution: template.statModifiers.constitution,
            modIntelligence: template.statModifiers.intelligence,
            modWisdom: template.statModifiers.wisdom,
            modCharisma: template.statModifiers.charisma,
            modMaxHealth: template.statModifiers.maxHealth,
            modMaxMana: template.statModifiers.maxMana,
            modMaxStamina: template.statModifiers.maxStamina,
            reqCircle: template.requirements.circle,
            reqGuilds: template.requirements.guilds,
            reqStrength: template.requirements.strength,
            reqAgility: template.requirements.agility,
            reqConstitution: template.requirements.constitution,
            reqIntelligence: template.requirements.intelligence,
            reqWisdom: template.requirements.wisdom,
            reqCharisma: template.requirements.charisma
        )
    }

    // MARK: - 輔助方法

    /// 檢查角色是否滿足此物品的使用/裝備條件
    func canBeUsedBy(_ character: PlayerCharacter) -> Bool {
        // 等階檢查
        if reqCircle > 0 && character.circle < reqCircle {
            return false
        }
        // 職業檢查
        if !reqGuilds.isEmpty {
            let guildRawValues = reqGuilds.compactMap { Guild(rawValue: $0) }
            if !guildRawValues.contains(character.guild) {
                return false
            }
        }
        // 屬性檢查
        if character.strength < reqStrength { return false }
        if character.agility < reqAgility { return false }
        if character.constitution < reqConstitution { return false }
        if character.intelligence < reqIntelligence { return false }
        if character.wisdom < reqWisdom { return false }
        if character.charisma < reqCharisma { return false }
        return true
    }

    /// 是否可堆疊
    var isStackable: Bool {
        maxStack > 1
    }

    /// 是否已達堆疊上限
    var isStackFull: Bool {
        stackCount >= maxStack
    }
}
