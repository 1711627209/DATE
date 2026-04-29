---
title: "ai-events-calendar"
source: "QClaw"
type: "skill"
created_at: "2026-04-29T22:15:51"
updated_at: "2026-04-29T22:15:51"
tags: []
status: "待整理"
source_path: "C:\\Users\\Administrator\\.qclaw\\skills\\ai-events-calendar"
---

# ai-events-calendar

## SKILL.md

---
name: ai-events-calendar
description: |
  AI 活动日历 skill。每周一/四自动搜索深圳+线上 AI 活动，添加到飞书日历，
  并生成周报发送到 IMA 知识库 + 腾讯文档 + 微信。支持大厂、高校、自媒体等多渠道搜索。
---

# AI Events Calendar Skill

## ⚠️ 配置文件（最高优先级）

**所有 ID、凭证、路径必须从 `config.json` 读取，禁止硬编码。**

```javascript
const fs = require('fs');
const config = JSON.parse(fs.readFileSync(
  'C:\\Users\\Administrator\\.qclaw\\skills\\ai-events-calendar\\config.json',
  'utf8'
));
// 用法
const openId = config.feishu.openId;
const kbId = config.ima.knowledgeBaseId;
const folderId = config.ima.folderId;  // IMA 上传文件夹
```

**当前 config.json 中已固定的值：**
- `ima.folderId` = `7453847278602227`（深圳AI活动周报文件夹）
- `ima.knowledgeBaseId` = `sXBIYWZpqbHyIdTo8xFJdSZSNtVk7jawJzAMjq9b3dM=`
- `feishu.calendarId` = `6940971944640741377`
- `feishu.organizerCalendarId` = `feishu.cn_hWbRu42HY0bbpJDQ7aJtrf@group.calendar.feishu.cn`

## 核心数据源（按优先级）

1. **浏览器已登录平台** ← 直接站内搜索，登录态已保存
   - 活动行 (huodongxing.com) — ✅ 已登录
   - 互动吧 (hudongba.com) — ✅ 已登录（用户：孙超，城市：深圳）
   - 即刻 (okjike.cn) — ✅ 已登录
   - Meetup (meetup.com) — 无需登录，位置设为 Shenzhen, CN
   - 使用 xbrowser 有头模式 (`--headed true`) 操作这些平台
   - 每次搜索前用 `xb run open <URL>` 打开平台，用 `xb run snapshot` 查看内容

2. **微博** — 搜索"深圳AI活动/会议"话题，可找科技博主转发的活动
   - 用 xbrowser 访问 weibo.com 搜索
3. **微信文章** ← xb 有头模式直接读取，QClaw 是腾讯产品有天然优势
   - 打开文章：`xb run --browser cft open "<wechat_url>"`
   - 等加载：`xb run --browser cft wait --load networkidle`
   - 提取标题：`xb run --browser cft eval "document.title"`
   - 提取正文：`xb run --browser cft eval "document.getElementById('js_content').innerText"`
   - 提取公众号/来源：`xb run --browser cft eval "document.querySelector('#js_name')?.innerText || document.querySelector('.account_nickname')?.innerText"`
   - 提取时间：`xb run --browser cft eval "document.querySelector('#publish_time')?.innerText || document.querySelector('.rich_media_meta_text')?.innerText"`
   - 完整流程：先 init → open → wait networkidle → eval 逐个提取字段
   - 注意：xb 默认浏览器是 cft，必须用 `--browser cft`
3. **搜狗微信**（weixin.sogou.com）— 微信公众号文章搜索
4. **通用搜索** — 补充搜索深圳 AI 活动/会议
5. **手动补充** — 用户直接告诉我的活动

## 搜索策略（核心）

### 日期驱动搜索（优先级最高）

**搜索未来 7 天，每天一组日期关键词：**

```
今天 = 4月27日
关键词组 = [
  "4月27日 深圳AI活动",
  "4月28日 深圳AI活动",
  "4月29日 深圳AI活动",
  "4月30日 深圳AI活动",
  "5月1日 深圳AI活动",
  "5月2日 深圳AI活动",
  "5月3日 深圳AI活动"
]
```

