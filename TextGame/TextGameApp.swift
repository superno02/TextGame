//
//  TextGameApp.swift
//  TextGame
//
//  Created by ant on 2026/3/5.
//

import SwiftUI
import SwiftData

@main
struct TextGameApp: App {
    let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            PlayerCharacter.self,
            Skill.self,
            GameItem.self,
            SaveSlot.self
        ])
        let config = ModelConfiguration(schema: schema)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Schema 不相容時，刪除舊資料庫並重建
            print("[TextGameApp] ModelContainer 建立失敗，嘗試重建資料庫：\(error)")
            let fileManager = FileManager.default
            if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let storeURL = appSupport.appendingPathComponent("default.store")
                for suffix in ["", "-wal", "-shm"] {
                    let fileURL = storeURL.appendingPathExtension(suffix.isEmpty ? "" : String(suffix.dropFirst()))
                    try? fileManager.removeItem(at: URL(fileURLWithPath: storeURL.path + suffix))
                }
            }
            do {
                modelContainer = try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("[TextGameApp] 無法建立 ModelContainer：\(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            StartView()
        }
        .modelContainer(modelContainer)
    }
}
