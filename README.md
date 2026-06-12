# CLCLab

> AI × GitHub Learning Lab

一个用于学习 AI 工具、GitHub 工作流、项目实验和部署实践的个人静态网站。

在线访问：[clclab.xyz](https://clclab.xyz) · 源码：[github.com/vod233/clclab](https://github.com/vod233/clclab)

---

## 当前功能

- **顶部导航** — 固定、响应式、移动端汉堡菜单，滚动时自动高亮当前区块
- **Hero 首屏** — CLCLab 品牌展示 + 副标题 + 双 CTA
- **AI 工具导航** — 8 个常用 AI 工具，支持 4 类筛选（AI 对话 / AI 搜索 / AI 编程 / 本地模型）
- **GitHub 学习路线** — 7 步渐进式学习卡片，从 Git 基础到自动部署
- **项目实验区** — 5 个正在生长的项目，支持按状态筛选（计划中 / 进行中 / 已完成）
- **部署记录** — sticky 侧栏 + 纵向时间轴，状态用绿/橙/灰三色区分
- **返回顶部** — 滚动 600px 后浮现的圆角按钮，毛玻璃风格
- **滚动出现动画** — 基于 IntersectionObserver 的轻量 reveal 动画，遵守 `prefers-reduced-motion`
- **响应式布局** — 桌面、平板、手机三档适配，断点 1000 / 900 / 820 / 640

---

## 技术栈

| 类别 | 选型 |
| --- | --- |
| 标记 | HTML5（单文件） |
| 样式 | 原生 CSS — CSS 变量、Grid、Flexbox、媒体查询 |
| 行为 | 原生 JavaScript — ES6+，无框架、无构建工具 |
| 字体 | SF Pro 系统字体 + Instrument Serif（编辑感点缀）+ JetBrains Mono（数字 / 路径） |
| 设计语言 | Apple 编辑式极简 — 大留白、柔和渐变、细腻阴影、圆角卡片 |

> **不引入任何框架 / 构建工具 / npm 包**。单文件 HTML 直接部署到 Cloudflare Pages。

---

## 部署方式

通过 [Cloudflare Pages](https://pages.cloudflare.com) 部署，零构建。

### 首次部署

1. 在 Cloudflare 控制台 → Workers & Pages → Create application → Pages → Connect to Git
2. 选择 `vod233/clclab` 仓库
3. 构建设置：
   - Framework preset: **None**
   - Build command: *（留空）*
   - Build output directory: *（留空）*
4. 保存并部署，几十秒后 `clclab.pages.dev` 即可访问

### 后续更新

```bash
git add .
git commit -m "update"
git push
```

push 即部署，Cloudflare 自动检测并重新发布。

### 绑定自定义域名

1. Cloudflare Pages 项目 → Custom domains → 添加 `clclab.xyz`
2. 在域名 DNS 服务商添加 CNAME 记录指向 `clclab.pages.dev`
3. 等待 SSL 证书自动签发（约 1 分钟）

---

## 学习目标

CLCLab 本身就是一个学习产物，目标是用项目驱动的方式掌握：

- **AI 工具的实战使用** — 让 ChatGPT / Claude / Cursor / Copilot 成为日常工作的延伸
- **Git & GitHub 工作流** — 从 `git init` 到 Pull Request、Issue、Actions
- **前端基础** — HTML / CSS / JavaScript 核心概念、原生 DOM 操作
- **静态站点工程** — 单文件架构、CSS 变量系统、ARIA 无障碍实践
- **持续部署** — 用 GitHub Actions / Cloudflare Pages 跑通 push-to-deploy 流程
- **设计美学** — 参考 Apple 官网的产品级设计语言（typography、留白、阴影、动画）

---

## 项目结构

```
clclab/
├── index.html              # 主站入口
├── 404.html                # 自定义 404 页面
├── README.md               # 本文件
├── sync-articles.ps1       # 文章自动化脚本
├── install.ps1             # 一次性配置脚本
├── _headers                # Cloudflare Pages 缓存 / 安全头
├── .githooks/
│   └── pre-commit          # git 钩子，commit 时自动跑同步脚本
└── articles/
    ├── article-list.html   # 文章目录（从 registry.json 渲染）
    ├── article.html        # 文章阅读页（marked.js 实时渲染）
    ├── marked.min.js       # vendored marked.js
    ├── registry.json       # 文章元数据（脚本自动维护）
    ├── clclab-build.md
    ├── cursor-copilot.md
    └── frontmatter-template.md
```

---

## 发布新文章

### 一次性配置（只需一次）

```powershell
.\install.ps1
```

会自动配置 git 钩子，并同步一次 registry。

### 以后发布文章（3 步）

**方式 A：一键全自动（推荐）**

```powershell
# 1. 把 your-post.md 放进 articles/
# 2. 在终端跑：
.\sync-articles.ps1 -Push
```

脚本会自动：扫描新文件 → 解析 frontmatter → 更新 `registry.json` → `git add` → `git commit` → `git push`。Cloudflare Pages 30 秒后自动部署。

**方式 B：手动 git 流程（pre-commit 钩子自动同步）**

```bash
# 1. 把 your-post.md 放进 articles/
# 2. 正常走 git 流程：
git add .
git commit -m "post: 我的新文章"
git push
```

`pre-commit` 钩子会在 commit 前自动跑 `sync-articles.ps1` 更新 registry.json。

### Frontmatter 模板

在 `.md` 文件顶部加上（可选，但推荐）：

```yaml
---
title: 文章标题
date: 2026-06-20
excerpt: 一句话简介
tags: [建站, AI]
---
```

字段留空时脚本会回退到：第一行 H1 标题 / 第一段正文 / 文件修改时间。

### 仅预览不修改

```powershell
.\sync-articles.ps1 -DryRun
```

---

## 后续计划

- [ ] 接入 Cloudflare Web Analytics
- [ ] 暗色模式（`prefers-color-scheme: dark`）
- [ ] 项目卡可点击进入详情子站
- [ ] AI 工具支持搜索 / 收藏 / 标签
- [ ] 学习路线增加外部阅读资源链接
- [ ] 接入香港云服务器，提供 AI 后端 API（VPS AI Backend）
- [ ] RSS feed 订阅
- [ ] 键盘快捷键（⌘K 唤起搜索）

---

## 链接

- 在线访问：https://clclab.xyz
- 源码仓库：https://github.com/vod233/clclab
- 部署平台：https://pages.cloudflare.com

---

## 许可

© 2026 CLCLab · Personal learning project.

源码仅供学习参考，不承诺任何形式的稳定性或可用性保证。
