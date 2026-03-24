//
//  TemplateLoaderTests.swift
//  TextGameTests
//
//  Created by ant on 2026/3/18.
//

import Testing
import Foundation
@testable import TextGame

struct TemplateLoaderTests {

    // MARK: - SceneTemplateLoader

    @Test("場景模板應成功載入")
    func sceneLoading() {
        let loader = SceneTemplateLoader.shared
        #expect(loader.loadError == nil)
        #expect(!loader.allScenes().isEmpty)
    }

    @Test("應能查詢 village 場景")
    func villageScene() {
        let scene = SceneTemplateLoader.shared.scene(for: "village")
        #expect(scene != nil)
        #expect(scene?.name == "村莊")
    }

    @Test("場景應有出口")
    func sceneExits() {
        let scene = SceneTemplateLoader.shared.scene(for: "village")
        #expect(scene != nil)
        #expect(!scene!.exits.isEmpty)
    }

    // MARK: - MonsterTemplateLoader

    @Test("怪物模板應成功載入")
    func monsterLoading() {
        let loader = MonsterTemplateLoader.shared
        #expect(loader.loadError == nil)
        #expect(!loader.allTemplates().isEmpty)
    }

    @Test("應能查詢 rabbit 怪物")
    func rabbitMonster() {
        let monster = MonsterTemplateLoader.shared.template(for: "rabbit")
        #expect(monster != nil)
        #expect(monster?.name == "兔子")
    }

    @Test("後山場景應有怪物")
    func mountainMonsters() {
        let monsters = MonsterTemplateLoader.shared.monstersInScene("mountain")
        #expect(!monsters.isEmpty)
    }

    // MARK: - NPCTemplateLoader

    @Test("NPC 模板應成功載入")
    func npcLoading() {
        let loader = NPCTemplateLoader.shared
        #expect(loader.loadError == nil)
        #expect(!loader.allTemplates().isEmpty)
    }

    @Test("應能查詢 village_elder NPC")
    func villageElderNPC() {
        let npc = NPCTemplateLoader.shared.template(for: "village_elder")
        #expect(npc != nil)
        #expect(npc?.name == "村長老伯")
    }

    // MARK: - ItemTemplateLoader

    @Test("物品模板應成功載入")
    func itemLoading() {
        let loader = ItemTemplateLoader.shared
        #expect(loader.loadError == nil)
        #expect(!loader.allTemplates().isEmpty)
    }

    @Test("應能查詢 iron_sword 物品")
    func ironSwordItem() {
        let item = ItemTemplateLoader.shared.template(for: "iron_sword")
        #expect(item != nil)
        #expect(item?.name == "鐵劍")
    }

    // MARK: - GuildTemplateLoader

    @Test("職業模板應成功載入")
    func guildLoading() {
        let loader = GuildTemplateLoader.shared
        #expect(loader.loadError == nil)
        #expect(loader.templates.count == 5)
    }

    @Test("應能查詢 warrior 職業")
    func warriorGuild() {
        let guild = GuildTemplateLoader.shared.template(for: "warrior")
        #expect(guild != nil)
        #expect(guild?.name == "戰士")
    }

    @Test("可選擇職業應排除 none")
    func selectableGuilds() {
        let selectable = GuildTemplateLoader.shared.selectableGuilds()
        #expect(selectable.count == 4)
        #expect(selectable.allSatisfy { $0.id != "none" })
    }
}
