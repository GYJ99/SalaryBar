# SalaryBar

一个常驻 macOS 顶部栏的工资可视化应用。

它会把月薪或时薪换算成实时收入，在顶部栏按秒显示“今天已经赚了多少钱”，并通过回血目标、节奏状态、剩余潜力等信息，把抽象工资变成更有感知的工作反馈。

## 项目定位

`SalaryBar` 不是网页小工具，也不是复杂记账软件。

这个项目的目标很明确：

- 常驻 `macOS Menu Bar`
- 支持月薪 / 时薪配置
- 按秒实时累计今日收入
- 支持午休、工作时段、暂停 / 继续
- 支持回血目标和解锁提醒
- 可直接打包为 `.app` 和 `.dmg`

## 当前特性

- 顶部栏实时显示当前回血金额
- 点击顶部栏展开详情面板
- 今日已赚、每秒 / 每分钟 / 每小时收入实时更新
- 工作节奏洞察：热身区、稳定输出、冲刺区、收尾区
- 今日封顶收益、剩余可回血金额、剩余工时
- 自定义回血目标列表
- 目标解锁通知
- 工作日、上下班、午休时段配置
- 常见作息预设
- 本地持久化配置
- 支持开机启动

## 技术栈

- `Swift 6`
- `SwiftUI`
- `MenuBarExtra`
- `AppKit`
- `UserDefaults + Codable`
- `ServiceManagement`
- `UserNotifications`

## 项目结构

```text
SalaryBar/
├── Assets/AppIcon
├── Sources/SalaryBar/App
├── Sources/SalaryBar/Models
├── Sources/SalaryBar/Services
├── Sources/SalaryBar/Utilities
├── Sources/SalaryBar/Views
├── Tests/SalaryBarTests
├── docs/screenshots
└── scripts
```

## 界面预览

`SalaryBar` 的交互重点不是复杂表格，而是让你在顶部栏里快速感知“今天已经回血多少、还差多少、下一步值不值得继续扛”。

### 顶部栏主面板

<p align="center">
  <img src="docs/screenshots/dashboard.png" width="360" alt="SalaryBar 详情面板">
</p>

主面板集中展示今日已赚、实时速率、当前目标、暂停状态和关键操作。打开顶部栏后，不需要进入设置页，也能立刻知道今天的回血进度。

### 今日节奏与回血潜力

<p align="center">
  <img src="docs/screenshots/today-rhythm.png" width="360" alt="SalaryBar 今日节奏">
</p>

这一块把工作日拆成更有感知的区段：当前所处节奏、今天的理论封顶、剩余可回血金额、剩余工时和进度条都会同步展示，适合拿来判断“今天还能不能再撑一会儿”。

### 搞钱成就与目标解锁

<p align="center">
  <img src="docs/screenshots/achievement-goals.png" width="360" alt="SalaryBar 搞钱成就">
</p>

目标系统会把抽象收入换成更直观的里程碑。每个目标都有进度、解锁状态和金额映射，完成后可以配合通知提醒，减少单纯盯数字带来的疲劳感。

### 设置窗口总览

设置窗口按工资、时间、目标、显示四个方向拆开，既保留必要配置项，也尽量让实时预览直接暴露在表单里。

| 工资配置 | 时间配置 |
| --- | --- |
| <img src="docs/screenshots/settings-salary.png" alt="SalaryBar 工资设置" width="480"> | <img src="docs/screenshots/settings-time.png" alt="SalaryBar 时间设置" width="480"> |

工资页负责定义计薪方式、月工时和实时换算结果；时间页则处理工作日、上下班时间、午休以及常见作息预设。

| 目标配置 | 显示配置 |
| --- | --- |
| <img src="docs/screenshots/settings-goals.png" alt="SalaryBar 目标设置" width="480"> | <img src="docs/screenshots/settings-display.png" alt="SalaryBar 显示设置" width="480"> |

目标页用于维护回血目标列表和推荐目标；显示页负责顶部栏样式、数字精度、通知偏好和开机启动等系统级体验。

