//
//  NPCTemplateTests.swift
//  TextGameTests
//
//  Created by ant on 2026/3/18.
//

import Testing
import Foundation
@testable import TextGame

struct NPCTemplateTests {

    @Test("無條件對話所有玩家都能看到")
    func unconditionalDialogue() {
        let npc = NPCTemplateLoader.shared.template(for: "04_01_village_elder")
        #expect(npc != nil)
        let dialogues = npc!.availableDialogues(playerGuild: nil)
        #expect(!dialogues.isEmpty)
    }

    @Test("無條件對話不管職業都能觸發")
    func unconditionalForAllGuilds() {
        let npc = NPCTemplateLoader.shared.template(for: "04_01_village_elder")!
        let noneDialogues = npc.availableDialogues(playerGuild: .none)
        let warriorDialogues = npc.availableDialogues(playerGuild: .warrior)
        // 村長的對話都是無條件的，數量應該相同
        #expect(noneDialogues.count == warriorDialogues.count)
    }

    @Test("戰士專屬對話只有戰士能觸發")
    func warriorOnlyDialogue() {
        let npc = NPCTemplateLoader.shared.template(for: "04_03_blacksmith")
        #expect(npc != nil)

        let warriorDialogues = npc!.availableDialogues(playerGuild: .warrior)
        let mageDialogues = npc!.availableDialogues(playerGuild: .mage)

        // 鐵匠有 "guild:05_02_warrior" 條件的對話
        let warriorOnly = warriorDialogues.filter { $0.condition == "guild:05_02_warrior" }
        let mageOnly = mageDialogues.filter { $0.condition == "guild:05_02_warrior" }
        #expect(warriorOnly.count == 1)
        #expect(mageOnly.isEmpty)
    }

    @Test("商人判定正確")
    func merchantDetection() {
        let merchant = NPCTemplateLoader.shared.template(for: "04_03_blacksmith")
        #expect(merchant?.isMerchant == true)

        let guard_ = NPCTemplateLoader.shared.template(for: "04_06_gate_guard")
        #expect(guard_?.isMerchant == false)
    }

    @Test("商人列表應不為空")
    func merchantList() {
        let merchants = NPCTemplateLoader.shared.merchants()
        #expect(!merchants.isEmpty)
    }

    @Test("法師與牧師的隱居老者對話")
    func hermitGuildDialogues() {
        let hermit = NPCTemplateLoader.shared.template(for: "04_07_hermit")
        #expect(hermit != nil)

        let mageDialogues = hermit!.availableDialogues(playerGuild: .mage)
        let clericDialogues = hermit!.availableDialogues(playerGuild: .cleric)
        let thiefDialogues = hermit!.availableDialogues(playerGuild: .thief)

        // 法師應看到 guild:mage 對話
        let mageSpecific = mageDialogues.filter { $0.condition == "guild:05_03_mage" }
        #expect(mageSpecific.count == 1)

        // 牧師應看到 guild:cleric 對話
        let clericSpecific = clericDialogues.filter { $0.condition == "guild:05_05_cleric" }
        #expect(clericSpecific.count == 1)

        // 盜賊不應看到法師或牧師專屬對話
        let thiefSpecific = thiefDialogues.filter {
            $0.condition == "guild:05_03_mage" || $0.condition == "guild:05_05_cleric"
        }
        #expect(thiefSpecific.isEmpty)
    }
}
