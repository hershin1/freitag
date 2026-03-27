## Freitag iOS App — Xcode 配置与运行指南

本文档将手把手教你如何在 Xcode 中配置和运行 freitag 项目。即使你之前没用过 Xcode，按照这些步骤也能顺利完成。

---

### 前置条件

在开始之前，请确认以下几点：

你的 Mac 上已安装 Xcode 15.0 或更高版本（从 Mac App Store 免费下载）。你有一个 Apple ID（用于在 Xcode 中签名 app）。你有一台运行 iOS 17 或更高版本的 iPhone，以及一根 USB 线（或通过 WiFi 连接）。

---

### 第一步：在 Xcode 中创建新项目

1. 打开 Xcode，选择 **Create New Project**（或菜单栏 File → New → Project）
2. 在模板选择界面，选择顶部的 **iOS** 标签
3. 选择 **App**，点击 **Next**
4. 填写项目信息：
   - **Product Name**: `freitag`
   - **Team**: 选择你的 Apple ID（如果没有，下一步会教你添加）
   - **Organization Identifier**: `com.freitag`（可以自定义）
   - **Interface**: 选择 **SwiftUI**
   - **Language**: 选择 **Swift**
   - **Storage**: 选择 **SwiftData**
   - 取消勾选 Include Tests
5. 点击 **Next**，选择一个保存位置（建议选桌面或文稿），点击 **Create**

Xcode 会自动生成一个基础项目。我们接下来会用 freitag 的源代码替换它。

---

### 第二步：登录 Apple ID

如果你在创建项目时没有看到 Team 选项，需要先登录：

1. 打开 Xcode 菜单：**Xcode → Settings**（或按 `Cmd + ,`）
2. 点击顶部的 **Accounts** 标签
3. 点击左下角的 **+** 按钮，选择 **Apple ID**
4. 输入你的 Apple ID 和密码，登录
5. 登录成功后关闭设置窗口

回到项目设置（点击左侧导航栏最顶部的蓝色项目图标），在 **Signing & Capabilities** 中，将 **Team** 选择为你刚登录的 Apple ID。

---

### 第三步：导入 freitag 源代码

我已经生成了全部源代码。现在需要把它们放进 Xcode 项目中。

1. 在 Finder 中打开源代码目录（我会告诉你路径）
2. 在 Xcode 左侧的文件导航栏中，找到 `freitag` 文件夹（蓝色图标）
3. **删除 Xcode 自动生成的文件**：选中 `freitag` 文件夹下自动生成的 `ContentView.swift` 和 `FreitagApp.swift`（如果有 `Item.swift` 也选中），右键 → **Delete** → 选择 **Move to Trash**
4. **拖入源代码**：从 Finder 中，将源代码目录下的 `freitag/` 文件夹里的所有子文件夹和文件（App、Models、Services、ViewModels、Views、Utilities）拖到 Xcode 左侧导航栏的 `freitag` 文件夹上
5. 在弹出的对话框中：
   - 勾选 **Copy items if needed**
   - 确认 **Create groups** 被选中（不是 Create folder references）
   - 确认 Target 列表中 **freitag** 被勾选
   - 点击 **Finish**

---

### 第四步：添加 SwiftSoup 依赖

freitag 使用 SwiftSoup 库来解析微信文章的 HTML 内容。

1. 在 Xcode 菜单中选择 **File → Add Package Dependencies...**
2. 在搜索框中粘贴：`https://github.com/scinfu/SwiftSoup.git`
3. 等待 Xcode 加载包信息（可能需要几秒钟）
4. 版本规则保持默认（Up to Next Major Version, 从 2.7.0 起）
5. 点击 **Add Package**
6. 在下一步中，确认 **SwiftSoup** 被勾选，Target 选择 **freitag**
7. 点击 **Add Package**

完成后，你可以在左侧导航栏底部的 **Package Dependencies** 中看到 SwiftSoup。

---

### 第五步：配置 App Group

App Group 让主 App 和 Share Extension 能共享数据。

1. 在左侧导航栏中，点击最顶部的蓝色项目图标
2. 在中间面板中，选择 **Targets** 列表下的 **freitag**（主 App target）
3. 点击顶部的 **Signing & Capabilities** 标签
4. 点击左上角的 **+ Capability** 按钮
5. 搜索 **App Groups**，双击添加
6. 在 App Groups 区域，点击 **+** 按钮
7. 输入：`group.com.freitag.app`
8. 点击 **OK**

同时，确认 `freitag.entitlements` 文件已出现在项目中。如果没有，把我生成的 `freitag/freitag.entitlements` 文件拖入 Xcode 项目。

---

### 第六步：添加 Share Extension Target

1. 在 Xcode 菜单中选择 **File → New → Target...**
2. 在 iOS 标签下，搜索或找到 **Share Extension**
3. 点击 **Next**
4. 填写信息：
   - **Product Name**: `FreitagShareExtension`
   - **Team**: 选择同一个 Apple ID
   - **Language**: Swift
   - **Embed in Application**: 选择 freitag
5. 点击 **Finish**
6. 如果弹出 "Activate scheme" 对话框，点击 **Activate**

Xcode 会自动创建一个 `FreitagShareExtension` 文件夹。现在替换它的内容：

