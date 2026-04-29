---
title: "bilibili-note-qclaw"
source: "QClaw"
type: "skill"
created_at: "2026-04-29T22:15:51"
updated_at: "2026-04-29T22:15:51"
tags: []
status: "待整理"
source_path: "C:\\Users\\Administrator\\.qclaw\\skills\\bilibili-note-qclaw"
---

# bilibili-note-qclaw

## SKILL.md

name: bilibili-note-qclaw
description: QCLAW本地可调用的B站视频笔记自动化技能。输入BV号、b23短链或B站链接，提取标题/字幕/高赞评论，生成"原文概括、视频核心要点、高价值评论、我的理解"四模块Markdown，并按config.json配置上传IMA。
user-invocable: true
---
# B站视频笔记 QCLAW 本地技能

## 触发场景
当用户说"看这个B站视频并生成笔记""BVxxx做笔记""B站笔记上传IMA""bilibili-learning重构版"等需求时，使用本技能。

## 本地调用
优先使用 QCLAW 内置 Node：

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\Administrator\.qclaw\skills\bilibili-note-qclaw\bin\run_bilibili_note.ps1 "BV1t9oZBDENp"
```

也可以指定输出目录：

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\Administrator\.qclaw\skills\bilibili-note-qclaw\bin\run_bilibili_note.ps1 "https://www.bilibili.com/video/BV1t9oZBDENp" -OutDir "C:\Users\Administrator\.qclaw\workspace\bilibili-notes"
```

## 强制输出结构
笔记必须包含以下四个模块，顺序固定：
1. 原文概括：高度还原字幕/原文，AI只做润色和结构化。
2. 视频核心要点：结构化提炼重点、步骤、工具、结论和限制。
3. 高价值评论：整理高赞评论；获取失败时写明原因，不假造。
4. 我的理解：放在最后，只做补充思考。

## 配置规则
- 配置文件：`C:\Users\Administrator\.qclaw\skills\bilibili-note-qclaw\config.json`
- **凭证必须填写真实值，禁止任何占位符**
- 真实凭证值（已固化，禁止删除/替换）：
  - IMA Client ID：`1271aed7a1ae531590f224e0845ab115`
  - IMA API Key：`D101yoyAPP5BgQFhLU60reUTxHGufKy6EKTzo0MqVAz//BxUjXkXyoUYU4wVOxWLgTq83ZB8HA==`
  - IMA KB ID：`sXBIYWZpqbHyIdTo8xFJdSZSNtVk7jawJzAMjq9b3dM=`
  - B站笔记文件夹：`folder_7453863858694332`（「B站视频学习」文件夹）
- 所有 IMA KB ID、folder ID、media_type、重试次数都从 config.json 读取，禁止硬编码到脚本逻辑外。
- 如需引用，直接读取 config.json 的真实值，不要凭记忆填写。

## 腾讯文档同步（步骤 5，必须执行）

笔记生成并上传 IMA 后，**必须同步创建腾讯文档并发送链接给用户**。

### 方法：直接调 MCP HTTP API（Node.js）

```javascript
// 读取笔记 MDX 内容
const fs = require('fs');
const https = require('https');
const mdx = fs.readFileSync('笔记文件路径.md', 'utf8');

// 读取 mcporter 配置获取 endpoint 和 headers
const mcporterConfig = JSON.parse(
  fs.readFileSync('C:\\Users\\Administrator\\.mcporter\\mcporter.json', 'utf8')
);
const tdConfig = mcporterConfig.mcpServers['tencent-docs'];
const headers = tdConfig.headers || {};
headers['Content-Type'] = 'application/json';

const postData = JSON.stringify({
  jsonrpc: '2.0',
  method: 'tools/call',
  params: {
    name: 'create_smartcanvas_by_mdx',
    arguments: { title: '【B站笔记】视频标题', mdx: mdx }
  },
  id: 1
});
headers['Content-Length'] = Buffer.byteLength(postData);

const urlObj = new URL(tdConfig.baseUrl);
const req = https.request({
  hostname: urlObj.hostname,
  port: urlObj.port || 443,
  path: urlObj.pathname,
  method: 'POST',
  headers: headers
}, (res) => {
  let data = '';
  res.on('data', c => data += c);
  res.on('end', () => {
    const result = JSON.parse(data);
    console.log(result.result.structuredContent.url);
  });
});
req.write(postData);
req.end();
```

### 完成后必须：
1. 拿到文档 URL
2. 通过 `message` 工具用微信发链接给用户

### 注意事项：
- **不要用 mcporter CLI**（PowerShell 下无法传递复杂 MDX 内容）
- 直接读 `~/.mcporter/mcporter.json` 获取 endpoint + headers
- 腾讯文档固定文件夹待用户确认后配置到 config.json

## 错误处理
- B站信息、字幕、评论任何一步失败，都必须写入错误日志。
- 字幕为空时，不得臆造原文；应在"原文概括"保留失败说明。
- IMA凭证缺失时，生成本地Markdown并跳过上传，不假装成功。

## 新技能开发铁律
基于本技能开发新版本或迁移到其他平台时，**必须遵守**：
1. config.json 填写真实凭证值，禁止留任何占位符（`YOUR_KEY`、`xxx` 等）
2. 文件夹 ID 必须用 `folder_7453863858694332`（B站视频文件夹），不要用 `folder_7454057727813789`（那是「AI活动周报」文件夹）
3. 凭证从 `config.json` 读取，不要让用户重复填写
4. IMA 上传走 COS 三步流程（create_media → COS PUT → add_knowledge），不要直接 POST content


## config.json

```json
{
  "ima": {
    "api_base_url": "https://ima.qq.com",
    "client_id": "1271aed7a1ae531590f224e0845ab115",
    "api_key": "D101yoyAPP5BgQFhLU60reUTxHGufKy6EKTzo0MqVAz//BxUjXkXyoUYU4wVOxWLgTq83ZB8HA==",
    "kb_id": "sXBIYWZpqbHyIdTo8xFJdSZSNtVk7jawJzAMjq9b3dM=",
    "bilibili_folder_id": "folder_7453863858694332",
    "media_type_markdown": 7,
    "upload_retry_times": 3,
    "cos": {
      "bucket": "ima-media-prod-1258344701",
      "region": "ap-shanghai"
    }
  },
  "bilibili": {
    "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "timeout_seconds": 20,
    "include_hot_replies": true,
    "hot_reply_limit": 20,
    "prefer_official_subtitle": true
  },
  "note_template": {
    "required_sections": [
      "原文概括",
      "视频核心要点",
      "高价值评论",
      "我的理解"
    ],
    "principle": "原文优先/高度还原AI只做润色和结构化压缩不删减关键内容"
  },
  "tencentDocs": {
    "_note": "腾讯文档同步 - 待配置固定文件夹",
    "mcporterConfig": "C:\\Users\\Administrator\\.mcporter\\mcporter.json",
    "folderId": "",
    "titlePrefix": "【B站笔记】"
  },
  "coze": {
    "workflow_name": "B站笔记生成",
    "config_variable_name": "config_json"
  }
}
```