### 主办方关键词（配合日期搜索）

每轮搜索叠加主办方关键词：

| 主办方 | 关键词 |
|--------|--------|
| 腾讯 | 腾讯AI活动 深圳腾讯开放日 AI Lab |
| 字节 | 字节AI活动 字节跳动火山引擎 |
| 高校 | 深圳大学AI 香港中文大学深圳 南方科技大学AI 清华深圳AI 哈工深AI 北大深圳AI |
| 华为 | 华为AI 华为云 深圳华为开发者 |
| 阿里 | 阿里云AI 深圳阿里创新中心 |
| 独角兽 | 深圳AI创业 深圳独角兽AI |

### 日期+主办方组合搜索

```
"4月27日 深圳AI活动 腾讯"
"4月28日 深圳AI活动 字节"
"4月29日 深圳AI活动 高校"
...
```

### 搜索执行顺序

1. **日期关键词搜索** — 7 天 × 1 次 = 7 次搜索
2. **日期+主办方组合** — 热门主办方 × 3 天 = 补充搜索
3. **主题关键词** — 当前月主题词 × 2 次

每次任务总搜索次数：10-15 次

### 活动筛选标准（必须严格执行）

**只收录以下类型：**
- AI/大模型/智能体/具身智能 技术会议、论坛、沙龙
- 自媒体+AI（AI写作、AI短视频、AI直播、AI获客、GEO优化）线下培训/沙龙
- 大厂技术开放日、开发者大会（含AI/技术方向）
- 高校AI学术讲座、实验室开放日
- AI创业/投资/行业对接活动
- AI产品发布会、展会中的AI专区

**一律排除（无论是否带"科技"字眼）：**
- 普通城市公园开园、亲子活动、科普体验
- 文旅节庆、国风/汉服/民俗活动（如锦绣中华、文博宫）
- 纯艺术/音乐/影视活动（无AI技术关联的）
- 电商促销、普通展会（无AI专题的）
- 仅在搜索结果中"顺带提到AI"但不以AI为核心的活动

**判断标准：** 问自己——「去掉AI元素后，这个活动还会不会存在？」如果会，就不该收录。

### 动态关键词库（每次任务前扩展）

**AI 技术关键词（持续扩展）：**
- OpenClaw / OpenAI / 开源模型
- Harness Engineering（驾驭工程）
- AIGC / AI应用 / 大模型 / 闭源模型
- 具身智能 / 机器人
- LangChain / RAG / Agent / Llama / Claude
- DeepSeek / 智谱 / 月之暗面 / Kimi

**自媒体+AI 关键词（丰富版）：**
- 自媒体AI运营 / AI自媒体变现 / AI内容创作
- AI短视频运营 / AI短视频变现 / AI视频号
- AI写作工具 / AI公众号运营 / AI爆款文
- AI数字人直播 / AI虚拟主播 / AI直播带货
- AI短剧制作 / AI漫剧 / AIGC内容
- 新媒体AI培训 / 自媒体AI沙龙 / AI获客沙龙
- 觉醒学院 / 蚁小二 / 抓词GEO
- GEO优化 / AI流量 / AI全域增长

**互联网大厂+AI（组合搜索，必做）：**
- 腾讯AI / 腾讯云AI / 腾讯开放日AI
- 字节AI / 字节跳动AI / 火山引擎AI
- 华为AI / 华为云AI / 华为开发者
- 阿里AI / 阿里云AI / 通义千问
- 百度AI / 文心一言
- 大厂AI活动 / 互联网大厂AI

**大厂技术沙龙（不加AI）：**
- 大厂技术沙龙 深圳
- 腾讯沙龙 字节沙龙 华为沙龙 阿里沙龙
- 互联网技术分享 深圳
- 大厂技术开放日
- AI写作工具
- AI视频生成

