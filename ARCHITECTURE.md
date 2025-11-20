# MacWallpaper 架构文档

## 概述

MacWallpaper 是一款使用 Swift 和 AppKit 框架开发的 macOS 动态壁纸应用。本文档详细说明了应用的架构设计和实现细节。

## 架构图

```
┌─────────────────────────────────────────────────────────────┐
│                     MacWallpaper.swift                       │
│                      (应用入口点)                             │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                     AppDelegate.swift                        │
│              (应用生命周期管理、协调中心)                      │
└──────┬──────────────┬──────────────┬──────────────┬─────────┘
       │              │              │              │
       ▼              ▼              ▼              ▼
┌─────────────┐ ┌──────────┐ ┌───────────┐ ┌──────────────┐
│WallpaperEngine│StatusBar│MainWindow │ Dock Icon   │
│             │ │Controller│ Controller│ Management  │
└──────┬──────┘ └─────────┘ └─────┬─────┘ └─────────────┘
       │                           │
       ▼                           ▼
┌──────────────┐         ┌───────────────────┐
│WallpaperWindow│        │MainViewController │
│ (每个屏幕)    │         │   (主UI控制)      │
└──────┬───────┘         └─────────┬─────────┘
       │                           │
       ▼                           ▼
┌──────────────┐         ┌───────────────────┐
│VideoPlayerView│        │  UI Components:   │
│ (AVFoundation)│        │  - Toolbar        │
└──────────────┘         │  - CollectionView │
                         │  - Settings Panel │
                         └───────────────────┘
```

## 核心组件

### 1. MacWallpaper.swift
**职责**: 应用入口点
- 创建 NSApplication 实例
- 设置 AppDelegate
- 启动应用运行循环

**关键代码**:
```swift
@main
class MacWallpaper {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
```

### 2. AppDelegate.swift
**职责**: 应用生命周期管理和组件协调
- 初始化核心组件
- 管理应用启动和终止
- 控制 Dock 图标显示/隐藏

**关键功能**:
- `applicationDidFinishLaunching`: 创建所有核心组件
- `applicationShouldTerminateAfterLastWindowClosed`: 返回 false，保持应用在后台运行
- `hideDockIcon/showDockIcon`: 切换 Dock 图标可见性

### 3. WallpaperEngine.swift
**职责**: 壁纸播放的核心引擎
- 管理所有屏幕的壁纸窗口
- 处理壁纸播放、停止、设置
- 响应屏幕配置变化

**核心属性**:
- `wallpaperWindows`: 壁纸窗口数组（每个屏幕一个）
- `currentWallpaper`: 当前正在播放的壁纸
- `isMuted`: 静音状态
- `quality`: 视频质量设置

**关键方法**:
- `playWallpaper(_:)`: 在所有屏幕上播放指定壁纸
- `stop()`: 停止播放
- `screenConfigurationChanged()`: 响应屏幕变化

**视频质量枚举**:
```swift
enum VideoQuality: String, CaseIterable {
    case low = "低"
    case medium = "中"
    case high = "高"
    case original = "原始"
}
```

### 4. WallpaperWindow.swift
**职责**: 壁纸显示窗口和视频播放
- 创建桌面级别的无边框窗口
- 嵌入视频播放器视图
- 管理视频循环播放

**窗口特性**:
- 窗口层级: `CGWindowLevelForKey(.desktopWindow)` - 位于桌面图标下方
- 集合行为: `.canJoinAllSpaces, .stationary` - 在所有 Space 中显示
- 无边框全屏显示

**VideoPlayerView 类**:
- 使用 AVFoundation 框架
- 使用 AVQueuePlayer 和 AVPlayerLooper 实现无缝循环
- 支持静音控制
- 自动生成视频缩略图

### 5. StatusBarController.swift
**职责**: 状态栏集成
- 创建和管理状态栏菜单
- 提供快捷操作入口
- 处理用户交互

**菜单项**:
- 打开主窗口
- 静音切换
- Dock 图标切换
- 关于
- 退出

**图标绘制**:
使用 NSBezierPath 绘制简单的自定义图标。

### 6. MainWindowController.swift
**职责**: 主窗口容器
- 创建和配置主窗口
- 托管 MainViewController
- 处理窗口关闭事件（不终止应用）

**窗口配置**:
- 初始大小: 900x600
- 最小大小: 700x500
- 样式: 标题栏、可关闭、可最小化、可调整大小

### 7. MainViewController.swift
**职责**: 主界面逻辑控制
- 管理工具栏
- 显示壁纸集合视图
- 处理用户交互（添加、搜索、选择壁纸）

