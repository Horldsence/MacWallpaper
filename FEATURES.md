# MacWallpaper 功能特性详解

## 核心功能

### 🎬 动态壁纸播放

MacWallpaper 使用 AVFoundation 框架提供强大的视频播放能力：

#### 支持的功能
- **格式支持**: MP4（推荐 H.264 编码）
- **循环播放**: 使用 AVPlayerLooper 实现无缝循环
- **多屏幕**: 自动支持所有连接的显示器
- **自适应**: 视频自动适配屏幕分辨率和宽高比
- **性能优化**: 硬件加速解码

#### 技术实现
```swift
// 核心播放逻辑
let playerItem = AVPlayerItem(url: videoURL)
let queuePlayer = AVQueuePlayer(playerItem: playerItem)
playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
```

### 🖼️ 壁纸库管理

#### 添加壁纸
- **本地导入**: 支持从文件系统选择 MP4 文件
- **批量添加**: 一次可选择多个视频文件
- **自动缩略图**: 从视频中提取帧作为预览图

#### 壁纸存储
- **持久化**: 使用 UserDefaults 存储壁纸信息
- **数据模型**: Codable 协议实现 JSON 序列化
```swift
struct WallpaperItem: Codable, Identifiable {
    let id: UUID
    let name: String
    let url: URL
    let thumbnailPath: String?
    let dateAdded: Date
}
```

#### 壁纸展示
- **网格布局**: NSCollectionView 提供流畅的滚动体验
- **视觉反馈**: 选中状态带边框高亮
- **快速预览**: 悬停显示完整文件名

### ⚙️ 设置选项

#### 音频控制
- **全局静音**: 一键关闭所有壁纸音频
- **即时生效**: 设置立即应用到正在播放的壁纸
- **状态保存**: 静音状态在应用重启后保持

#### 视频质量
四档质量可选：
1. **低** (Low)
   - 降低渲染质量
   - 节省 CPU/GPU 资源
   - 延长电池续航
   - 适合老旧设备

2. **中** (Medium)
   - 平衡性能和质量
   - 适合日常使用
   - 推荐用于笔记本

3. **高** (High)
   - 高质量渲染
   - 推荐设置
   - 适合台式机

4. **原始** (Original)
   - 原始视频质量
   - 最佳视觉效果
   - 需要强劲性能

### 🔧 工具栏功能

#### 添加壁纸按钮
- **图标**: ➕ (Plus symbol)
- **快捷操作**: 直接打开文件选择器
- **多选支持**: 批量导入壁纸

#### 搜索壁纸按钮
- **图标**: 🔍 (Magnifying glass)
- **智能识别**: 
  - 输入 URL → 直接打开网页
  - 输入关键词 → Google 搜索 "关键词 wallpaper mp4"
- **便捷浏览**: 在浏览器中查找在线资源

#### 设置按钮
- **图标**: ⚙️ (Gear shape)
- **快速访问**: 打开设置面板
- **实时调整**: 无需重启应用

### 📍 状态栏集成

#### 状态栏图标
- **常驻显示**: 始终在状态栏右侧
- **系统风格**: 使用模板图像，自动适配浅色/深色模式
- **快速访问**: 点击展开菜单

#### 菜单选项
1. **打开主窗口**: 显示并激活主界面
2. **静音**: 切换音频开关，带状态指示（☑️/☐）
3. **Dock 图标**: 隐藏/显示 Dock 中的应用图标
4. **关于**: 显示应用信息
5. **退出**: 完全关闭应用（⌘Q）

### 🚫 Dock 栏控制

#### 隐藏 Dock 图标
```swift
NSApp.setActivationPolicy(.accessory)
```
- 应用仅在状态栏显示
- 不占用 Dock 空间
- 不参与 ⌘Tab 窗口切换
- 后台运行模式

#### 显示 Dock 图标
```swift
NSApp.setActivationPolicy(.regular)
```
- 正常应用模式
- Dock 中显示图标
- 参与窗口切换

**用例**:
- 隐藏：希望应用低调运行，不干扰工作区
- 显示：需要快速访问主窗口

### 🖥️ 多屏幕支持

#### 自动检测
- **屏幕枚举**: 自动识别所有连接的显示器
- **动态调整**: 响应屏幕连接/断开事件
```swift
NotificationCenter.default.addObserver(
    self,
    selector: #selector(screenConfigurationChanged),
    name: NSApplication.didChangeScreenParametersNotification,
    object: nil
)
```

#### 独立窗口
- 每个屏幕创建独立的壁纸窗口
- 自动匹配屏幕分辨率
- 支持不同宽高比
- 同步播放相同视频

#### 场景支持
- **桌面设备**: 多显示器工作站
- **笔记本**: 外接显示器热插拔
- **演示模式**: 投影仪/副屏

### 🎨 用户界面设计

#### 遵循 Apple HIG
- **AppKit 原生控件**: NSWindow, NSToolbar, NSCollectionView
- **系统图标**: SF Symbols（plus, magnifyingglass, gearshape）
- **标准布局**: 工具栏、集合视图、设置面板
- **macOS 风格**: 窗口阴影、圆角、过渡动画