**政府/区级/街道来源（深圳AI活动富矿）：**
- 南山区科技创新局 / 南山科创局
- 福田区企业服务中心 / 福田企服中心
- 龙华区工信局 / 龙华工信局
- 宝安区科创局 / 宝安科创局
- 粤海街道 / 华强北街道 / 南山街道 / 福田街道
- 南山智园 / 天安云谷 / 深圳湾科技生态园
- 区级产业对接会 / 招商会 / 培训课

**校名校友关键词：**
- 清华深圳校友
- 北大深圳校友
- 哈工深校友
- 深大校友
- 南科大校友
- 港中深校友

**大厂内部平台（元宝搜不到，需人脉获取）：**
- 腾讯：Tapd、KM、内部论坛
- 字节：飞书文档、内部论坛
- 华为：内部开发者社区

### 活动范围标记

活动信息必须标注：
- **[深圳]** — 本地线下活动
- **[线上]** — 全国线上活动
- **[深圳+线上]** — 混合活动

### 已登录平台搜索命令

每次搜索时，按顺序打开各平台并搜索：

```bash
# 活动行 — 搜索AI活动
xb run open https://www.huodongxing.com/search?q=深圳AI活动

# 互动吧 — 搜索AI活动
xb run open https://www.hudongba.com/shenzhen/关键词

# 即刻 — 搜索AI话题活动
xb run open https://web.okjike.com/search?keyword=深圳AI活动

# Meetup — 搜索深圳AI活动（无需登录）
xb run open https://www.meetup.com/zh-CN/search/?keywords=AI&location=shenzhen
```

```bash
# 微博 — 搜索深圳AI活动（无需登录）
xb run open https://s.weibo.com
xb run type e31 "深圳 AI 活动"
xb run click e7
```

**xbrowser 命令格式（xb.cjs）：**
```bash
node "D:\Program Files\QClaw\resources\openclaw\config\skills\xbrowser\scripts\xb.cjs" run --browser default --headed true open <URL>
node "D:\Program Files\QClaw\resources\openclaw\config\skills\xbrowser\scripts\xb.cjs" run --browser default wait --load networkidle
node "D:\Program Files\QClaw\resources\openclaw\config\skills\xbrowser\scripts\xb.cjs" run --browser default snapshot -i
```

## 定时节奏

- **每周一 09:00** — 搜索本周+下周深圳 AI 活动
- **每周四 09:00** — 搜索本周+下周深圳 AI 活动（补充）

## 工作流程

### 步骤 1：搜索（核心）

#### 1.1 日期驱动搜索（7天）

计算未来 7 天日期，逐日搜索：

```javascript
const today = new Date();
for (let i = 0; i < 7; i++) {
  const date = new Date(today);
  date.setDate(date.getDate() + i);
  const dateStr = `${date.getMonth() + 1}月${date.getDate()}日`;
  
  // 搜索关键词
  const query = `${dateStr} 深圳AI活动`;
  // 使用 online-search 工具搜索
}
```

#### 1.2 主办方补充搜索

重点主办方：
- **腾讯**："深圳 腾讯AI活动" "腾讯开放日 深圳"
- **字节**："深圳 字节AI" "火山引擎 深圳"
- **高校**："深圳大学 AI讲座" "南科大 AI" "港中深 AI"
- **华为**："深圳 华为AI" "华为开发者 深圳"

#### 1.3 使用 online-search 工具

```javascript
// 示例调用
online-search.search({
  query: "4月27日 深圳AI活动",
  count: 10
});
```

提取信息：名称、时间、地点、费用、报名链接、来源

### 步骤 2：飞书日历

**必须从 config.json 读取 calendarId，禁止硬编码。**

使用 `@larksuite/cli`（官方飞书 CLI）：

```bash
lark-cli calendar +create \
  --summary "[AI活动] [免费] 深圳·具身智能 Meetup" \
  --start "2026-05-10T14:00:00+08:00" \
  --end "2026-05-10T17:00:00+08:00" \
  --description "来源: 深圳AI协会\n报名: https://..."
```

- 用户 OpenID：`config.feishu.openId`（在 config.json 中）
- 日历 ID：`config.feishu.calendarId`（在 config.json 中，**禁止硬编码**）