**工具栏项**:
1. **添加壁纸**: 打开文件选择器，支持多选
2. **搜索壁纸**: 打开搜索对话框，支持 URL 或关键词搜索
3. **设置**: 显示设置面板

**集合视图**:
- 使用 NSCollectionViewFlowLayout
- 网格布局，每个项 200x180
- 显示视频缩略图和名称
- 支持单选

### 8. WallpaperManager.swift
**职责**: 壁纸库管理
- 持久化存储壁纸信息
- 添加/删除壁纸
- 从 UserDefaults 加载/保存

**数据模型**:
```swift
struct WallpaperItem: Codable, Identifiable {
    let id: UUID
    let name: String
    let url: URL
    let thumbnailPath: String?
    let dateAdded: Date
}
```

### 9. WallpaperCollectionViewItem.swift
**职责**: 壁纸集合视图单元格
- 显示壁纸缩略图
- 显示壁纸名称
- 处理选中状态

**UI 组件**:
- `thumbnailImageView`: 显示视频缩略图
- `nameLabel`: 显示壁纸名称
- `containerView`: 容器视图，处理选中边框

**缩略图生成**:
使用 AVAssetImageGenerator 从视频中提取帧作为缩略图。

### 10. SettingsPanel.swift
**职责**: 设置界面
- 静音开关
- 视频质量选择器
- 实时更新设置

**UI 布局**:
使用 NSStackView 垂直堆叠布局，包含:
- 标题标签
- 静音复选框
- 质量下拉菜单
- 提示信息

## 数据流

### 播放壁纸流程

```
用户选择壁纸
     │
     ▼
MainViewController.collectionView(didSelectItemsAt:)
     │
     ▼
WallpaperEngine.playWallpaper(_:)
     │
     ▼
遍历所有 WallpaperWindow
     │
     ▼
WallpaperWindow.loadVideo(url:muted:quality:)
     │
     ▼
VideoPlayerView.loadVideo(url:muted:)
     │
     ▼
创建 AVQueuePlayer + AVPlayerLooper
     │
     ▼
开始循环播放
```

### 添加壁纸流程

```
用户点击"添加壁纸"
     │
     ▼
MainViewController.addWallpaper()
     │
     ▼
显示 NSOpenPanel
     │
     ▼
用户选择 MP4 文件
     │
     ▼
WallpaperManager.addWallpaper(_:)
     │
     ▼
编码并保存到 UserDefaults
     │
     ▼
刷新 CollectionView
```

## 技术要点

### 1. 窗口层级管理
使用 `CGWindowLevelForKey(.desktopWindow)` 将壁纸窗口放置在桌面图标下方，确保不遮挡桌面交互。

### 2. 视频循环播放
使用 `AVPlayerLooper` 实现无缝循环，避免传统方式的播放间隙。

### 3. 多屏幕支持
- 监听 `NSApplication.didChangeScreenParametersNotification`
- 为每个 `NSScreen` 创建独立的 WallpaperWindow
- 屏幕配置变化时重新创建窗口

### 4. 状态栏集成
使用 `NSStatusBar.system.statusItem` 创建状态栏项，提供快速访问。

### 5. Dock 图标控制
通过 `NSApp.setActivationPolicy()` 在 `.regular` 和 `.accessory` 之间切换:
- `.regular`: 显示 Dock 图标
- `.accessory`: 隐藏 Dock 图标

### 6. 数据持久化
使用 UserDefaults 存储壁纸库，通过 Codable 协议实现 JSON 序列化。

## 性能优化

1. **异步缩略图生成**: 在后台线程生成缩略图，避免阻塞 UI
2. **视频质量选项**: 允许用户根据系统性能选择合适的播放质量
3. **资源管理**: 停止播放时清理 AVPlayer 资源

## 扩展性

### 可能的扩展方向

1. **支持更多视频格式**: MOV, AVI, WebM 等
2. **壁纸商店**: 内置壁纸下载和浏览功能
3. **定时切换**: 自动切换壁纸
4. **效果叠加**: 添加滤镜、调色等效果
5. **互动壁纸**: 响应鼠标/键盘事件
6. **性能监控**: 显示 CPU/内存使用情况
7. **iCloud 同步**: 跨设备同步壁纸库

## 依赖框架

- **AppKit**: macOS UI 框架
- **AVFoundation**: 音视频处理
- **Foundation**: 基础功能（数据结构、文件系统等）

## 最低系统要求

- macOS 12.0 (Monterey) 或更高
- Swift 6.2 或更高

## 许可证

请参阅项目根目录的 LICENSE 文件。
