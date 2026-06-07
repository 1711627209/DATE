# 开源 PM 市场调研工具清单

> 统计时间：2026-06-07  
> 说明：星标数来自 GitHub 当前公开页面或 GitHub API，后续会浮动。这里不是“全网所有项目”，而是按产品经理市场调研链路筛选出的高相关开源工具池。

## 一、结论

当前最适合你直接用的，不是单个“产品经理 skill”，而是一套组合工作流：

1. `GPT Researcher / Open Deep Research`：做行业资料初筛和带引用报告。
2. `Firecrawl / Crawl4AI / Playwright / Maxun`：抓官网、PDF、竞品资料和网页变化。
3. `Formbricks / LimeSurvey / Typebot`：做定性访谈、问卷、线索收集。
4. `PostHog / Umami / Matomo / GrowthBook`：做用户行为、产品数据、实验分析。
5. `n8n / Dify / Flowise / Activepieces`：把上面这些串成自动化流程。
6. `Metabase / Superset / Redash`：把调研数据做成可视化看板。

对你当前的 `车载/低速激光雷达竞品分析` 来说，最值得优先试的是：

- `GPT Researcher`
- `Open Deep Research`
- `Firecrawl`
- `Crawl4AI`
- `Formbricks`
- `n8n`
- `Metabase`

---

## 二、按 PM 调研链路分类

### A. 深度研究 / 市场报告生成