### 步骤 3：生成周报（内容要求 + 格式规范）

**⚠️ 核心格式：表格+详情 两段式（IMA上传 + 腾讯文档 共用同一份MD中间态文件）**

这份 MD 是 IMA 上传和腾讯文档创建的**唯一中间态文件**，一份 MD 两头用。

---

## 🔒 MD输出格式规范（锁定模板 - 不可修改）

**以下格式为标准模板，必须严格遵守，不得随意调整结构、字段顺序或内容格式。**

#### 格式结构（必须严格遵守）：

```markdown
# AI 活动周报 YYYY.MM.DD - YYYY.MM.DD

> 统计：本周 N 场 | 免费 N 场 | 付费 N 场 | 线上 N 场

---

## 📊 活动一览表

| # | 活动名称 | 日期 | 时间 | 地点 | 费用 | 类型 |
|---|---------|------|------|------|------|------|
| 1 | 深圳AI开发者大会 | 4/27 | 14:00-18:00 | 南山区科技园 | 免费 | 深圳 |
| 2 | 具身智能前沿论坛 | 4/29 | 09:00-17:00 | 福田会展中心 | ¥200 | 深圳 |
| 3 | AI自媒体变现线上课 | 5/1 | 20:00-21:30 | — | 免费 | 线上 |

---

## 📝 活动详情

### 1. 深圳AI开发者大会

**时间：** 2026年4月27日（周六）14:00 - 18:00
**地点：** 深圳市南山区科技园南区深圳湾科技生态园创新中心
**费用：** 免费
**主办方：** 深圳市人工智能行业协会
**报名：** https://example.com/register（无则写"待确认"）
**来源：** 微信搜索 / 活动行 / 微博
**标签：** #AI #开发者 #大模型 #深圳

**活动简介：**
（完整活动介绍，2-5句话概括活动主题、嘉宾、亮点。必须从搜索结果中提取真实信息，不能编造。如果搜索结果中没有详细介绍，写"暂无详细简介，请通过报名链接查看完整信息"。）

**议程/亮点：**
- 嘉宾A：主题演讲《xxx》
- 圆桌：xxx
- （如有议程信息则列出，无则省略此段）

---

### 2. 具身智能前沿论坛

（同上格式，每个活动都必须有完整信息）

---

## 下周活动预告

（如有下周已确认活动，按同样格式列出）

---

*报告生成时间：YYYY-MM-DD HH:MM | 数据来源：微信搜索 / 活动行 / 互动吧 / 即刻 / Meetup / 微博 / 通用搜索*
```

#### 内容规则（必须严格执行）：

1. **一览表目的**：让读者3秒内扫完所有活动（一目了然）
2. **详情部分目的**：每个活动的完整信息，和腾讯文档内容一致
3. **不得省略任何字段**：时间、地点、费用、主办方、报名链接、来源、简介——全部必填
4. **不能用"等"代替**：必须写出完整信息
5. **简介必须真实**：从搜索结果提取，不能编造；没有就写"暂无详细简介"
6. **标签**：每个活动加3-5个标签方便检索

---

## 🔒 格式锁定声明

**本模板已于 2026-04-28 锁定，格式如下：**

1. **文档标题**：`# AI 活动周报 YYYY.MM.DD - YYYY.MM.DD`
2. **统计行**：`> 统计：本周 N 场 | 免费 N 场 | 付费 N 场 | 线上 N 场`
3. **分隔线**：`---`
4. **活动一览表**：表格格式，7列（# | 活动名称 | 日期 | 时间 | 地点 | 费用 | 类型）
5. **分隔线**：`---`
6. **活动详情**：每个活动独立章节，格式固定
   - 标题：`### N. 活动名称`
   - 字段：时间、地点、费用、主办方、报名、来源、标签（7个必填）
   - 活动简介：2-5句话
   - 议程/亮点：可选
7. **下周活动预告**：如有则按同样格式
8. **页脚**：生成时间 + 数据来源

