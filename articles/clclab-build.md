# CLCLab 建站复盘

> 发布于 2026-06-13 · 约 8 分钟阅读

## 背景

CLCLab 从零到上线花了不到一天。写这篇文章的目的不是炫耀速度，而是把过程中做过的每一个决策记录下来，方便以后回看，也方便有类似需求的同学参考。

## 为什么是纯静态

一开始想过用 Next.js + Contentlayer，后来放弃了。原因是：

1. **学习曲线太陡** — Next.js App Router 的缓存策略、ISR、动态路由对我来说还是黑盒，调试 CI 问题会花很多时间
2. **发布流程太重** — 每写一篇文章要跑 build、等部署，门槛太高
3. **不必要** — CLCLab 本质上是一个内容入口，不是内容平台，不需要搜索、评论、访问统计（至少现在不需要）

所以最终选了 **纯 HTML + marked.js CDN** 方案：
- 文章写 Markdown
- 上传到 `articles/` 目录
- 页面用 JS 渲染，实时转换

## 技术选型

| 组件 | 选择 | 原因 |
|---|---|---|
| 渲染 | [marked.js](https://marked.js.org)（CDN） | 轻量、API 简洁、兼容性好 |
| 代码高亮 | highlight.js（CDN） | 支持主流语言、自动检测 |
| 图床 | Cloudflare R2 | 已在用 Cloudflare，零额外成本 |
| 部署 | Cloudflare Pages | push 即部署，边缘加速 |

## 目录结构

```
clclab/
├── index.html              # 首页
├── 404.html                # 404
├── articles/
│   ├── article-list.html   # 文章目录
│   ├── article.html        # 文章阅读页（模板）
│   ├── clclab-build.md     # 本文
│   └── example.md          # 第二篇示例
└── README.md
```

## 踩过的坑

### 1. marked.js 的 XSS 问题

marked.js 默认允许渲染原始 HTML，在用户生成内容里是安全隐患。但 CLCLab 的文章都是我写的，不存在这个问题，所以直接用了默认配置。如果以后开放投稿，需要切换到 `marked.use({ breaks: true })` 并禁用 `gfm: false`。

### 2. Cloudflare Pages 的 404 处理

Cloudflare Pages 默认把所有 404 都指向根目录的 `404.html`，这意味着 `articles/my-post.md` 这样的路径实际上不存在。

解决方案：**所有文章路径都通过 query 参数传递**，即 `article.html?slug=my-post`，而不是文件系统路径。这样 Cloudflare Pages 只需要处理两个路由：`/` 和 `/article.html`，404 只在这两个文件上生效。

### 3. marked.js 渲染时机

一开始把 marked.js 的调用放在 `<head>` 里，会导致文章内容闪一下（先看到 Markdown 原文，再变成渲染后的 HTML）。

后来把脚本移到 `</body>` 前，并在内容区加了一个简单的 loading 状态：

```html
<div id="content" class="loading">
  <div class="skeleton"></div>
</div>
```

CSS 加一个 skeleton shimmer 效果，阅读体验好很多。

## 下一步

- [ ] 给文章加阅读进度条（scroll-driven）
- [ ] 支持文章标签和分类筛选
- [ ] 添加站内搜索（Pagefind，不需要构建）
- [ ] 文章目录自动生成（TOC）

---

*如果你也在搭个人站点，欢迎参考 CLCLab 的架构。有问题可以在 GitHub 提 Issue。*
