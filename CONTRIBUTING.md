# 贡献指南

感谢你对 MacWallpaper 项目的关注！我们欢迎所有形式的贡献。

## 目录

1. [行为准则](#行为准则)
2. [如何贡献](#如何贡献)
3. [开发设置](#开发设置)
4. [编码规范](#编码规范)
5. [提交 Pull Request](#提交-pull-request)
6. [报告问题](#报告问题)
7. [功能请求](#功能请求)

## 行为准则

参与本项目的所有人都应该遵守以下准则：

- 尊重他人
- 接受建设性批评
- 关注对社区最有利的事情
- 对其他社区成员表现出同理心

## 如何贡献

有许多方式可以为 MacWallpaper 做出贡献：

### 报告 Bug

如果你发现了 bug：

1. 检查 [Issues](https://github.com/Horldsence/MacWallpaper/issues) 确保问题尚未报告
2. 创建新 issue，包含：
   - 清晰的标题
   - 详细的问题描述
   - 重现步骤
   - 预期行为 vs 实际行为
   - 截图（如适用）
   - 系统信息（macOS 版本、Swift 版本）

### 建议新功能

如果你有功能建议：

1. 检查是否已有类似的功能请求
2. 创建新 issue，使用 "Feature Request" 标签
3. 描述：
   - 功能的目的和用途
   - 预期的使用场景
   - 可能的实现方案（可选）

### 改进文档

文档改进同样重要：

- 修正拼写/语法错误
- 改进说明清晰度
- 添加使用示例
- 翻译成其他语言

### 贡献代码

我们欢迎代码贡献！请遵循以下流程。

## 开发设置

### 环境要求

- macOS 12.0 或更高
- Xcode 14.0 或更高（推荐最新版本）
- Swift 6.2 或更高
- Git

### 设置开发环境

1. Fork 仓库到你的 GitHub 账户

2. Clone 你的 fork：
   ```bash
   git clone https://github.com/YOUR_USERNAME/MacWallpaper.git
   cd MacWallpaper
   ```

3. 添加上游仓库：
   ```bash
   git remote add upstream https://github.com/Horldsence/MacWallpaper.git
   ```

4. 创建新分支：
   ```bash
   git checkout -b feature/your-feature-name
   ```

5. 构建项目：
   ```bash
   ./build.sh
   ```
   或使用 Xcode：
   ```bash
   swift package generate-xcodeproj
   open MacWallpaper.xcodeproj
   ```

## 编码规范

### Swift 代码风格

遵循 [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)：

```swift
// 好的示例
func loadWallpaper(from url: URL) throws {
    // 实现
}

class WallpaperEngine {
    private var wallpaperWindows: [WallpaperWindow] = []
    
    func playWallpaper(_ wallpaper: WallpaperItem) {
        // 实现
    }
}

// 避免
func LoadWallpaper(URL: URL) {  // 不要使用 Pascal Case
    // 实现
}
```

### 命名约定

- **类和结构体**：使用 PascalCase（`WallpaperEngine`, `VideoPlayerView`）
- **函数和变量**：使用 camelCase（`playWallpaper`, `isMuted`）
- **常量**：使用 camelCase 或 PascalCase（`wallpapersKey`, `VideoQuality`）
- **私有属性**：根据需要使用（`private var statusItem`）

### 代码组织

```swift
import Foundation  // 系统框架导入
import AppKit

// MARK: - 主类定义
class MyClass {
    // MARK: Properties
    private var privateProperty: String
    var publicProperty: Int
    
    // MARK: Initialization
    init() {
        // 实现
    }
    
    // MARK: Public Methods
    func publicMethod() {
        // 实现
    }
    
    // MARK: Private Methods
    private func privateMethod() {
        // 实现
    }
}

// MARK: - Extensions
extension MyClass: SomeProtocol {
    // 协议实现
}
```

### 注释

- 为公共 API 添加文档注释
- 复杂逻辑添加解释性注释
- 使用 `// MARK:` 组织代码段

```swift
/// 加载并播放指定的壁纸
/// - Parameter wallpaper: 要播放的壁纸项
/// - Throws: 如果视频文件无法访问则抛出错误
func playWallpaper(_ wallpaper: WallpaperItem) throws {
    // 实现
}
```

### 错误处理

使用 Swift 的错误处理机制：

```swift
enum WallpaperError: Error {
    case fileNotFound
    case invalidFormat
    case playbackFailed(Error)
}

func loadVideo(from url: URL) throws {
    guard FileManager.default.fileExists(atPath: url.path) else {
        throw WallpaperError.fileNotFound
    }
    // 继续处理
}
```

## 提交 Pull Request

### 提交前检查清单

- [ ] 代码遵循项目风格指南
- [ ] 添加了必要的注释和文档
- [ ] 代码可以成功构建
- [ ] 功能已在 macOS 上测试
- [ ] 没有引入新的警告或错误
- [ ] 提交信息清晰明了

### 提交信息规范

使用清晰的提交信息：

```
类型: 简短描述（不超过 50 字符）

更详细的说明（如需要）。
可以包含多行文字。

- 项目列表
- 关键变更

修复 #issue_number
```

**类型**：
- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `style`: 代码格式（不影响功能）
- `refactor`: 代码重构
- `perf`: 性能优化
- `test`: 添加测试
- `chore`: 构建过程或辅助工具的变动

**示例**：
```
feat: 添加视频质量选择器

- 添加 VideoQuality 枚举
- 在设置面板中添加下拉菜单
- 更新 WallpaperEngine 支持质量设置

修复 #42
```

### PR 流程

1. 确保你的分支是最新的：
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. 推送你的分支：
   ```bash
   git push origin feature/your-feature-name
   ```

3. 在 GitHub 上创建 Pull Request

4. 填写 PR 模板（如有）：
   - 描述变更内容
   - 关联相关 issue
   - 添加截图（UI 变更）
   - 列出测试步骤

5. 等待代码审查

6. 根据反馈进行修改

7. PR 被合并后，删除分支：
   ```bash
   git branch -d feature/your-feature-name
   git push origin --delete feature/your-feature-name
   ```

## 报告问题

### Bug 报告模板

```markdown
### 问题描述
简要描述遇到的问题

### 重现步骤
1. 打开应用
2. 点击 '...'
3. 滚动到 '...'
4. 看到错误

### 预期行为
描述你期望发生什么

### 实际行为
描述实际发生了什么

### 截图
如果适用，添加截图

### 环境信息
- macOS 版本: [例如 macOS 13.0]
- MacWallpaper 版本: [例如 1.0.0]
- Swift 版本: [例如 6.2]

### 附加信息
其他相关信息
```

## 功能请求

### 功能请求模板

```markdown
### 功能描述
清晰简洁地描述你想要的功能

### 问题描述
这个功能解决了什么问题？

### 建议的解决方案
描述你希望如何实现

### 替代方案
描述你考虑过的其他替代方案

### 附加信息
其他相关信息或截图
```

## 架构决策

重大变更或架构决策应该：

1. 先在 issue 中讨论
2. 考虑向后兼容性
3. 更新相关文档
4. 获得维护者批准

## 发布流程

（仅限维护者）

1. 更新版本号
2. 更新 CHANGELOG.md
3. 创建 git tag
4. 推送 tag 触发发布

## 代码审查

所有提交都需要经过代码审查：

- 至少一个维护者批准
- CI/CD 检查通过
- 没有合并冲突

审查者会检查：
- 代码质量和风格
- 功能正确性
- 性能影响
- 安全问题
- 文档完整性

## 许可证

通过贡献代码，你同意你的贡献将在与项目相同的许可证下发布。

## 问题？

如有任何问题，请：
- 创建 issue
- 在现有 issue 中评论
- 联系维护者

---

再次感谢你的贡献！🎉
