//
//  GameItemTests.swift
//  TextGameTests
//
//  Created by ant on 2026/3/18.
//

import Testing
import Foundation
@testable import TextGame

struct GameItemTests {

    @Test("無條件物品所有角色都能使用")
    func noRequirements() {
        let item = GameItem(
            itemId: "test",
            name: "測試物品",
            itemDescription: "一個測試用物品",
            itemType: .misc
        )
        let character = PlayerCharacter(name: "測試", guild: .none)
        #expect(item.canBeUsedBy(character))
    }

    @Test("等階不足時不能使用")
    func circleRequirement() {
        let item = GameItem(
            itemId: "test",
            name: "高等武器",
            itemDescription: "測試",
            itemType: .weapon,
            reqCircle: 5
        )
        let character = PlayerCharacter(name: "測試", guild: .none)
        // 角色初始等階為 1，需求為 5
        #expect(!item.canBeUsedBy(character))
    }

    @Test("職業限制正確生效")
    func guildRequirement() {
        let item = GameItem(
            itemId: "test",
            name: "戰士專用",
            itemDescription: "測試",
            itemType: .weapon,
            reqGuilds: ["05_02_warrior"]
        )
        let warrior = PlayerCharacter(name: "戰士", guild: .warrior)
        let mage = PlayerCharacter(name: "法師", guild: .mage)
        #expect(item.canBeUsedBy(warrior))
        #expect(!item.canBeUsedBy(mage))
    }

    @Test("屬性需求檢查")
    func statRequirement() {
        let item = GameItem(
            itemId: "test",
            name: "力量武器",
            itemDescription: "測試",
            itemType: .weapon,
            reqStrength: 20
        )
        let character = PlayerCharacter(name: "測試", guild: .none)
        // 無業遊民力量為 10，需求為 20
        #expect(!item.canBeUsedBy(character))
    }

    @Test("可堆疊判斷")
    func stackable() {
        let stackable = GameItem(
            itemId: "potion",
            name: "藥水",
            itemDescription: "測試",
            itemType: .consumable,
            stackCount: 5,
            maxStack: 20
        )
        #expect(stackable.isStackable)
        #expect(!stackable.isStackFull)

        let nonStackable = GameItem(
            itemId: "sword",
            name: "劍",
            itemDescription: "測試",
            itemType: .weapon,
            stackCount: 1,
            maxStack: 1
        )
        #expect(!nonStackable.isStackable)
    }

    @Test("堆疊已滿判斷")
    func stackFull() {
        let item = GameItem(
            itemId: "potion",
            name: "藥水",
            itemDescription: "測試",
            itemType: .consumable,
            stackCount: 20,
            maxStack: 20
        )
        #expect(item.isStackFull)
    }

    @Test("物品類型計算屬性正確")
    func itemTypeComputed() {
        let item = GameItem(
            itemId: "test",
            name: "測試",
            itemDescription: "測試",
            itemType: .weapon
        )
        #expect(item.itemType == .weapon)
    }

    @Test("裝備部位計算屬性正確")
    func equipSlotComputed() {
        let item = GameItem(
            itemId: "test",
            name: "測試",
            itemDescription: "測試",
            itemType: .armor,
            equipSlot: .body
        )
        #expect(item.equipSlot == .body)
    }

    @Test("預設為未裝備狀態")
    func defaultNotEquipped() {
        let item = GameItem(
            itemId: "test",
            name: "測試",
            itemDescription: "測試",
            itemType: .weapon
        )
        #expect(!item.isEquipped)
    }
}