## 本地开发

运行应用：

```bash
swift run
```

运行测试：

```bash
swift test
```

## 打包

### 一键打包 DMG

推荐直接使用：

```bash
./scripts/package_release.sh
```

默认会执行：

1. `swift build -c release`
2. 组装 `.app`
3. 写入 `Info.plist`
4. 本地 `ad-hoc` 签名
5. 输出 `.dmg`

默认产物：

- `dist/SalaryBar.app`
- `dist/SalaryBar-<version>.dmg`

### 使用 Git 自动生成版本号

脚本默认会优先尝试读取 Git 信息：

- `VERSION`：优先取最近的 tag，例如 `v1.2.0` 会变成 `1.2.0`
- `BUILD_NUMBER`：优先取当前 commit 数

如果仓库还没打 tag，会自动回退到默认值。

### 手动指定版本号

```bash
VERSION=1.0.1 BUILD_NUMBER=12 ./scripts/package_release.sh
```

### 执行测试后再打包

```bash
RUN_TESTS=1 ./scripts/package_release.sh
```

### 关闭 Git 版本推导

```bash
USE_GIT_VERSION=0 VERSION=1.0.0 BUILD_NUMBER=1 ./scripts/package_release.sh
```

## 签名与公证

本地开发默认使用 `ad-hoc` 签名，适合你自己机器安装测试。

如果要对外分发，建议使用正式 Apple Developer 证书签名，并接入 notarization。

### 使用正式签名

```bash
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
./scripts/package_release.sh
```

### 使用 notarytool 公证

先在本机配置好 keychain profile，例如：

```bash
xcrun notarytool store-credentials "AC_PROFILE"
```

然后执行：

```bash
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
NOTARIZE=1 \
NOTARY_PROFILE="AC_PROFILE" \
./scripts/package_release.sh
```

脚本会自动：

1. 签名 `.app`
2. 打包 `.dmg`
3. 提交 `notarytool`
4. 等待公证结果
5. 对 `.dmg` 执行 `stapler`

## GitHub Release 自动上传

可以实现，而且仓库里已经加好了工作流：

- [release.yml](.github/workflows/release.yml)

它会在你推送 `v*` 标签时自动：

1. 在 GitHub 的 macOS Runner 上构建项目
2. 生成 `.dmg`
3. 自动创建 GitHub Release
4. 把 `.dmg` 和 `SHA256SUMS.txt` 上传到 Release Assets

### 使用方式

提交代码后执行：

```bash
git tag v1.0.0
git push origin main --tags
```

或者只推标签：

```bash
git push origin v1.0.0
```

然后到 GitHub 仓库的 `Actions` / `Releases` 页面就能看到自动生成的发布版本。

### 说明

- 这里的 “Releases” 指的是 `GitHub Releases`，不是 Git 本身自带能力
- 这个流程不需要 Apple Developer 账号
- 生成的包仍然是 `ad-hoc` 签名，适合测试和个人分发
- 如果以后你有开发者账号，可以再把正式签名和 notarization 接到这个工作流里

## 文档

项目内已经包含以下设计和方案文档：

- [功能需求文档](docs/工资条回血器-功能需求文档.md)
- [UI 结构说明文档](docs/工资条回血器-UI结构说明文档.md)
- [技术方案设计文档](docs/工资条回血器-技术方案设计文档.md)

## 图标资源

- 正式图标源文件：`Assets/AppIcon/app_icon.svg`
- 项目内预生成图标：`Assets/AppIcon/AppIcon.icns`
- 打包时优先使用项目里的 `.icns`
- 如果你修改了 SVG，可执行：`./scripts/generate_app_icon.sh`

## Git 发布建议

更推荐的 Git 发布方式：

- 源码入仓库
- 产物通过 GitHub Releases 上传
- 用 tag 驱动 `VERSION`

## 后续可继续扩展

- 深色模式专项优化
- 顶部栏数字过渡动画
- 周报 / 月报统计
- iCloud 同步
- 更多作息模板
- 正式品牌图标和启动页