#### 响应式设计
- **最小窗口**: 700x500 像素
- **可调整大小**: 自由拖动调整
- **自动布局**: 适配不同窗口大小
- **流式布局**: 壁纸网格自动排列

#### 视觉元素
- **缩略图**: 200x180 像素网格项
- **圆角**: 8px 圆角提升美感
- **边框**: 选中时显示 accent color 边框
- **间距**: 20px 间距保持视觉舒适

### 💾 数据持久化

#### UserDefaults 存储
```swift
// 保存壁纸库
if let data = try? JSONEncoder().encode(wallpapers) {
    userDefaults.set(data, forKey: wallpapersKey)
}

// 加载壁纸库
if let data = userDefaults.data(forKey: wallpapersKey),
   let savedWallpapers = try? JSONDecoder().decode([WallpaperItem].self, from: data) {
    wallpapers = savedWallpapers
}
```

#### 存储内容
- 壁纸文件路径（URL）
- 壁纸名称
- 添加日期
- 缩略图路径（可选）

#### 优点
- 无需数据库
- 系统原生支持
- 自动同步
- 轻量级存储

### 🔄 自动缩略图生成

#### AVAssetImageGenerator
```swift
let asset = AVAsset(url: videoURL)
let imageGenerator = AVAssetImageGenerator(asset: asset)
imageGenerator.appliesPreferredTrackTransform = true
imageGenerator.maximumSize = CGSize(width: 400, height: 300)

let time = CMTime(seconds: 1, preferredTimescale: 1)
let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
```

#### 特性
- **异步处理**: 后台线程生成，不阻塞 UI
- **智能提取**: 从视频 1 秒处提取帧
- **尺寸优化**: 限制最大尺寸节省内存
- **旋转处理**: 自动应用视频旋转变换

### 🎯 窗口层级管理

#### 桌面级别窗口
```swift
window.level = .init(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
```

#### 层级结构
1. **应用窗口层** (最上层)
   - 正常应用窗口
   - 响应用户交互

2. **桌面图标层**
   - 文件和文件夹图标
   - 可以点击和拖动

3. **壁纸窗口层** ← MacWallpaper 在这里
   - 视频播放窗口
   - 不响应鼠标事件
   - 位于图标下方

4. **系统壁纸层** (最下层)
   - 系统设置的静态壁纸

#### 窗口行为
```swift
window.collectionBehavior = [.canJoinAllSpaces, .stationary]
```
- `.canJoinAllSpaces`: 出现在所有虚拟桌面
- `.stationary`: 固定位置，不随窗口移动

### 🔔 系统通知

#### 应用通知
```swift
let notification = NSUserNotification()
notification.title = "壁纸已应用"
notification.informativeText = wallpaperName
NSUserNotificationCenter.default.deliver(notification)
```

#### 通知时机
- 成功应用壁纸后
- 提供视觉反馈
- 确认操作成功

## 性能优化

### 内存管理
- **及时释放**: 停止播放时清理 AVPlayer 资源
- **弱引用**: 使用 weak self 避免循环引用
- **自动释放池**: 缩略图生成使用 autoreleasepool

### CPU 优化
- **硬件加速**: AVPlayer 使用 VideoToolbox 硬解码
- **质量选项**: 允许用户降低质量节省 CPU
- **异步处理**: 缩略图生成在后台线程

### 电池续航
- **质量调整**: 低质量模式降低功耗
- **静音播放**: 减少音频处理开销
- **高效循环**: AVPlayerLooper 比手动循环更高效

## 兼容性

### 系统要求
- **最低版本**: macOS 12.0 (Monterey)
- **推荐版本**: macOS 13.0 (Ventura) 或更高
- **Swift 版本**: 6.2 或更高

### 硬件要求
- **CPU**: Intel 或 Apple Silicon
- **内存**: 4GB 以上（推荐 8GB）
- **GPU**: 支持硬件视频解码
- **存储**: 取决于壁纸文件大小

### 架构支持
- ✅ Apple Silicon (arm64)
- ✅ Intel (x86_64)
- ✅ Universal Binary

## 安全性

### 文件访问
- **沙盒兼容**: 遵守 macOS 沙盒规则
- **权限请求**: 通过 NSOpenPanel 访问文件
- **安全存储**: URL 使用 security-scoped bookmark（如需要）

### 隐私保护
- **无网络**: 除搜索功能外不连接网络
- **本地数据**: 所有数据存储在本地
- **无追踪**: 不收集用户数据

## 扩展性

### 插件系统（未来）
- 滤镜插件
- 效果插件
- 主题插件

### API 接口（未来）
- 命令行工具
- AppleScript 支持
- Shortcuts 集成

### 社区功能（未来）
- 壁纸分享
- 在线商店
- 社区评分

---

**注意**: 部分功能可能需要在实际 macOS 环境中测试和优化。