7. **删除自动生成的文件**：在 Xcode 左侧导航栏中找到 `FreitagShareExtension` 文件夹，删除里面自动生成的 `ShareViewController.swift`（和 `MainInterface.storyboard` 如果有的话）
8. **拖入源代码**：将我生成的 `FreitagShareExtension/` 文件夹中的文件（ShareViewController.swift、ShareExtensionView.swift、ShareExtensionViewModel.swift、Info.plist）拖入 Xcode 的 `FreitagShareExtension` 文件夹
   - 勾选 **Copy items if needed**
   - Target 确认选中 **FreitagShareExtension**

---

### 第七步：配置 Share Extension

#### 7.1 添加 App Group

1. 在 Targets 列表中选择 **FreitagShareExtension**
2. 点击 **Signing & Capabilities**
3. 点击 **+ Capability** → 搜索 **App Groups** → 双击添加
4. 添加同一个 Group：`group.com.freitag.app`

#### 7.2 共享文件的 Target Membership

Share Extension 需要访问主 App 的部分代码。在 Xcode 左侧导航栏中，逐个选中以下文件，在右侧的 **File Inspector**（右边栏）中，找到 **Target Membership** 区域，勾选 **FreitagShareExtension**：

需要共享的文件（勾选两个 target）：
- `App/AppConstants.swift`
- `App/SharedModelContainer.swift`
- `Models/Article.swift`
- `Models/Analysis.swift`
- `Models/AIProvider.swift`

操作方法：选中文件 → 看右侧面板（如果看不到，按 `Cmd + Option + 1` 打开）→ 在 Target Membership 中同时勾选 freitag 和 FreitagShareExtension。

#### 7.3 添加 SwiftSoup 到 Share Extension

1. 选择 **FreitagShareExtension** target
2. 滚动到 **Frameworks, Libraries, and Embedded Content** 区域
3. 点击 **+** 按钮
4. 搜索 **SwiftSoup**，选中后点击 **Add**

#### 7.4 配置 Info.plist

检查 FreitagShareExtension 的 Info.plist 已正确设置。如果 Xcode 自动生成了 Info.plist，确认 NSExtension 部分包含：

- NSExtensionPointIdentifier: `com.apple.share-services`
- NSExtensionPrincipalClass: `$(PRODUCT_MODULE_NAME).ShareViewController`
- NSExtensionActivationRule 下的 NSExtensionActivationSupportsWebURLWithMaxCount: `1`

如果不确定，直接用我生成的 Info.plist 替换。

---

### 第八步：连接 iPhone 并运行

1. 用 USB 线连接你的 iPhone 到 Mac
2. iPhone 上可能弹出"是否信任此电脑"，选择 **信任**
3. 在 Xcode 顶部工具栏，点击运行目标（模拟器名称旁边的下拉菜单），选择你的 iPhone 设备
4. 确保左上角的 scheme 选择的是 **freitag**（不是 FreitagShareExtension）
5. 点击 **运行按钮**（三角形 ▶️）或按 `Cmd + R`

#### 首次运行可能遇到的问题

**"Unable to install app" / 签名错误**：
- 到 iPhone 的 设置 → 通用 → VPN 与设备管理 → 找到你的开发者 App → 信任

**"Untrusted Developer"**：
- 同上，在 iPhone 设置中信任你的开发者证书

**Build 报错**：
- 检查所有源文件是否都导入成功（Xcode 左侧是否能看到所有文件）
- 检查 SwiftSoup 包是否成功添加
- 确认 Deployment Target 设置为 iOS 17.0

---

### 第九步：测试 Share Extension

1. 确保 freitag 主 App 已经成功安装到手机上
2. 打开微信，找到一篇公众号文章
3. 点击右上角的 **...** 按钮
4. 在弹出菜单中选择 **更多**（如果在分享面板中找不到 freitag）
5. 找到 **freitag** 图标并点击
6. 等待看到"已保存"提示

如果在分享面板中找不到 freitag：
- 滑到最右边，点击 **更多**
- 在列表中找到 freitag，打开它的开关
- 你也可以长按拖动来调整它的位置

---

### 第十步：配置 AI 服务

1. 打开 freitag App
2. 点击底部的 **设置** 标签
3. 选择 AI 服务商（推荐 DeepSeek，性价比高，中文理解好）
4. 输入你的 API Key
5. 点击 **测试连接** 确认配置正确
6. 返回文章列表，点击你分享的文章，点击 **AI 智能分析**

#### 如何获取 API Key

**DeepSeek**：访问 https://platform.deepseek.com → 注册 → API Keys → 创建新 Key

**OpenAI**：访问 https://platform.openai.com → 注册 → API Keys → 创建新 Key

---

### 常见问题

**Q: 免费 Apple ID 可以用吗？**
A: 可以。免费 Apple ID 能在自己的设备上安装和运行 App，但每 7 天需要重新运行一次（重新用 Xcode 安装）。付费开发者账号（$99/年）没有这个限制。

**Q: App Group 配置失败怎么办？**
A: 免费账号在某些情况下可能无法使用 App Group。如果遇到这种情况，你可以在主 App 中使用「粘贴链接」功能代替 Share Extension。在微信中长按文章标题 → 复制链接 → 打开 freitag → 点击右上角 + 号 → 粘贴链接。

**Q: 文章内容显示为空？**
A: 部分微信文章使用 JavaScript 动态渲染内容。目前的解析方案可能无法获取这类文章的正文。App 会显示提示信息。后续版本可以通过 WKWebView 方案解决。

**Q: 支持哪些 AI 服务商？**
A: 任何兼容 OpenAI API 格式的服务商都可以使用。包括 OpenAI、DeepSeek、智谱 AI、月之暗面 (Moonshot) 等。在设置中选择「自定义」，填入对应的 Base URL 和模型名称即可。
