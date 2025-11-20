# MacWallpaper 快速参考

## 快速开始

### 1. 构建应用
```bash
cd MacWallpaper
./build.sh
```

### 2. 运行应用
```bash
.build/release/MacWallpaper
```

### 3. 添加第一个壁纸
1. 点击工具栏 "➕ 添加壁纸"
2. 选择 MP4 文件
3. 点击壁纸缩略图应用

## 命令速查

### 构建命令
```bash
# 调试构建
swift build

# 发布构建
swift build -c release

# 清理构建
rm -rf .build

# 生成 Xcode 项目
swift package generate-xcodeproj
```

### Git 操作
```bash
# 克隆仓库
git clone https://github.com/Horldsence/MacWallpaper.git

# 更新代码
git pull origin main

# 查看状态
git status
```

## 快捷键

| 快捷键 | 功能 |
|--------|------|
| ⌘Q | 退出应用 |
| ⌘W | 关闭主窗口 |
| ⌘, | 打开设置（标准，未实现） |

## 文件路径

### 源代码
```
Sources/MacWallpaper/
├── MacWallpaper.swift           # 应用入口
├── AppDelegate.swift            # 应用代理
├── WallpaperEngine.swift        # 壁纸引擎
├── WallpaperWindow.swift        # 壁纸窗口
├── StatusBarController.swift    # 状态栏控制器
├── MainWindowController.swift   # 主窗口控制器
├── MainViewController.swift     # 主视图控制器
├── WallpaperManager.swift       # 壁纸管理器
├── WallpaperCollectionViewItem.swift # 集合视图项
└── SettingsPanel.swift          # 设置面板
```

### 配置文件
```
Package.swift                    # SPM 配置
Resources/Info.plist             # 应用配置
.gitignore                       # Git 忽略规则
build.sh                         # 构建脚本
```

### 文档
```
README.md                        # 项目说明
ARCHITECTURE.md                  # 架构文档
USER_GUIDE.md                    # 用户指南
CONTRIBUTING.md                  # 贡献指南
UI_OVERVIEW.md                   # UI 概览
FEATURES.md                      # 功能特性
QUICK_REFERENCE.md               # 本文件
```

## API 速查

### WallpaperEngine

```swift
// 播放壁纸
wallpaperEngine.playWallpaper(wallpaperItem)

// 停止播放
wallpaperEngine.stop()

// 设置静音
wallpaperEngine.isMuted = true

// 设置质量
wallpaperEngine.quality = .high
```

### WallpaperManager

```swift
// 加载壁纸库
wallpaperManager.loadWallpapers()

// 添加壁纸
wallpaperManager.addWallpaper(wallpaperItem)

// 删除壁纸
wallpaperManager.removeWallpaper(at: index)

// 获取壁纸列表
let wallpapers = wallpaperManager.wallpapers
```

### AppDelegate

```swift
// 隐藏 Dock 图标
appDelegate.hideDockIcon()

// 显示 Dock 图标
appDelegate.showDockIcon()
```

## 常见问题速查

| 问题 | 解决方案 |
|------|----------|
| 壁纸不播放 | 1. 检查文件格式是否为 MP4<br>2. 确认文件路径有效<br>3. 重启应用 |
| 性能问题 | 1. 降低播放质量<br>2. 使用较小的视频文件<br>3. 关闭其他应用 |
| 编译错误 | 1. 确认使用 macOS<br>2. 检查 Swift 版本<br>3. 清理构建目录 |
| 状态栏图标不显示 | 1. 检查系统设置<br>2. 重启应用<br>3. 查看控制台错误 |

## 调试技巧

### 查看日志
```swift
// 添加调试输出
print("Debug: \(variable)")

// 使用断言
assert(condition, "Error message")

// 错误处理
do {
    try somethingThatMightFail()
} catch {
    print("Error: \(error)")
}
```

### 控制台命令
```bash
# 查看应用日志
log stream --predicate 'processImagePath contains "MacWallpaper"'

# 查看崩溃日志
ls ~/Library/Logs/DiagnosticReports/MacWallpaper*
```

## 性能基准

### 推荐配置

| 项目 | 推荐值 |
|------|--------|
| 视频分辨率 | 1920x1080 或 2560x1440 |
| 视频时长 | 10-30 秒 |
| 文件大小 | 50-200 MB |
| 帧率 | 30 fps |
| 编码 | H.264 |
| 码率 | 5-10 Mbps |

### 性能影响

| 设置 | CPU 使用 | 内存使用 | 电池影响 |
|------|----------|----------|----------|
| 低质量 | ~5% | ~100 MB | 低 |
| 中质量 | ~10% | ~150 MB | 中 |
| 高质量 | ~15% | ~200 MB | 中高 |
| 原始质量 | ~20% | ~250 MB | 高 |

*数据为估计值，实际可能因系统和视频而异*

## 开发工作流

### 1. 修改代码
```bash
# 编辑源文件
vim Sources/MacWallpaper/SomeFile.swift
```

### 2. 测试构建
```bash
swift build
```

### 3. 运行测试
```bash
swift run
```

### 4. 提交更改
```bash
git add .
git commit -m "描述性提交信息"
git push
```

## 故障排除

### 编译问题

**错误**: `error: 'NSApplication' is unavailable`
```
原因: 不在 macOS 环境
解决: 在 macOS 上编译
```

**错误**: `error: could not find module 'AppKit'`
```
原因: 缺少 macOS SDK
解决: 安装 Xcode Command Line Tools
```

### 运行时问题

**问题**: 应用无法启动
```
检查:
1. 是否在 macOS 上运行
2. 系统版本是否 >= 12.0
3. 权限设置是否正确
```

**问题**: 视频无法播放
```
检查:
1. 文件是否存在
2. 格式是否支持
3. 文件是否损坏
```

## 项目统计

### 代码规模
```
文件数: 10 个 Swift 源文件
总行数: ~1500 行代码
注释率: ~20%
文档: 5 个 Markdown 文件
```

### 组件数量
```
类 (Class): 10
结构体 (Struct): 2
枚举 (Enum): 2
扩展 (Extension): 3
```

## 资源链接

### 官方文档
- [Swift.org](https://swift.org)
- [Apple Developer](https://developer.apple.com)
- [AppKit Documentation](https://developer.apple.com/documentation/appkit)
- [AVFoundation Guide](https://developer.apple.com/av-foundation/)

### 社区资源
- [Swift Forums](https://forums.swift.org)
- [Stack Overflow - Swift](https://stackoverflow.com/questions/tagged/swift)
- [r/swift](https://reddit.com/r/swift)

### 推荐壁纸网站
- [Pexels Videos](https://www.pexels.com/videos/)
- [Pixabay](https://pixabay.com/videos/)
- [Coverr](https://coverr.co)

## 版本信息

### 当前版本
```
版本: 1.0.0
发布日期: 2025
Swift: 6.2
最低 macOS: 12.0
```

### 变更历史
请查看 Git 提交历史或 CHANGELOG.md（如有）

## 许可证

本项目的许可证信息请参阅 [LICENSE](LICENSE) 文件。

---

**最后更新**: 2025年

**维护者**: Horldsence

**项目地址**: https://github.com/Horldsence/MacWallpaper
