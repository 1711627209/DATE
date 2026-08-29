# Skills & Agent 知识资产库

> 本目录集中管理所有可复用的 Skill、Agent 配置和策略文档。
> 源文件同时备份在 `.agents/skills/`（Harness 运行目录）。

---

## 目录结构

```
skills/
├── README.md                    ← 本文件（总索引）
│
├── positioning-framework/       ← 主 Skill：心智规律 + 战略框架
│   └── SKILL.md
│
├── positioning-naming/          ← 子 Skill：品牌命名
│   └── SKILL.md
│
├── positioning-visual/          ← 子 Skill：视觉品牌
│   └── SKILL.md
│
├── positioning-strategy/        ← 子 Skill：战略决策
│   └── SKILL.md
│
└── positioning-marketing/       ← 子 Skill：传播执行
    └── SKILL.md
```

---

## 各 Skill 说明

### positioning-framework（主 Skill）
- **核心内容：** 李里斯战略定位理论完整框架
- **覆盖：** 心智七法则、二元法则、品类创新四步法、中小企业战略五步法
- **触发词：** 定位、心智规律、品类创新、差异化、品牌战略
- **来源：** 2026-08-29 林和西横路163号 李里斯咨询集团课程（7场）

### positioning-naming（命名专家）
- **核心内容：** 品牌命名五大技巧 + 检验标准 + 坏案例库
- **覆盖：** 动植物法/人名法/数字法/描述法/叠词法；60/80/90分检验标准
- **触发词：** 起名、命名、品牌名评估、名字好不好
- **来源：** 同上课程第7场

### positioning-visual（视觉专家）
- **核心内容：** 视觉锤十大来源 + 成功/失败案例
- **覆盖：** 瑞幸案例、中国品牌视觉机会、命名与视觉协同
- **触发词：** 视觉锤、logo设计、品牌视觉、包装设计
- **来源：** 同上课程第7场

### positioning-strategy（战略专家）
- **核心内容：** 品类选择三角 + 样板市场 + 定价策略 + 战略漂移诊断
- **覆盖：** 原点人群势能、滚雪球扩张、卖得更贵原则
- **触发词：** 战略、品类选择、样板市场、定价策略
- **来源：** 同上课程第1-5场

### positioning-marketing（传播专家）
- **核心内容：** 一道菜战略 + 营销一体性 + 渠道匹配 + AIPL归因
- **覆盖：** 费大厨案例、分众投放策略、天工报告解读
- **触发词：** 营销、传播策略、渠道选择、投放、AIPL
- **来源：** 同上课程第2-6场

---

## 调用方式

| 场景 | 输入 | 路由到 |
|------|------|--------|
| 品牌诊断 | "XX品牌有问题" | positioning-framework |
| 起名字 | "帮我给产品起名" | positioning-naming |
| 做视觉 | "设计一个视觉锤" | positioning-visual |
| 定战略 | "怎么选品类" | positioning-strategy |
| 做投放 | "品牌怎么打出去" | positioning-marketing |

---

## 数据来源

所有 Skill 内容提取自：
- **2026-08-29 广州林和西横路163号** 李里斯咨询集团战略定位课程（7场，约10小时）
- **2026-08-29 分众传媒投放策略分享**（第6场，38分钟）

原始逐字稿：`_workspace/minutes/obcnps*/transcript.txt`
原始洞察提取：`30-个人/系统洞察/`
归类聚合文件：`30-个人/系统洞察/归类/`

---

## 维护说明

- 本目录内容与 `.agents/skills/` 保持同步
- Skill 更新后，需同时更新两处
- 通过 git 双备份：GitHub + Gitee

---

## Git 远程

- **GitHub:** `git@github.com:1711627209/DATE.git`
- **Gitee:** 待配置
