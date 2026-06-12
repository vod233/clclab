---
title: 用 frontmatter 发布文章（模板示例）
date: 2026-06-18
excerpt: 演示如何在 Markdown 顶部用 YAML frontmatter 控制文章的元数据。
tags: [教程, 模板]
---

# 用 frontmatter 发布文章（模板示例）

> 这是一篇**模板文章**，可以删除。

把下面这一段删掉，把内容替换成你自己的就行：

## Frontmatter 字段说明

| 字段 | 必填 | 说明 |
|---|---|---|
| `title` | 否 | 留空时用第一个 H1 |
| `date` | 否 | 留空时用文件最后修改日期 |
| `excerpt` | 否 | 留空时自动从正文第一段提取 |
| `tags` | 否 | 数组格式 `[建站, AI]` 或逗号分隔 `建站, AI` |
| `updated` | 否 | 留空时与 `date` 相同 |

## 发布流程

1. 在 `articles/` 目录下新建 `your-slug.md`
2. 顶部加上 frontmatter（可选，但推荐）
3. 在 Trae 终端里跑：

```powershell
.\sync-articles.ps1 -Push
```

或者三步走（让 pre-commit 钩子自动同步）：

```bash
git add .
git commit -m "post: your article title"
git push
```

> 没有 frontmatter 也可以。脚本会自动从 H1 提取标题，从第一段提取 excerpt，从文件修改时间提取日期。
