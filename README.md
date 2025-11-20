# MacWallpaper

一款使用 Swift 设计的 macOS 动态壁纸软件

## 功能特性

- 🎬 **MP4 格式支持**: 播放 MP4 格式的动态壁纸
- 🎨 **优雅的用户界面**: 使用 Apple 推荐的 AppKit 框架设计
- 🖼️ **壁纸库管理**: 网格视图展示所有已添加的壁纸
- 🔇 **静音选项**: 可配置壁纸音频播放
- 📊 **质量设置**: 支持低、中、高、原始等多种播放质量
- 🔍 **壁纸搜索**: 提供在线壁纸搜索功能
- ➕ **手动添加**: 支持从本地文件系统添加 MP4 壁纸
- 📍 **状态栏图标**: 常驻状态栏，便捷访问
- 🚫 **Dock 栏隐藏**: 支持隐藏/显示 Dock 图标

## 系统要求

- macOS 12.0 (Monterey) 或更高版本
- Swift 6.2 或更高版本

## 项目结构

```
MacWallpaper/
├── Sources/
│   └── MacWallpaper/
│       ├── MacWallpaper.swift           # 应用入口
│       ├── AppDelegate.swift            # 应用代理
│       ├── WallpaperEngine.swift        # 壁纸引擎核心
│       ├── WallpaperWindow.swift        # 壁纸窗口和视频播放器
│       ├── StatusBarController.swift    # 状态栏控制器
│       ├── MainWindowController.swift   # 主窗口控制器
│       ├── MainViewController.swift     # 主视图控制器
│       ├── WallpaperManager.swift       # 壁纸管理器
│       ├── WallpaperCollectionViewItem.swift # 壁纸网格项
│       └── SettingsPanel.swift          # 设置面板
├── Resources/
│   └── Info.plist                       # 应用配置
├── Package.swift                        # Swift Package Manager 配置
└── README.md

```

## 构建和运行

### 使用 Swift Package Manager

```bash
cd MacWallpaper
swift build
swift run
```

### 使用 Xcode

1. 在 macOS 上打开项目目录
2. 运行以下命令生成 Xcode 项目:
   ```bash
   swift package generate-xcodeproj
   ```
3. 在 Xcode 中打开生成的 `.xcodeproj` 文件
4. 选择目标设备并点击运行

## 使用说明

### 添加壁纸

1. 点击工具栏的 **"添加壁纸"** 按钮
2. 选择一个或多个 MP4 格式的视频文件
3. 壁纸将自动添加到库中

### 应用壁纸

1. 在壁纸库中点击选择要应用的壁纸
2. 壁纸将立即应用到所有桌面

### 搜索壁纸

1. 点击工具栏的 **"搜索壁纸"** 按钮
2. 输入搜索关键词或壁纸网站地址
3. 应用将打开浏览器进行搜索

### 配置设置

1. 点击工具栏的 **"设置"** 按钮
2. 可以配置以下选项:
   - **静音播放**: 开启/关闭壁纸音频
   - **播放质量**: 选择低、中、高或原始质量

### 状态栏菜单

右键点击状态栏图标可以:
- 打开主窗口
- 切换静音
- 隐藏/显示 Dock 图标
- 查看关于信息
- 退出应用

## 技术架构

- **AppKit**: 用户界面框架
- **AVFoundation**: 视频播放和处理
- **NSStatusBar**: 状态栏集成
- **NSCollectionView**: 壁纸网格布局
- **UserDefaults**: 壁纸库持久化存储

## 核心组件

### WallpaperEngine
管理壁纸播放的核心引擎，负责:
- 创建和管理壁纸窗口
- 处理多屏幕支持
- 控制视频播放参数

### WallpaperWindow
专门的壁纸窗口，特点:
- 位于桌面窗口层级
- 支持所有 Spaces
- 全屏无边框显示
- 自动循环播放视频

### StatusBarController
状态栏集成，提供:
- 快速访问菜单
- 常用功能快捷操作
- 系统通知集成

## 许可证

请参阅 [LICENSE](LICENSE) 文件了解详情。

## 贡献

欢迎贡献！请随时提交问题或拉取请求。

## 作者

Horldsence
