# 个人工作流自动化系统 V1.1

这是《个人工作流自动化系统 V1.1》的最小可运行开发包，当前先落地 3 个确定能力：

1. AI 对话 JSON -> Markdown 转换
2. 工作碎片批量整理
3. 标准确认 / 执行结果文案生成

## 当前边界

- 不直接写入飞书、Obsidian、IMA
- 不绕过二次确认
- 不做无人值守全自动执行
- 涉及保存、删除、修改的动作，默认只生成结果与确认文案
- 第三方工具中的最终写入，当前阶段仍由用户手动完成

## 目录结构

- `docs/V1.1-开发规格.md`：开发规格与下一阶段计划
- `config/workflow.config.json`：V1.1 规则、提醒、分类与确认边界
- `scripts/convert-ai-chat.mjs`：AI 对话导出 JSON 转 Markdown
- `scripts/organize-work-fragments.mjs`：工作碎片整理脚本
- `scripts/render-workflow-message.mjs`：标准确认 / 结果文案生成器
- `samples/`：样例输入
- `samples/output/`：样例输出

## 快速开始

在当前目录执行：

```bash
npm run test:samples
```

如果你更想直接点窗口，用下面两种方式都可以：

- 双击 `E:\tongbu\OneDrive\文档\Obsidian Vault\20-领域\工作\个人工作流自动化系统\打开工作流窗口.vbs`
- 或在终端里执行：

```bash
npm run gui
```

单独运行脚本：

```bash
node scripts/render-workflow-message.mjs --mode confirm --details "将最近两周 AI 对话导出并转换为 Markdown"
node scripts/convert-ai-chat.mjs --input samples/ai-chat-sample.json --output samples/output/ai-chat-sample.md
node scripts/organize-work-fragments.mjs --input samples/work-fragments-sample.txt --output samples/output/work-fragments-sample.md
```

窗口自检：

```bash
npm run gui:selftest
```

## 当前实现范围

### 已实现

- 规则配置文件
- AI 对话导出转换器（支持常见 `messages` / `mapping` 结构与通用递归兜底）
- 工作碎片整理器（按待办、待确认、风险、想法、资料、备注分组）
- 标准确认文案与执行结果文案生成器
- 样例输入与样例输出
- Windows 图形界面入口（适合直接点按钮使用）

### 下一阶段建议

1. 接入真实的提醒调度
2. 接入 QCLAW 的输入落盘格式
3. 根据你第一次真实导出的 AI 平台 JSON 再调优转换规则
4. 补一层操作日志与月报生成