**禁止行为：**
- ❌ 不得调整字段顺序
- ❌ 不得省略必填字段
- ❌ 不得修改表格列数和列名
- ❌ 不得改变章节结构（一览表→详情）
- ❌ 不得用其他格式替代Markdown表格

**如需调整格式，必须征得用户同意。**

### 步骤 4：上传到 IMA

**必须从 config.json 读取 `knowledgeBaseId`、`folderId`、`clientId`、`apiKey`。**

使用 IMA Wiki OpenAPI，三步流程：

```javascript
// 读取配置
const config = JSON.parse(fs.readFileSync(
  'C:\\Users\\Administrator\\.qclaw\\skills\\ai-events-calendar\\config.json',
  'utf8'
));
const kbId = config.ima.knowledgeBaseId;       // sXBIYWZpqbHyIdTo8xFJdSZSNtVk7jawJzAMjq9b3dM=
const folderId = config.ima.folderId;          // 7453847278602227（深圳AI活动周报）
const clientId = config.ima.clientId;          // 1271aed7a1ae531590f224e0845ab115
const apiKey = config.ima.apiKey;              // D101yoyAPP5BgQFhLU60reUTxHGufKy6EKTzo0MqVAz//...
```

#### 4.1 create_media（获取上传凭证）

```bash
POST https://ima.qq.com/openapi/wiki/v1/create_media
Headers:
  Content-Type: application/json
  ima-openapi-clientid: {clientId}  # 从 config 读取
  ima-openapi-apikey: {apiKey}      # 从 config 读取

Body:
{
  "file_name": "ai-events-weekly-20260427.md",
  "file_size": 1383,
  "content_type": "text/markdown",
  "knowledge_base_id": "{kbId}",
  "file_ext": "md"
}

返回:
{
  "code": 0,
  "data": {
    "media_id": "markdown_xxx",
    "cos_credential": {
      "secret_id": "...",
      "secret_key": "...",
      "token": "...",
      "bucket_name": "ima-media-prod-1258344701",
      "region": "ap-shanghai",
      "cos_key": "2/xxx/file_manager/xxx.md"
    }
  }
}
```

#### 4.2 COS 上传（使用 Node.js SDK）

```javascript
const COS = require('cos-nodejs-sdk-v5');
const cos = new COS({
  SecretId: cos_credential.secret_id,    // 注意：从 cos_credential 内层读取
  SecretKey: cos_credential.secret_key,
  XCosSecurityToken: cos_credential.token
});

await cos.putObject({
  Bucket: cos_credential.bucket_name,
  Region: cos_credential.region,
  Key: cos_credential.cos_key,
  Body: fileBuffer,
  ContentLength: fileBuffer.length
});
```

#### 4.3 add_knowledge（完成上传）

```bash
POST https://ima.qq.com/openapi/wiki/v1/add_knowledge
Headers: 同上

Body:
{
  "media_type": 7,
  "media_id": "markdown_xxx",
  "title": "ai-events-weekly-20260427.md",
  "knowledge_base_id": "{kbId}",
  "file_info": {
    "cos_key": "2/xxx/file_manager/xxx.md",
    "file_size": 1383,
    "file_name": "ai-events-weekly-20260427.md"
  }
}
```

**关键注意事项：**
- Content-Type 只写 `application/json`，不能带 `charset=utf-8`
- `folder_id` 参数必须省略（省略则上传到知识库根目录，**不要传空字符串**）
- `folderId` 写进 `config.json`，上传时从配置读，不硬编码
- COS SDK 安装位置：`C:\tempcos\node_modules\cos-nodejs-sdk-v5`

#### 完整上传脚本

参考：`C:\Users\Administrator\.qclaw\workspace\_ima_full_upload.js`

### 步骤 5：创建腾讯文档（必须）

**⚠️ 必须执行，不能跳过。内容必须包含完整简介和报名链接，不得省略。**

#### 方式 A：mcporter（推荐）

```bash
mcporter call tencent-docs create_smartcanvas_by_mdx --args '<JSON>'
```

MDX 内容格式（用周报 markdown 转换）：
```javascript
const mdx = `# AI 活动周报

