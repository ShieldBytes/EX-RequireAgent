---
description: 导出需求文档为其他格式
argument-hint: md / json / csv
allowed-tools: ["Read", "Write", "Glob"]
---

# 导出需求文档

你需要将当前需求文档导出为用户指定的格式。

## 执行步骤

### 1. 解析参数

从用户输入 `$ARGUMENTS` 中解析目标格式：
- `md`：Markdown 格式（默认）
- `json`：结构化 JSON 格式
- `csv`：功能点列表 CSV 格式

如果参数缺失或不支持，提示用户：
```
用法：/require-export <格式>
支持格式：md / json / csv
示例：/require-export json
```

### 2. 定位项目和文档

扫描 `.require-agent/projects/` 目录，找到最近修改的项目。
读取项目的 `requirement-overview.md`（输出目录中的主文档）。

如果文档不存在，提示：
```
未找到需求文档。请确认项目已生成文档。
```

### 3. 按格式导出

#### md 格式
- 将 `requirement-overview.md` 复制一份到项目根目录下 `exports/` 目录
- 文件名：`{项目名}-requirements.md`

#### json 格式
- 解析 `requirement-overview.md` 内容
- 按章节结构化为 JSON，包含：
  - `project_name`：项目名称
  - `exported_at`：导出时间
  - `sections`：章节数组，每个章节包含 `title`、`content`、`sub_sections`
  - `features`：功能点列表，每个包含 `name`、`description`、`priority`、`acceptance_criteria`
- 写入 `exports/{项目名}-requirements.json`

#### csv 格式
- 从文档中提取功能点列表
- CSV 列：功能名称,功能描述,优先级,状态
- 写入 `exports/{项目名}-features.csv`
- 首行为表头

### 4. 展示结果

```
📤 导出完成

项目：{项目名}
格式：{格式}
文件：{导出文件路径}
大小：{文件大小}

提示：文件已保存到 exports/ 目录。
```
