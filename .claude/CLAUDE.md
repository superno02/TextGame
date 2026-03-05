# TextGame 專案設定

## 語言
- 永遠使用繁體中文回答，包含所有提示訊息

## 技術棧
- Swift、SwiftUI、SwiftData
- 最低部署目標：依 Xcode 專案設定為準

## 程式碼風格
- 使用 4 格空白縮排
- 型別名稱使用 PascalCase，屬性與方法使用 camelCase
- SwiftUI 狀態使用 `@State private var`
- 優先使用 Swift async/await，避免使用 Combine
- 使用 Swift Testing 框架撰寫單元測試

## 架構原則
- 遵循 SwiftUI 的資料驅動模式
- Model 層使用 SwiftData（`@Model`）
- 保持 View 簡潔，複雜邏輯抽取至獨立方法或 ViewModel
