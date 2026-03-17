---
description: 给需求文档版本打标签
argument-hint: <版本号> "标签描述"（如 v5 "客户演示版"）
allowed-tools: ["Read", "Write"]
---

# 版本标签管理

你需要为需求文档的某个版本打上标签，便于后续快速定位关键版本。

## 执行步骤

### 1. 解析参数

从用户输入 `$ARGUMENTS` 中解析：
- **版本号**：格式为 `v{数字}`，如 `v5`
- **标签描述**：引号中的文字，如 `"客户演示版"`

如果参数缺失或格式不正确，提示用户：
```
用法：/require-tag <版本号> "标签描述"
示例：/require-tag v5 "客户演示版"
```

### 2. 定位最近项目

读取 `.require-agent/projects/` 目录，找到最近修改的项目目录（按 `state.json` 的 `updated_at` 字段判断）。

如果 `.require-agent/projects/` 不存在或为空，提示：
```
未找到任何需求优化项目。请先使用 /require 启动一个项目。
```

### 3. 验证版本存在

检查 `.require-agent/projects/{项目名}/versions/v{N}.md` 是否存在。如果不存在，提示：
```
版本 v{N} 不存在。可用版本：{列出 versions/ 下所有 .md 文件}
```

### 4. 写入标签

读取 `.require-agent/projects/{项目名}/state.json`。

在 `state.json` 中追加或更新 `version_tags` 字段：

```json
{
  "version_tags": {
    "v{N}": {
      "label": "{标签描述}",
      "tagged_at": "{当前 ISO 时间戳}"
    }
  }
}
```

如果 `version_tags` 字段不存在，创建它。如果该版本已有标签，覆盖旧标签。

将更新后的 `state.json` 写回文件。

### 5. 展示结果

```
已标记 v{N} 为 "{标签描述}"

项目：{项目名}
版本：v{N}
标签：{标签描述}
时间：{当前时间}

当前所有标签：
{遍历 version_tags，逐行展示 "v{N} — {label}（{tagged_at}）"}
```