| 项目 | Stars | 用途 | 适合 PM 的点 | 适配度 |
|---|---:|---|---|---|
| [assafelovic/gpt-researcher](https://github.com/assafelovic/gpt-researcher) | 27.5k | 自动深度研究，生成带引用报告 | 行业调研、竞品初稿、资料综述 | 高 |
| [langchain-ai/open_deep_research](https://github.com/langchain-ai/open_deep_research) | 11.6k | 开源 deep research agent | 可配置搜索、模型、MCP，适合严肃研究 | 高 |
| [tarun7r/deep-research-agent](https://github.com/tarun7r/deep-research-agent) | 172 | 多 Agent 研究报告 | 小而轻，适合研究工作流学习 | 中 |
| [ai-agents-2030/awesome-deep-research-agent](https://github.com/ai-agents-2030/awesome-deep-research-agent) | 618 | Deep Research 项目索引 | 找更多研究 agent | 中 |
| [ItzCrazyKns/Perplexica](https://github.com/ItzCrazyKns/Perplexica) | 待复核 | 开源搜索问答 | 适合替代部分 Perplexity 场景 | 中 |

建议用途：

- 行业概览
- 竞品资料初筛
- 官方资料摘要
- 报告大纲生成
- 引用来源整理

限制：

- 不能直接相信结论。
- 必须人工复核官方网页、PDF、年报、产品 datasheet。

### B. 网页抓取 / 竞品资料采集

| 项目 | Stars | 用途 | 适合 PM 的点 | 适配度 |
|---|---:|---|---|---|
| [firecrawl/firecrawl](https://github.com/firecrawl/firecrawl) | 129.6k | 网页搜索、抓取、转 Markdown | 抓官网、产品页、新闻稿、PDF 入口 | 高 |
| [unclecode/crawl4ai](https://github.com/unclecode/crawl4ai) | 67.9k | LLM 友好网页爬虫 | 适合把网页变成可投喂 AI 的资料 | 高 |
| [ScrapeGraphAI/Scrapegraph-ai](https://github.com/ScrapeGraphAI/Scrapegraph-ai) | 26.8k | AI 驱动网页抽取 | 从网页抽结构化字段 | 中高 |
| [apify/crawlee](https://github.com/apify/crawlee) | 23.7k | Node.js 爬虫框架 | 批量抓网页、PDF、图片 | 中高 |
| [scrapy/scrapy](https://github.com/scrapy/scrapy) | 62.1k | Python 爬虫框架 | 稳定、工程化抓取 | 中 |
| [microsoft/playwright](https://github.com/microsoft/playwright) | 90.4k | 浏览器自动化 | 抓动态网页、下载 PDF、模拟浏览 | 高 |
| [browser-use/browser-use](https://github.com/browser-use/browser-use) | 97.5k | AI 控制浏览器 | 自动浏览竞品官网、表单、搜索页面 | 中高 |
| [getmaxun/maxun](https://github.com/getmaxun/maxun) | 15.8k | 无代码网页抓取 | PM 可低代码做网页采集 | 高 |
| [dgtlmoon/changedetection.io](https://github.com/dgtlmoon/changedetection.io) | 31.9k | 网页变化监控 | 监控竞品官网、价格、产品参数变化 | 高 |
| [RSSHub/RSSHub](https://github.com/RSSHub/RSSHub) | 待复核 | 把网站转 RSS | 订阅竞品新闻、招聘、公告 | 中高 |
| [RSSNext/Folo](https://github.com/RSSNext/Folo) | 38.4k | AI RSS 阅读器 | 信息源订阅与初筛 | 中 |
| [searxng/searxng](https://github.com/searxng/searxng) | 31.6k | 元搜索引擎 | 自建搜索入口，减少搜索平台依赖 | 中 |

建议用途：

- 竞品官网产品页抓取
- datasheet / PDF 入口发现
- 新闻稿和 IR 材料跟踪
- 网页变化监控

对激光雷达调研最有用：

- `changedetection.io` 监控竞品官网产品页
- `Firecrawl / Crawl4AI` 把产品页转成 Markdown
- `Playwright` 自动下载 PDF / datasheet

### C. 问卷 / 用户访谈 / 需求收集

| 项目 | Stars | 用途 | 适合 PM 的点 | 适配度 |
|---|---:|---|---|---|
| [formbricks/formbricks](https://github.com/formbricks/formbricks) | 12.4k | 开源问卷和体验管理 | 用户反馈、NPS、访谈问卷、站内调查 | 高 |
| [LimeSurvey/LimeSurvey](https://github.com/LimeSurvey/LimeSurvey) | 3.6k | 老牌开源问卷平台 | 复杂问卷、跳题、多语言、学术调研 | 中高 |
| [ohmyform/ohmyform](https://github.com/ohmyform/ohmyform) | 待复核 | 开源表单 | 简单收集访谈对象和需求 | 中 |
| [baptisteArno/typebot.io](https://github.com/baptisteArno/typebot.io) | 10k | 可自托管聊天机器人/表单 | 用对话形式做访谈和线索收集 | 高 |
| [EUSurvey/EUSURVEY](https://github.com/EUSurvey/EUSURVEY) | 待复核 | 欧盟问卷系统 | 严肃问卷/政企问卷参考 | 低中 |
| [logchimp/logchimp](https://github.com/logchimp/logchimp) | 待复核 | 用户反馈与路线图 | 收集需求、投票、反馈池 | 中 |

建议用途：

- 做车企产品负责人访谈表
- 建需求收集表
- 做问卷版本的作业2
- 访谈对象线索登记

对你当前最有价值：

- `Formbricks` 做正式问卷和反馈
- `Typebot` 做对话式访谈

### D. 产品数据分析 / 行为分析 / 实验

| 项目 | Stars | 用途 | 适合 PM 的点 | 适配度 |
|---|---:|---|---|---|
| [PostHog/posthog](https://github.com/posthog/posthog) | 34.9k | 产品分析、回放、实验、问卷、特性开关 | SaaS / 软件产品 PM 很强 | 高 |
| [umami-software/umami](https://github.com/umami-software/umami) | 37.1k | 网站与产品分析 | 轻量分析网站访问、用户来源 | 中高 |
| [matomo-org/matomo](https://github.com/matomo-org/matomo) | 21.6k | 开源 Google Analytics 替代 | 网站与用户行为分析 | 中 |
| [Countly/countly-server](https://github.com/Countly/countly-server) | 待复核 | 产品分析平台 | App / Web 行为分析 | 中 |
| [Openpanel-dev/openpanel](https://github.com/Openpanel-dev/openpanel) | 待复核 | 产品分析 | 轻量产品分析替代 | 中 |
| [GrowthBook/growthbook](https://github.com/GrowthBook/growthbook) | 7.9k | Feature flags、A/B test、产品分析 | 版本实验、功能灰度、效果评估 | 高 |
| [Flagsmith/flagsmith](https://github.com/Flagsmith/flagsmith) | 待复核 | Feature flags | 功能开关和灰度发布 | 中 |
| [Unleash/unleash](https://github.com/Unleash/unleash) | 待复核 | Feature flags | 功能发布控制 | 中 |

建议用途：

- 软件产品数据分析
- 产品版本效果评估
- 功能实验
- 用户行为洞察

对硬件 PM 的限制：

- 如果没有线上用户数据，这类工具价值有限。
- 但如果你做硬件配套 App / Web / 社群运营，它们很有用。

### E. BI / 调研数据可视化

| 项目 | Stars | 用途 | 适合 PM 的点 | 适配度 |
|---|---:|---|---|---|
| [apache/superset](https://github.com/apache/superset) | 73.2k | 数据可视化和探索 | 大数据看板、业务分析 | 中高 |
| [metabase/metabase](https://github.com/metabase/metabase) | 47.6k | 易用 BI / 数据看板 | PM 友好，适合做调研看板 | 高 |
| [getredash/redash](https://github.com/getredash/redash) | 28.6k | SQL 查询和看板 | 技术型 PM / 数据分析 | 中高 |
| [evidence-dev/evidence](https://github.com/evidence-dev/evidence) | 待复核 | Markdown + SQL 报告 | 把调研数据写成数据报告 | 中 |

建议用途：

- 竞品参数表可视化
- 调研问卷结果看板
- 用户反馈分类统计
- 市场数据趋势图

对你当前最推荐：

- `Metabase`：更适合 PM 上手。
- `Superset`：更偏数据团队。

### F. AI 工作流 / Agent 编排

| 项目 | Stars | 用途 | 适合 PM 的点 | 适配度 |
|---|---:|---|---|---|
| [n8n-io/n8n](https://github.com/n8n-io/n8n) | 191k | 工作流自动化，400+ 集成 | 自动抓资料、发提醒、整理到文档 | 高 |
| [langgenius/dify](https://github.com/langgenius/dify) | 144.2k | Agent / workflow 平台 | 做市场调研助手、RAG 知识库 | 高 |
| [FlowiseAI/Flowise](https://github.com/FlowiseAI/Flowise) | 53.4k | 可视化 AI Agent | 快速搭建研究流程 | 中高 |
| [activepieces/activepieces](https://github.com/activepieces/activepieces) | 22.6k | AI / MCP / 工作流自动化 | n8n 替代，可做自动任务 | 中高 |
| [huginn/huginn](https://github.com/huginn/huginn) | 待复核 | 事件监控和自动化 | 监控网页、RSS、触发任务 | 中 |
| [crewAIInc/crewAI](https://github.com/crewAIInc/crewAI) | 53k | 多 Agent 协作 | 做竞品研究 Agent 分工 | 中 |
| [microsoft/autogen](https://github.com/microsoft/autogen) | 58.7k | Agent 编程框架 | 多 Agent 研究框架 | 中 |
| [langchain-ai/langchain](https://github.com/langchain-ai/langchain) | 138.7k | Agent / LLM 应用框架 | 开发自定义调研流程 | 中 |
| [run-llama/llama_index](https://github.com/run-llama/llama_index) | 50k | 文档/RAG/知识库 | 把 PDF、网页、会议纪要做成知识库 | 高 |

建议用途：

- 自动市场情报日报
- 竞品网页变动监控
- PDF / datasheet 自动摘要
- 访谈记录入库
- 自动生成作业草稿

对你当前最推荐：

- `n8n`：串流程
- `Dify`：做调研助手
- `LlamaIndex`：处理本地文档和 PDF

### G. 金融 / 公司 / 行业数据源

| 项目 | Stars | 用途 | 适合 PM 的点 | 适配度 |
|---|---:|---|---|---|
| [OpenBB-finance/OpenBB](https://github.com/OpenBB-finance/OpenBB) | 68.7k | 金融数据平台 | 查上市公司、行业、财报、资本市场 | 中高 |
| [akfamily/akshare](https://github.com/akfamily/akshare) | 20.1k | 中文财经数据接口 | A 股、行业、宏观、公司数据 | 中高 |

建议用途：

- 查上市竞品财务数据
- 查行业公司资本市场表现
- 辅助商业化和融资案例分析

限制：

- 对激光雷达私企 / 非上市公司覆盖有限。
- 更适合补充市场和资本层信息。

---

## 三、优先级建议

### 第一梯队：现在就可以用

| 工具 | 为什么优先 |
|---|---|
| GPT Researcher | 可以直接生成行业调研初稿 |
| Open Deep Research | 更严肃，可配置，适合后续做固定工作流 |
| Firecrawl | 把官网、产品页、新闻稿抓成 Markdown |
| Crawl4AI | LLM 友好，适合和 AI 结合 |
| Formbricks | 能做访谈问卷和需求收集 |
| n8n | 串联自动化流程 |
| Metabase | 做调研结果看板 |

### 第二梯队：有数据后再用

| 工具 | 适合场景 |
|---|---|
| PostHog | 有软件/App 用户数据后 |
| GrowthBook | 要做功能实验后 |
| Umami / Matomo | 有网站或自媒体账号后 |
| Typebot | 想做对话式访谈后 |
| OpenBB / AKShare | 要做上市公司和行业资本分析后 |

### 第三梯队：技术改造型

| 工具 | 原因 |
|---|---|
| LangChain | 太底层，需要开发 |
| LlamaIndex | 强，但需要搭知识库 |
| CrewAI / AutoGen | 适合工程化多 Agent，不适合一上来就用 |
| Scrapy / Crawlee | 爬虫工程能力强，但需要维护 |

---

## 四、建议组合工作流

### 工作流 1：竞品资料自动采集

用途：车载/低速激光雷达竞品分析

1. `changedetection.io` 监控竞品官网产品页。
2. `Firecrawl / Crawl4AI` 把网页转 Markdown。
3. `GPT Researcher / Open Deep Research` 做摘要和对比。
4. `n8n` 定时运行。
5. 输出到 Obsidian。

适合你现在的作业3。

### 工作流 2：访谈对象与问卷收集

用途：作业2、车企产品负责人访谈

1. `Formbricks` 建访谈问卷。
2. `Typebot` 做对话式收集。
3. `n8n` 把结果同步到表格或 Markdown。
4. `GPT Researcher / LLM` 对回答做主题聚类。

适合后续真实访谈。

### 工作流 3：产品调研知识库

用途：长期 PM 转型资料沉淀

1. `Firecrawl / Playwright` 抓网页和 PDF。
2. `LlamaIndex / Dify` 建知识库。
3. `Open Deep Research` 基于知识库生成报告。
4. `Metabase` 做结构化表格和看板。

适合后续做作品集。

### 工作流 4：产品数据与实验

用途：如果你后面做自媒体、工具产品或硬件配套软件

1. `PostHog / Umami` 采集用户行为。
2. `Formbricks` 收集用户反馈。
3. `GrowthBook` 做功能实验。
4. `Metabase` 看指标变化。

适合产品化阶段。

---

## 五、针对你当前激光雷达作业的选择

如果目标是完成 `作业3：车载/低速激光雷达行业竞品分析`：

- 先用 `GPT Researcher / Open Deep Research` 做竞品资料初筛。
- 用 `Firecrawl / Crawl4AI` 抓竞品官网和产品页。
- 用 `Playwright` 处理需要点击下载的 PDF。
- 用 `changedetection.io` 监控竞品产品页变化。
- 用 `Metabase` 或 Markdown 表格做对比表。

如果目标是完成 `作业2：访谈提纲与需求洞察`：

- 用 `Formbricks` 做访谈问卷。
- 用 `Typebot` 做对话式访谈。
- 用 `n8n` 把结果汇总到本地 Markdown。
- 用 AI 做开放题聚类。

如果目标是长期构建 PM 作品集：

- 用 `Dify / LlamaIndex` 做自己的调研知识库。
- 用 `n8n` 定时抓行业新闻、竞品更新。
- 用 `GPT Researcher` 输出可发布的产品分析文章初稿。

---

## 六、我建议我们先落地的最小组合

先不要一次装很多。建议先做这个最小组合：

| 环节 | 工具 | 目标 |
|---|---|---|
| 搜集资料 | Firecrawl 或 Crawl4AI | 抓竞品官网和产品页 |
| 生成报告 | GPT Researcher | 生成带引用的行业/竞品初稿 |
| 问卷访谈 | Formbricks | 收集访谈对象和需求 |
| 自动化 | n8n | 定时跑任务、汇总结果 |
| 沉淀 | Obsidian | 存最终资料 |

这套组合能覆盖你当前最需要的 80% 工作。

---

## 七、待二次确认

后续如果要真正部署，需要进一步确认：

- 哪些工具能在 Windows 本机稳定跑。
- 哪些需要 Docker。
- 哪些需要 API Key。
- 哪些许可证不适合商用。
- 哪些能直接和 Obsidian / Markdown 流程打通。
- 哪些适合封装成 Codex skill。

---

## 八、豆包补充：PM 通用技能库与学习资源

这一组不是“市场调研工具”本身，而是更偏产品经理通用能力、AI PM skill 仓库、学习路线和方法论资源。它们对你有价值，但应和上面的调研工具分开看。

### A. 直接和 PM 工作流相关的 Skill 仓库

| 项目 | 来源 | 说明 | 与市场调研关系 | 建议 |
|---|---|---|---|---|
| [phuryn/pm-skills](https://github.com/phuryn/pm-skills) | 豆包 | AI PM skill 集合，偏工作流和方法论执行 | 高 | 值得重点看 |
| [deanpeters/Product-Manager-Skills](https://github.com/deanpeters/Product-Manager-Skills) | 豆包 + 已检索 | 面向 Claude Code、Codex 等的 PM 技能框架，当前 README 显示 `49 battle-tested skills + 6 command workflows` | 高 | 值得重点看 |
| [product-on-purpose/pm-skills](https://github.com/product-on-purpose/pm-skills) | 补充发现 | 更偏“可安装 skill 包”，最近更新活跃 | 高 | 值得补充看 |
| [neurofoo/agent-skills](https://github.com/neurofoo/agent-skills) | 豆包 | 通用 agent skills，其中包含用户研究、复盘等可迁移 skill | 中高 | 适合挑着看 |
| [menkesu/awesome-pm-skills](https://github.com/menkesu/awesome-pm-skills) | 豆包 | PM 资源索引型仓库 | 中 | 当导航站用 |
| [Digidai/product-manager-skills](https://github.com/Digidai/product-manager-skills) | 豆包 | PM 技能树/知识结构 | 中 | 适合查缺补漏 |

这些仓库里，真正对你现在有用的不是“学完全部内容”，而是找下面几类 skill：

- 用户研究
- 竞品分析
- PRD / MRD / BRD
- Roadmap / 优先级排序
- 产品战略
- 访谈总结 / 需求聚类
- 复盘 / pre-mortem / 风险判断

### B. 学习路线与知识图谱

| 项目 | 来源 | 说明 | 与当前任务关系 | 建议 |
|---|---|---|---|---|
| [roadmap.sh/product-manager](https://roadmap.sh/product-manager) | 豆包 | PM 学习路线图 | 中 | 用来补全知识结构 |
| [menkesu/awesome-pm-skills](https://github.com/menkesu/awesome-pm-skills) | 豆包 | 资源导航 | 中 | 作为索引，不直接落地 |
| [Digidai/product-manager-skills](https://github.com/Digidai/product-manager-skills) | 豆包 | 技能树 | 中 | 用于自查能力缺口 |

这类项目适合：

- 做长期转型规划
- 评估自己缺哪些能力
- 拆学习路径

不适合直接解决你当前的作业 2 / 作业 3。

### C. 作为基础补课的通用技能

| 方向 | 豆包给出的典型资源 | 判断 |
|---|---|---|
| Git / GitHub | `git/git`、`first-contributions/first-contributions` | 有用，但不属于调研工具 |
| SQL / 数据分析 | `sqlbolt/sqlbolt`、`ModeAnalytics/sql-tutorial` | 对 PM 很有用，尤其后期数据分析 |
| 前端原型 | `freeCodeCamp/freeCodeCamp`、`facebook/react`、`vuejs/vue` | 适合做原型和工具，但不是你当前优先级 |
| AI 基础 | `NirDiamant/RAG_Techniques`、`AutoGPT` | 对构建 AI 工作流有帮助 |
| 云与安全 | `OWASP/Top10`、`docker/awesome-compose` | 偏工程基础，非当前主线 |

这批资源不建议放进“市场调研工具”的第一梯队，但可以放进你的长期能力建设池。

---

## 九、把这些能力用到你身上

你的目标不是做一个“什么都会一点的 PM 学习者”，而是尽快形成一套能反复复用的调研工作流。按你当前状态，建议分三层使用。

### 第一层：立刻服务当前作业

用途：完成 `作业2`、`作业3`

- 用 `GPT Researcher / Open Deep Research` 生成行业调研和竞品初稿。
- 用 `Firecrawl / Crawl4AI / Playwright` 抓竞品官网、产品页、PDF。
- 用 `Formbricks` 做访谈问卷和线索收集。
- 用 `deanpeters/Product-Manager-Skills` 或 `phuryn/pm-skills` 里的方法论 skill，辅助做：
  - 用户研究提纲
  - 竞品分析框架
  - 需求优先级判断
  - PRD / Roadmap 结构

### 第二层：沉淀成你自己的作品集生产线

用途：不是只做这一次作业，而是持续输出产品分析

- 用 `n8n` 定时抓竞品官网变化。
- 用 `changedetection.io` 盯住重点产品页。
- 用 `Dify / LlamaIndex` 做你的行业知识库。
- 用 `Obsidian` 做最终沉淀。
- 用 `PM skill 仓库`中的框架，把每篇分析固定成同一种结构。

适合产出：

- 竞品分析文章
- 行业调研报告
- 项目案例拆解
- 面试作品集

### 第三层：补长期短板

用途：为后面做真正的产品经理工作做准备

- 学 `SQL`，因为后面做数据分析会用到。
- 学 `Git / GitHub`，因为你会越来越多接触开源 skill 和自动化项目。
- 学一点 `前端原型`，因为你以后会想快速做 demo。
- 学一点 `RAG / AI workflow`，因为你已经在用 AI 协作，后面一定会走到这一步。

---

## 十、我建议优先看的 6 个项目

如果只保留最值得你现在投入时间的 6 个：

1. [assafelovic/gpt-researcher](https://github.com/assafelovic/gpt-researcher)
2. [firecrawl/firecrawl](https://github.com/firecrawl/firecrawl)
3. [formbricks/formbricks](https://github.com/formbricks/formbricks)
4. [n8n-io/n8n](https://github.com/n8n-io/n8n)
5. [deanpeters/Product-Manager-Skills](https://github.com/deanpeters/Product-Manager-Skills)
6. [phuryn/pm-skills](https://github.com/phuryn/pm-skills)

这 6 个里面：

- 前 4 个偏“能直接干活”
- 后 2 个偏“把产品方法论变成 AI 可调用能力”

---

## 十一、下一步怎么做

最合理的下一步不是继续搜更多项目，而是开始做筛选实验。

建议顺序：

1. 先选 `1 个调研引擎`
   - `GPT Researcher` 或 `Open Deep Research`
2. 再选 `1 个网页采集工具`
   - `Firecrawl` 或 `Crawl4AI`
3. 再选 `1 个 PM skill 仓库`
   - `deanpeters/Product-Manager-Skills` 或 `phuryn/pm-skills`
4. 用这 3 类工具做一次真实任务：
   - 以 `车载/低速激光雷达竞品分析` 为例，跑一轮完整流程

这样能最快判断哪些东西你真的用得上，哪些只是“看起来很强”。