## 本周活动

### 活动名称
**时间：** ...  **地点：** ...  **费用：** ...
**主办方：** ...  **报名：** ...  **来源：** ...

...（每个活动必须有完整信息，不能省略）
`;
```

#### 方式 B：青云脚本（备选）

腾讯文档也有独立的 API，上传脚本参考：`C:\Users\Administrator\.qclaw\workspace\_tencent_docs_upload.js`

#### 完成后必须：
1. 拿文档 URL
2. 通过 `message` 工具用微信发链接给用户

---

### 步骤 6：去重规则（核心逻辑）

#### 6.1 飞书日历去重

**新建事件前必须检查：**

```bash
# 1. 先查询已有事件
lark-cli calendar +agenda --start "YYYY-MM-DD" --end "YYYY-MM-DD"
```

**去重判断条件（满足任一即为重复）：**
1. **名称完全匹配**（忽略大小写、空格、标点）
2. **名称模糊匹配 > 80%** 且 **日期相同**
3. **同日期 + 同地点 + 同主办方**

**示例：**
- ✅ 新增：「深圳AI开发者大会」vs 日历已有「深圳 AI 开发者大会」→ 重复，跳过
- ✅ 新增：「AI Night 沙龙」vs 日历已有「AI Night沙龙」→ 重复，跳过
- ❌ 新增：「具身智能论坛」vs 日历已有「AI开发者大会」→ 不重复，创建

#### 6.2 重复活动删除流程

**发现重复时的处理：**

```bash
# 1. 获取事件 ID
lark-cli calendar +agenda --summary "活动名称"

# 2. 删除重复事件（保留最早创建的）
lark-cli calendar delete --event-id "xxx"
```

**删除优先级：**
1. 保留来源最权威的（官网 > 公众号 > 第三方平台）
2. 保留信息最完整的（有报名链接 > 无链接）
3. 保留最早创建的

#### 6.3 周报去重

**生成周报时的去重逻辑：**

```javascript
const activities = [...]  // 搜索结果

// 去重函数
function dedupeActivities(activities) {
  const seen = new Map();
  
  for (const act of activities) {
    // 标准化 key：名称(小写去符号) + 日期
    const key = act.name.toLowerCase().replace(/[^a-z0-9\u4e00-\u9fa5]/g, '') + '|' + act.date;
    
    if (!seen.has(key)) {
      seen.set(key, act);
    } else {
      // 冲突处理：保留信息更完整的
      const existing = seen.get(key);
      if (act.link && !existing.link) {
        seen.set(key, act);  // 新的有链接，替换
      }
    }
  }
  
  return Array.from(seen.values());
}
```

#### 6.4 跨平台去重

**同一活动可能出现在多个平台，去重规则：**

| 平台优先级 | 来源权重 |
|-----------|----------|
| 官方公众号 | 10 |
| 活动行 | 8 |
| 互动吧 | 7 |
| 即刻 | 6 |
| Meetup | 5 |
| 微博 | 4 |
| 通用搜索 | 3 |

**处理逻辑：**
1. 同一活动在多平台出现 → 保留权重最高的来源
2. 合并信息：取各平台最完整的字段（时间/地点/链接）
3. 记录所有来源链接在「来源」字段

#### 6.5 已过期活动自动过滤

```javascript
// 自动过滤已过期活动
const today = new Date();
today.setHours(0, 0, 0, 0);

const validActivities = activities.filter(act => {
  const actDate = new Date(act.date);
  return actDate >= today;
});
```

---

## 输出检查清单

**每次执行后必须确认：**

- [ ] 微信摘要已发送
- [ ] IMA 上传成功（media_id 已记录）
- [ ] 腾讯文档已创建（URL 已获取）
- [ ] 飞书日历已同步（检查重复后新增）
- [ ] 文档链接已通过微信发送给用户
- [ ] 无重复活动（去重逻辑已执行）
- [ ] 无已过期活动（自动过滤已执行）

## 飞书日历集成

使用 `@larksuite/cli`（官方飞书 CLI）：

