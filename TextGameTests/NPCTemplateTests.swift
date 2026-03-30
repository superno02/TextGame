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

    // MARK: - 輔助方法

    /// 建立測試用的 DialogueContext
    private func makeContext(
        guild: Guild? = nil,
        circle: Int = 0,
        itemIds: Set<String> = [],
        affinity: Int = 0
    ) -> DialogueContext {
        DialogueContext(
            playerGuild: guild,
            playerCircle: circle,
            inventoryItemIds: itemIds,
            npcAffinity: affinity
        )
    }

    // MARK: - 根選項過濾測試

    @Test("無條件對話所有玩家都能看到")
    func unconditionalDialogue() {
        let npc = NPCTemplateLoader.shared.template(for: "04_01_village_elder")
        #expect(npc != nil)
        let options = npc!.availableRootOptions(context: makeContext())
        #expect(!options.isEmpty)
    }

    @Test("無條件對話不管職業都能觸發")
    func unconditionalForAllGuilds() {
        let npc = NPCTemplateLoader.shared.template(for: "04_01_village_elder")!
        let noneOptions = npc.availableRootOptions(context: makeContext(guild: .none))
        let warriorOptions = npc.availableRootOptions(context: makeContext(guild: .warrior))
        // 村長的對話都是無條件的，數量應該相同
        #expect(noneOptions.count == warriorOptions.count)
    }

    @Test("戰士專屬對話只有戰士能觸發")
    func warriorOnlyDialogue() {
        let npc = NPCTemplateLoader.shared.template(for: "04_03_blacksmith")
        #expect(npc != nil)

        let warriorOptions = npc!.availableRootOptions(context: makeContext(guild: .warrior))
        let mageOptions = npc!.availableRootOptions(context: makeContext(guild: .mage))

        // 鐵匠有 guild:05_02_warrior 條件的根對話，戰士應比法師多至少一個選項
        #expect(warriorOptions.count > mageOptions.count)
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

        let mageOptions = hermit!.availableRootOptions(context: makeContext(guild: .mage))
        let clericOptions = hermit!.availableRootOptions(context: makeContext(guild: .cleric))
        let thiefOptions = hermit!.availableRootOptions(context: makeContext(guild: .thief))

        // 法師應看到 guild:mage 條件的選項
        let mageSpecific = mageOptions.filter { $0.condition == "guild:05_03_mage" }
        #expect(mageSpecific.count == 1)

        // 牧師應看到 guild:cleric 條件的選項
        let clericSpecific = clericOptions.filter { $0.condition == "guild:05_05_cleric" }
        #expect(clericSpecific.count == 1)

        // 盜賊不應看到法師或牧師專屬對話
        let thiefSpecific = thiefOptions.filter {
            $0.condition == "guild:05_03_mage" || $0.condition == "guild:05_05_cleric"
        }
        #expect(thiefSpecific.isEmpty)
    }

    // MARK: - goto 跳轉測試

    @Test("findNode 遞迴搜尋正確")
    func dialogueGotoNavigation() {
        // 守衛阿強有巢狀對話結構，測試 findNode 能找到深層節點
        let guard_ = NPCTemplateLoader.shared.template(for: "04_06_gate_guard")
        #expect(guard_ != nil)

        // 根節點應該能找到
        let rootNode = guard_!.dialogueRoot.first
        #expect(rootNode != nil)
        let found = guard_!.findNode(byId: rootNode!.id)
        #expect(found != nil)
        #expect(found!.id == rootNode!.id)

        // 搜尋不存在的節點應回傳 nil
        let missing = guard_!.findNode(byId: "nonexistent_node_id")
        #expect(missing == nil)
    }

    // MARK: - 商人 openShop 動作測試

    @Test("所有商人至少有一個 openShop 對話路徑")
    func merchantHasOpenShopAction() {
        let merchants = NPCTemplateLoader.shared.merchants()
        #expect(!merchants.isEmpty)

        for merchant in merchants {
            let hasOpenShop = containsAction(in: merchant.dialogueRoot, action: "openShop")
            #expect(hasOpenShop, "商人 \(merchant.name)（\(merchant.id)）缺少 openShop 動作")
        }
    }

    /// 遞迴檢查對話樹中是否包含指定動作
    private func containsAction(in nodes: [DialogueNode], action: String) -> Bool {
        for node in nodes {
            if node.action == action { return true }
            if containsAction(in: node.options, action: action) { return true }
        }
        return false
    }

    // MARK: - 條件評估測試

    @Test("guild 條件評估正確")
    func conditionGuild() {
        let warriorCtx = makeContext(guild: .warrior)
        let mageCtx = makeContext(guild: .mage)

        #expect(evaluateCondition("guild:05_02_warrior", context: warriorCtx) == true)
        #expect(evaluateCondition("guild:05_02_warrior", context: mageCtx) == false)
        #expect(evaluateCondition(nil, context: warriorCtx) == true) // nil 條件永遠通過
    }

    @Test("circle 條件評估正確")
    func conditionCircle() {
        let circle3 = makeContext(circle: 3)
        let circle1 = makeContext(circle: 1)

        #expect(evaluateCondition("circle:3", context: circle3) == true)
        #expect(evaluateCondition("circle:3", context: circle1) == false)
        #expect(evaluateCondition("circle:1", context: circle3) == true) // >= 判斷
    }

    @Test("item 條件評估正確")
    func conditionItem() {
        let withSword = makeContext(itemIds: Set(["01_01_iron_sword"]))
        let empty = makeContext()

        #expect(evaluateCondition("item:01_01_iron_sword", context: withSword) == true)
        #expect(evaluateCondition("item:01_01_iron_sword", context: empty) == false)
    }

    @Test("affinity 條件評估正確")
    func conditionAffinity() {
        let high = makeContext(affinity: 10)
        let low = makeContext(affinity: 3)

        #expect(evaluateCondition("affinity:10", context: high) == true)
        #expect(evaluateCondition("affinity:10", context: low) == false)
        #expect(evaluateCondition("affinity:5", context: high) == true) // >= 判斷
    }

    @Test("無效條件格式回傳 false")
    func conditionInvalidFormat() {
        let ctx = makeContext()
        #expect(evaluateCondition("invalid", context: ctx) == false)
        #expect(evaluateCondition("unknown:value", context: ctx) == false)
        #expect(evaluateCondition("circle:abc", context: ctx) == false)
    }

    // MARK: - DialogueNode JSON 解碼測試

    @Test("DialogueNode JSON 解碼正確")
    func dialogueNodeDecoding() throws {
        let json = """
        {
            "id": "test_node",
            "label": "測試選項",
            "response": "NPC 回應",
            "condition": "guild:05_02_warrior",
            "action": "openShop",
            "options": [
                {
                    "id": "child_node",
                    "label": "子選項",
                    "response": "子回應"
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(DialogueNode.self, from: data)

        #expect(node.id == "test_node")
        #expect(node.label == "測試選項")
        #expect(node.response == "NPC 回應")
        #expect(node.condition == "guild:05_02_warrior")
        #expect(node.action == "openShop")
        #expect(node.goto == nil)
        #expect(node.options.count == 1)
        #expect(node.options[0].id == "child_node")
        #expect(node.options[0].options.isEmpty) // 省略 options 時預設為空陣列
    }

    @Test("DialogueNode 省略 optional 欄位解碼正確")
    func dialogueNodeMinimalDecoding() throws {
        let json = """
        {
            "id": "minimal",
            "label": "最簡選項",
            "response": "最簡回應"
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(DialogueNode.self, from: data)

        #expect(node.id == "minimal")
        #expect(node.condition == nil)
        #expect(node.action == nil)
        #expect(node.goto == nil)
        #expect(node.options.isEmpty)
    }
}
