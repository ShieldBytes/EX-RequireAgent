# 需求评估报告

## 评估概要
- **项目**：{project_name}
- **项目类型**：{project_type}
- **新需求**：{requirement_summary}
- **综合结论**：{verdict: [推荐实施] / [有条件实施] / [不建议实施]}
- **综合加权分**：{weighted_score}/10
- **评估时间**：{timestamp}

---

## 兼容度评分

| 维度 | 分数 | 权重 | 说明 |
|------|------|------|------|
| 业务契合度 | {business_fit}/10 | 25% | {business_fit_reason} |
| 架构兼容度 | {arch_compat}/10 | 25% | {arch_compat_reason} |
| 数据兼容度 | {data_compat}/10 | 20% | {data_compat_reason} |
| 依赖兼容度 | {dep_compat}/10 | 15% | {dep_compat_reason} |
| 实施复杂度 | {impl_complexity}/10 | 15% | {impl_complexity_reason} |

---

## 落地建议

### 推荐方案

{recommended_approach}

### 文件级改动清单

**需要修改（{modify_count} 个）：**
{modify_list}

**需要新增（{create_count} 个）：**
{create_list}

**可能受影响（{affect_count} 个）：**
{affect_list}

### 依赖变更

{dependency_changes}

---

## 风险分析

### 前置条件

{prerequisites}

### 技术风险

{tech_risks}

### 业务风险

{business_risks}

### git 热度分析

{git_heat_analysis}

---

## 实施优先级

{implementation_priority}
