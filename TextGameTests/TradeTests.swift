//
//  TradeTests.swift
//  TextGameTests
//
//  Created by ant on 2026/3/27.
//

import Testing
import Foundation
@testable import TextGame

struct TradeTests {

    // MARK: - 購買價計算

    @Test("購買價 - 原價倍率")
    func buyPriceNormal() {
        let price = TradeCalculator.buyPrice(baseValue: 50, priceMultiplier: 1.0)
        #expect(price == 50)
    }

    @Test("購買價 - 高倍率向上取整")
    func buyPriceCeil() {
        // 戰士巨劍 value=200, multiplier=1.5 → 300
        let price = TradeCalculator.buyPrice(baseValue: 200, priceMultiplier: 1.5)
        #expect(price == 300)
    }

    @Test("購買價 - 小數向上取整")
    func buyPriceCeilDecimal() {
        // 體力草 value=5, multiplier=1.2 → 6.0 → 6
        let price = TradeCalculator.buyPrice(baseValue: 5, priceMultiplier: 1.2)
        #expect(price == 6)
    }

    @Test("購買價 - 折扣倍率")
    func buyPriceDiscount() {
        // 藥婆的治療藥水 value=10, multiplier=0.9 → 9.0 → 9
        let price = TradeCalculator.buyPrice(baseValue: 10, priceMultiplier: 0.9)
        #expect(price == 9)
    }

    @Test("購買價 - 低折扣向上取整")
    func buyPriceDiscountCeil() {
        // 木杖 value=40, multiplier=0.7 → 28.0 → 28
        let price = TradeCalculator.buyPrice(baseValue: 40, priceMultiplier: 0.7)
        #expect(price == 28)
    }

    // MARK: - 出售價計算

    @Test("出售價 - 基本半價")
    func sellPriceBasic() {
        // 鐵劍 value=50 → 25
        let price = TradeCalculator.sellPrice(baseValue: 50)
        #expect(price == 25)
    }

    @Test("出售價 - 最低 1 金")
    func sellPriceMinimum() {
        // 雞毛 value=1 → 0.5 → floor → 0 → max 1
        let price = TradeCalculator.sellPrice(baseValue: 1)
        #expect(price == 1)
    }

    @Test("出售價 - 交易技能加成")
    func sellPriceWithTrading() {
        // 鐵劍 value=50, tradingRank=10 → 50 * 0.5 * 1.1 = 27.5 → 27
        let price = TradeCalculator.sellPrice(baseValue: 50, tradingRank: 10)
        #expect(price == 27)
    }

    @Test("出售價 - 向下取整")
    func sellPriceFloor() {
        // value=15, tradingRank=0 → 15 * 0.5 = 7.5 → 7
        let price = TradeCalculator.sellPrice(baseValue: 15)
        #expect(price == 7)
    }

    @Test("出售價 - 高交易技能加成")
    func sellPriceHighTrading() {
        // value=100, tradingRank=50 → 100 * 0.5 * 1.5 = 75
        let price = TradeCalculator.sellPrice(baseValue: 100, tradingRank: 50)
        #expect(price == 75)
    }

    // MARK: - 角色金幣初始值

    @Test("角色初始金幣為 100")
    func initialGold() {
        let character = PlayerCharacter(name: "測試", guild: .none)
        #expect(character.gold == 100)
    }
}
