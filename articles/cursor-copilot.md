# 第二篇示例：Cursor + Copilot 协作写作体验

> 发布于 2026-06-15 · 约 6 分钟阅读

## 起因

最近在写一个 Node.js CLI 工具，功能不复杂，但重复代码很多。让我开始思考：**Cursor 和 Copilot 在同一个项目里同时开着，到底是效率倍增还是注意力灾难？**

于是做了一个为期两周的实验。

## 实验设置

- **项目**：一个命令行 RSS 阅读器（TypeScript，约 800 行）
- **机器**：MacBook Pro M3，32GB
- **工具**：Cursor（always on）+ GitHub Copilot（VS Code 插件版）
- **评价维度**：代码质量、上下文切换成本、最终产物体积

## 工作流

第一周用 Cursor，第二周用 Copilot，第三周混合。对比维度：

1. 完成同样功能所需时间
2. 代码可读性（事后找他人 review）
3. 上下文切换频率（切出 IDE 的次数）

## Cursor 体验

Cursor 的核心优势是 **inline edit**。`⌘K` 唤起的修改框比 Copilot 的补全提示更直观——你可以直接看到哪些行会被改掉。

最常用的模式：

```
写一个函数 → ⌘K 选中 → 描述改动 → 回车
```

Copilot 的模式则更像是 **填空**：给你一整块代码让你接受或拒绝，但没有渐进式修改的感觉。

## Copilot 体验

Copilot 的强项在 **补全整块 boilerplate**。比如写一个 class：

```typescript
class FeedParser {
  // Copilot 会自动补全 constructor、parse、fetch 等方法签名
}
```

这在写测试文件时尤其明显。Cursor 的补全有时候会「想太多」，给你一整页测试代码，但我不一定想要那么多。

## 混合模式

第三周同时开着两个工具，发现一个问题：**两者的建议会相互干扰**。Copilot 的灰色提示和 Cursor 的蓝色框叠在一起，视觉上很乱。

解决方案：把 Copilot 关掉，只在 Cursor 里用 `⌘L` 唤起 Chat 模式查文档。Chat 的好处是可以上传整个文件让它分析，不只是当前光标位置。

## 数据对比

| 维度 | Cursor | Copilot |
|---|---|---|
| 完成 800 行代码耗时 | ~8h | ~11h |
| 事后 review 评分（1-10） | 7.5 | 6 |
| 上下文切换次数 | 约 120 次 | 约 210 次 |

## 结论

**Cursor 更适合中小型项目，尤其是需要频繁修改已有代码的场景。**

**Copilot 更适合写新的 boilerplate，尤其是测试文件和初始脚手架。**

两者结合的理想状态：用 Copilot 生成骨架，用 Cursor 精修。

## 工具链建议

如果你也在尝试 AI 结对编程，我的配置是：

- **Cursor** 作为主编辑器（always on）
- **Copilot Chat** 作为辅助查询（`⌘+Shift+P` 唤起）
- **不同时开启补全** — 两者补全同时出现只会分散注意力

---

*实验还在继续，下一篇会写 Ollama 本地跑 Code Llama 的体验。*