```bash
# 安装
npm install -g @larksuite/cli

# 授权（两步都需要）
lark-cli config init     # App 级别授权（应用权限）
lark-cli auth login --domain calendar  # 用户个人扫码登录
```

**创建日历事件：**
```bash
lark-cli calendar +create \
  --summary "[AI活动] [免费] 深圳·具身智能 Meetup" \
  --start "2026-05-10T14:00:00+08:00" \
  --end "2026-05-10T17:00:00+08:00" \
  --description "来源: 深圳AI协会\n报名: https://..."
```

**查看日历：**
```bash
lark-cli calendar +agenda  # 今天日程
```

## 关键配置

| 配置项 | 值 |
|--------|-----|
| **配置文件** | `C:\Users\Administrator\.qclaw\skills\ai-events-calendar\config.json` |
| **所有 ID 必须从配置文件读取，禁止硬编码** | — |
| IMA KB ID | sXBIYWZpqbHyIdTo8xFJdSZSNtVk7jawJzAMjq9b3dM= |
| IMA Folder ID | 7453847278602227（深圳AI活动周报） |
| 飞书日历 ID | 6940971944640741377 |
| 飞书组织日历 | feishu.cn_hWbRu42HY0bbpJDQ7aJtrf@group.calendar.feishu.cn |
| 日历标题格式 | [AI活动] [免费/付费¥金额/线上/深圳] {活动名称} |
| lark-cli config | C:\Users\Administrator\.lark-cli\openclaw\config.json |
| COS SDK 路径 | C:\tempcos\node_modules\cos-nodejs-sdk-v5 |

## 已实现状态

- [x] 安装 @larksuite/cli
- [x] App 级别授权（lark-cli config init）
- [x] 用户个人登录（lark-cli auth login）
- [x] 飞书日历读取（lark-cli calendar +agenda）
- [x] 飞书日历写入（lark-cli calendar +create）
- [x] IMA 上传流程（create_media → COS → add_knowledge）
- [x] 浏览器已登录平台（活动行、互动吧、即刻、Meetup）
- [x] config.json 配置文件（所有 ID 集中管理）
- [x] 腾讯文档创建（mcporter key=value 格式，已验证可用）
- [ ] 定时任务配置（qclaw-cron-skill）
- [ ] 完整端到端测试（站内搜索 → 提取活动 → 五步输出）


## config.json

```json
{
  "_comment": "AI 活动日历配置文件 — 所有 ID 均存储在此，禁止硬编码到脚本中",
  "feishu": {
    "openId": "ou_306a9dbc603752ff0b487c6f148391d6",
    "calendarId": "6940971944640741377",
    "organizerCalendarId": "feishu.cn_hWbRu42HY0bbpJDQ7aJtrf@group.calendar.feishu.cn",
    "larkCliConfig": "C:\\Users\\Administrator\\.lark-cli\\openclaw\\config.json"
  },
  "ima": {
    "knowledgeBaseId": "sXBIYWZpqbHyIdTo8xFJdSZSNtVk7jawJzAMjq9b3dM=",
    "folderId": "7453847278602227",
    "clientId": "1271aed7a1ae531590f224e0845ab115",
    "apiKey": "D101yoyAPP5BgQFhLU60reUTxHGufKy6EKTzo0MqVAz//BxUjXkXyoUYU4wVOxWLgTq83ZB8HA==",
    "cosSdkPath": "C:\\tempcos\\node_modules\\cos-nodejs-sdk-v5"
  },
  "tencentDocs": {
    "_note": "腾讯文档同步已验证可用 - 通过 Node.js 直接调 MCP HTTP API",
    "mcporterConfig": "C:\\Users\\Administrator\\.mcporter\\mcporter.json",
    "template": {
      "titlePrefix": "【AI活动周报】",
      "folderName": "AI活动",
      "folderId": ""
    }
  },
  "platforms": {
    "browserLoggedIn": [
      "活动行",
      "互动吧",
      "即刻",
      "Meetup"
    ],
    "noLoginRequired": [
      "微博",
      "Meetup"
    ]
  }
}
```
