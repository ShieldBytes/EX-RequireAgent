---
description: 开发团队反馈需求问题
argument-hint: <项目名> --issue "问题描述"
allowed-tools: ["Read", "Write"]
---

# 需求问题反馈

你需要记录开发团队对需求文档的反馈和问题。

## 执行步骤

### 1. 解析参数

从用户输入 `$ARGUMENTS` 中解析：
- **项目名**：第一个参数
- **--issue "问题描述"**：`--issue` 后引号中的内容

如果参数缺失，提示用户：
```
用法：/require-feedback <项目名> --issue "问题描述"
示例：/require-feedback 电商平台 --issue "退款流程缺少超时处理机制的描述"
```

### 2. 验证项目

检查 `docs/requirements/{项目名}/` 目录是否存在。
如果不存在，检查 `.require-agent/projects/{项目名}/` 是否存在。

如果都不存在：
```
未找到项目 {项目名}。可用项目：{列出所有项目}
```

### 3. 记录反馈

读取或创建 `docs/requirements/{项目名}/open-questions.md`。

追加反馈条目：
```markdown
### [{序号}] {当前日期}

**问题**：{问题描述}
**状态**：待处理
**来源**：开发团队反馈
```

### 4. 记录到进化日志

读取 `evolution/evolution-log.json`（如存在），追加一条反馈事件：
```json
{
  "type": "feedback",
  "project": "{项目名}",
  "issue": "{问题描述}",
  "timestamp": "{当前时间}"
}
```

### 5. 检查反馈累计

统计该项目 `open-questions.md` 中状态为"待处理"的反馈数量。

如果超过 5 条，额外提示：
```
⚠️ 该项目已有 {N} 条待处理反馈，建议重新启动优化：
   /require {项目名} --resume
```

### 6. 展示结果

```
📝 反馈已记录

项目：{项目名}
问题：{问题描述}
记录位置：docs/requirements/{项目名}/open-questions.md
待处理反馈总数：{N}
```
