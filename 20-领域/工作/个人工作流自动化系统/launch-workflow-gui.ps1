param(
    [switch]$SelfTest
)

$ErrorActionPreference = 'Stop'

try {
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
} catch {
}

$script:ProjectRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$script:TempRoot = Join-Path $script:ProjectRoot '.tmp'
$script:NodePath = (Get-Command node -ErrorAction Stop).Source

$vaultRoot = Split-Path (Split-Path (Split-Path $script:ProjectRoot -Parent) -Parent) -Parent
$inboxPath = Join-Path $vaultRoot '00-收件箱'
if (Test-Path -LiteralPath $inboxPath) {
    $script:DefaultOutputRoot = $inboxPath
} else {
    $script:DefaultOutputRoot = [Environment]::GetFolderPath('Desktop')
}

New-Item -ItemType Directory -Force -Path $script:TempRoot | Out-Null

function Get-TimeStampTag {
    return (Get-Date).ToString('yyyy-MM-dd-HHmmss')
}

function New-Utf8BomFile {
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [string]$Content
    )

    $parent = Split-Path -Path $Path -Parent
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }

    $encoding = [System.Text.UTF8Encoding]::new($true)
    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

function Read-Utf8Text {
    param([Parameter(Mandatory)] [string]$Path)
    return [System.IO.File]::ReadAllText($Path)
}

function Get-DefaultMarkdownPath {
    param([Parameter(Mandatory)] [string]$Prefix)
    $safePrefix = $Prefix -replace '[\\/:*?"<>|]', '-'
    return (Join-Path $script:DefaultOutputRoot ("{0}-{1}.md" -f $safePrefix, (Get-TimeStampTag)))
}

function Invoke-NodeScript {
    param(
        [Parameter(Mandatory)] [string]$RelativeScript,
        [string[]]$Arguments = @()
    )

    $scriptPath = Join-Path $script:ProjectRoot $RelativeScript
    $output = & $script:NodePath $scriptPath @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    $text = ($output | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = $text.Trim()
    }
}

function Invoke-WorkflowSelfTest {
    $messages = New-Object System.Collections.Generic.List[string]
    $messages.Add("项目目录：$script:ProjectRoot")
    $messages.Add("Node：$script:NodePath")

    $aiOutput = Join-Path $script:ProjectRoot 'samples\output\ai-chat-sample.md'
    $fragmentOutput = Join-Path $script:ProjectRoot 'samples\output\work-fragments-sample.md'

    $aiResult = Invoke-NodeScript -RelativeScript 'scripts\convert-ai-chat.mjs' -Arguments @(
        '--input', (Join-Path $script:ProjectRoot 'samples\ai-chat-sample.json'),
        '--output', $aiOutput,
        '--title', 'AI 对话样例'
    )
    $messages.Add($aiResult.Output)
    if ($aiResult.ExitCode -ne 0) {
        return [pscustomobject]@{ Success = $false; Output = ($messages -join [Environment]::NewLine) }
    }

    $fragmentResult = Invoke-NodeScript -RelativeScript 'scripts\organize-work-fragments.mjs' -Arguments @(
        '--input', (Join-Path $script:ProjectRoot 'samples\work-fragments-sample.txt'),
        '--output', $fragmentOutput,
        '--title', '工作碎片样例'
    )
    $messages.Add($fragmentResult.Output)
    if ($fragmentResult.ExitCode -ne 0) {
        return [pscustomobject]@{ Success = $false; Output = ($messages -join [Environment]::NewLine) }
    }

    $messageResult = Invoke-NodeScript -RelativeScript 'scripts\render-workflow-message.mjs' -Arguments @(
        '--mode', 'result',
        '--task', '样例任务',
        '--details', '执行了样例验证',
        '--result', '3 个脚本可正常运行',
        '--confirm', '无'
    )
    $messages.Add($messageResult.Output)
    if ($messageResult.ExitCode -ne 0) {
        return [pscustomobject]@{ Success = $false; Output = ($messages -join [Environment]::NewLine) }
    }

    $messages.Add('自检完成：窗口依赖与脚本能力都可用。')
    return [pscustomobject]@{ Success = $true; Output = ($messages -join [Environment]::NewLine) }
}

if ($SelfTest) {
    $result = Invoke-WorkflowSelfTest
    Write-Output $result.Output
    if ($result.Success) {
        exit 0
    }
    exit 1
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$font = New-Object System.Drawing.Font('Microsoft YaHei UI', 10)
$titleFont = New-Object System.Drawing.Font('Microsoft YaHei UI', 11, [System.Drawing.FontStyle]::Bold)
$monoFont = New-Object System.Drawing.Font('Consolas', 10)

function Show-ErrorMessage {
    param([string]$Message, [string]$Title = '操作失败')
    [System.Windows.Forms.MessageBox]::Show($Message, $Title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
}

function Show-InfoMessage {
    param([string]$Message, [string]$Title = '提示')
    [System.Windows.Forms.MessageBox]::Show($Message, $Title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
}

function Set-ClipboardText {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) {
        Show-InfoMessage '当前没有可复制的内容。'
        return
    }
    [System.Windows.Forms.Clipboard]::SetText($Text)
    Show-InfoMessage '已复制到剪贴板。'
}

function Open-PathIfExists {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) {
        Show-InfoMessage '目标路径不存在。'
        return
    }
    Start-Process -FilePath $Path | Out-Null
}

function Select-OpenFile {
    param(
        [string]$Filter = '所有文件 (*.*)|*.*',
        [string]$Title = '选择文件'
    )

    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = $Filter
    $dialog.Title = $Title
    $dialog.Multiselect = $false
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.FileName
    }
    return $null
}

function Select-SaveFile {
    param(
        [string]$Filter = 'Markdown 文件 (*.md)|*.md|文本文件 (*.txt)|*.txt|所有文件 (*.*)|*.*',
        [string]$Title = '选择保存位置',
        [string]$InitialPath = ''
    )

    $dialog = New-Object System.Windows.Forms.SaveFileDialog
    $dialog.Filter = $Filter
    $dialog.Title = $Title
    if (-not [string]::IsNullOrWhiteSpace($InitialPath)) {
        $dialog.InitialDirectory = Split-Path -Path $InitialPath -Parent
        $dialog.FileName = Split-Path -Path $InitialPath -Leaf
    }
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.FileName
    }
    return $null
}

$form = New-Object System.Windows.Forms.Form
$form.Text = '个人工作流自动化系统 V1.1 - 轻量窗口'
$form.StartPosition = 'CenterScreen'
$form.Size = New-Object System.Drawing.Size(1120, 820)
$form.MinimumSize = New-Object System.Drawing.Size(1000, 720)
$form.Font = $font
$form.BackColor = [System.Drawing.Color]::WhiteSmoke

$tabs = New-Object System.Windows.Forms.TabControl
$tabs.Dock = 'Fill'
$tabs.Font = $font
$form.Controls.Add($tabs)

$homeTab = New-Object System.Windows.Forms.TabPage
$homeTab.Text = '开始使用'
$homeTab.BackColor = [System.Drawing.Color]::White
$tabs.TabPages.Add($homeTab)

$aiTab = New-Object System.Windows.Forms.TabPage
$aiTab.Text = 'AI对话转Markdown'
$aiTab.BackColor = [System.Drawing.Color]::White
$tabs.TabPages.Add($aiTab)

$fragmentTab = New-Object System.Windows.Forms.TabPage
$fragmentTab.Text = '工作碎片整理'
$fragmentTab.BackColor = [System.Drawing.Color]::White
$tabs.TabPages.Add($fragmentTab)

$messageTab = New-Object System.Windows.Forms.TabPage
$messageTab.Text = '标准文案'
$messageTab.BackColor = [System.Drawing.Color]::White
$tabs.TabPages.Add($messageTab)
$homeIntro = New-Object System.Windows.Forms.Label
$homeIntro.Location = New-Object System.Drawing.Point(20, 20)
$homeIntro.Size = New-Object System.Drawing.Size(1020, 120)
$homeIntro.Font = $titleFont
$homeIntro.Text = "这是给你做的傻瓜窗口版：`r`n1. AI 对话导出 JSON -> Markdown`r`n2. 工作碎片 -> 结构化整理稿`r`n3. 标准确认文案 / 执行结果文案`r`n`r`n注意：当前仍然不会直接改飞书、Obsidian、IMA，只会生成结果供你确认后手动保存。"
$homeTab.Controls.Add($homeIntro)

$openProjectButton = New-Object System.Windows.Forms.Button
$openProjectButton.Location = New-Object System.Drawing.Point(20, 160)
$openProjectButton.Size = New-Object System.Drawing.Size(140, 36)
$openProjectButton.Text = '打开项目目录'
$homeTab.Controls.Add($openProjectButton)

$openReadmeButton = New-Object System.Windows.Forms.Button
$openReadmeButton.Location = New-Object System.Drawing.Point(180, 160)
$openReadmeButton.Size = New-Object System.Drawing.Size(140, 36)
$openReadmeButton.Text = '打开使用说明'
$homeTab.Controls.Add($openReadmeButton)

$openInboxButton = New-Object System.Windows.Forms.Button
$openInboxButton.Location = New-Object System.Drawing.Point(340, 160)
$openInboxButton.Size = New-Object System.Drawing.Size(160, 36)
$openInboxButton.Text = '打开默认输出目录'
$homeTab.Controls.Add($openInboxButton)

$sampleTestButton = New-Object System.Windows.Forms.Button
$sampleTestButton.Location = New-Object System.Drawing.Point(520, 160)
$sampleTestButton.Size = New-Object System.Drawing.Size(160, 36)
$sampleTestButton.Text = '运行样例自测'
$homeTab.Controls.Add($sampleTestButton)

$homeLogTitle = New-Object System.Windows.Forms.Label
$homeLogTitle.Location = New-Object System.Drawing.Point(20, 220)
$homeLogTitle.Size = New-Object System.Drawing.Size(360, 28)
$homeLogTitle.Text = '运行日志 / 提示'
$homeTab.Controls.Add($homeLogTitle)

$homeLog = New-Object System.Windows.Forms.TextBox
$homeLog.Location = New-Object System.Drawing.Point(20, 250)
$homeLog.Size = New-Object System.Drawing.Size(1040, 470)
$homeLog.Multiline = $true
$homeLog.ScrollBars = 'Vertical'
$homeLog.ReadOnly = $true
$homeLog.Font = $monoFont
$homeLog.Anchor = 'Top,Bottom,Left,Right'
$homeLog.Text = "项目目录：$script:ProjectRoot`r`n默认输出目录：$script:DefaultOutputRoot"
$homeTab.Controls.Add($homeLog)

$aiIntro = New-Object System.Windows.Forms.Label
$aiIntro.Location = New-Object System.Drawing.Point(20, 20)
$aiIntro.Size = New-Object System.Drawing.Size(1020, 28)
$aiIntro.Text = '把 AI 平台导出的 JSON 文件转换为 Markdown，适合后续放进 Obsidian。'
$aiTab.Controls.Add($aiIntro)

$aiInputLabel = New-Object System.Windows.Forms.Label
$aiInputLabel.Location = New-Object System.Drawing.Point(20, 60)
$aiInputLabel.Size = New-Object System.Drawing.Size(110, 28)
$aiInputLabel.Text = '输入 JSON'
$aiTab.Controls.Add($aiInputLabel)

$aiInputText = New-Object System.Windows.Forms.TextBox
$aiInputText.Location = New-Object System.Drawing.Point(140, 58)
$aiInputText.Size = New-Object System.Drawing.Size(760, 28)
$aiInputText.Anchor = 'Top,Left,Right'
$aiTab.Controls.Add($aiInputText)

$aiInputBrowse = New-Object System.Windows.Forms.Button
$aiInputBrowse.Location = New-Object System.Drawing.Point(915, 56)
$aiInputBrowse.Size = New-Object System.Drawing.Size(120, 32)
$aiInputBrowse.Text = '选择 JSON'
$aiInputBrowse.Anchor = 'Top,Right'
$aiTab.Controls.Add($aiInputBrowse)

$aiOutputLabel = New-Object System.Windows.Forms.Label
$aiOutputLabel.Location = New-Object System.Drawing.Point(20, 102)
$aiOutputLabel.Size = New-Object System.Drawing.Size(110, 28)
$aiOutputLabel.Text = '输出 Markdown'
$aiTab.Controls.Add($aiOutputLabel)

$aiOutputText = New-Object System.Windows.Forms.TextBox
$aiOutputText.Location = New-Object System.Drawing.Point(140, 100)
$aiOutputText.Size = New-Object System.Drawing.Size(760, 28)
$aiOutputText.Anchor = 'Top,Left,Right'
$aiOutputText.Text = Get-DefaultMarkdownPath 'AI对话归档'
$aiTab.Controls.Add($aiOutputText)

$aiOutputBrowse = New-Object System.Windows.Forms.Button
$aiOutputBrowse.Location = New-Object System.Drawing.Point(915, 98)
$aiOutputBrowse.Size = New-Object System.Drawing.Size(120, 32)
$aiOutputBrowse.Text = '选择保存位置'
$aiOutputBrowse.Anchor = 'Top,Right'
$aiTab.Controls.Add($aiOutputBrowse)

$aiTitleLabel = New-Object System.Windows.Forms.Label
$aiTitleLabel.Location = New-Object System.Drawing.Point(20, 144)
$aiTitleLabel.Size = New-Object System.Drawing.Size(110, 28)
$aiTitleLabel.Text = '标题'
$aiTab.Controls.Add($aiTitleLabel)

$aiTitleText = New-Object System.Windows.Forms.TextBox
$aiTitleText.Location = New-Object System.Drawing.Point(140, 142)
$aiTitleText.Size = New-Object System.Drawing.Size(760, 28)
$aiTitleText.Anchor = 'Top,Left,Right'
$aiTab.Controls.Add($aiTitleText)

$aiRunButton = New-Object System.Windows.Forms.Button
$aiRunButton.Location = New-Object System.Drawing.Point(140, 186)
$aiRunButton.Size = New-Object System.Drawing.Size(120, 36)
$aiRunButton.Text = '开始转换'
$aiTab.Controls.Add($aiRunButton)

$aiOpenOutputButton = New-Object System.Windows.Forms.Button
$aiOpenOutputButton.Location = New-Object System.Drawing.Point(276, 186)
$aiOpenOutputButton.Size = New-Object System.Drawing.Size(140, 36)
$aiOpenOutputButton.Text = '打开输出文件'
$aiTab.Controls.Add($aiOpenOutputButton)

$aiCopyButton = New-Object System.Windows.Forms.Button
$aiCopyButton.Location = New-Object System.Drawing.Point(432, 186)
$aiCopyButton.Size = New-Object System.Drawing.Size(140, 36)
$aiCopyButton.Text = '复制预览内容'
$aiTab.Controls.Add($aiCopyButton)

$aiStatus = New-Object System.Windows.Forms.Label
$aiStatus.Location = New-Object System.Drawing.Point(20, 236)
$aiStatus.Size = New-Object System.Drawing.Size(1020, 24)
$aiStatus.Text = '状态：等待转换。'
$aiStatus.Anchor = 'Top,Left,Right'
$aiTab.Controls.Add($aiStatus)

$aiPreview = New-Object System.Windows.Forms.TextBox
$aiPreview.Location = New-Object System.Drawing.Point(20, 270)
$aiPreview.Size = New-Object System.Drawing.Size(1040, 450)
$aiPreview.Multiline = $true
$aiPreview.ScrollBars = 'Both'
$aiPreview.ReadOnly = $true
$aiPreview.Font = $monoFont
$aiPreview.Anchor = 'Top,Bottom,Left,Right'
$aiTab.Controls.Add($aiPreview)
$fragmentIntro = New-Object System.Windows.Forms.Label
$fragmentIntro.Location = New-Object System.Drawing.Point(20, 20)
$fragmentIntro.Size = New-Object System.Drawing.Size(1020, 44)
$fragmentIntro.Text = '把零散待办、问题、灵感、资料整理成结构化 Markdown。`r`n你可以直接粘贴内容，也可以导入 txt/json 文件。'
$fragmentTab.Controls.Add($fragmentIntro)

$fragmentFileLabel = New-Object System.Windows.Forms.Label
$fragmentFileLabel.Location = New-Object System.Drawing.Point(20, 76)
$fragmentFileLabel.Size = New-Object System.Drawing.Size(110, 28)
$fragmentFileLabel.Text = '已有文件（可选）'
$fragmentTab.Controls.Add($fragmentFileLabel)

$fragmentFileText = New-Object System.Windows.Forms.TextBox
$fragmentFileText.Location = New-Object System.Drawing.Point(140, 74)
$fragmentFileText.Size = New-Object System.Drawing.Size(680, 28)
$fragmentFileText.Anchor = 'Top,Left,Right'
$fragmentTab.Controls.Add($fragmentFileText)

$fragmentFileBrowse = New-Object System.Windows.Forms.Button
$fragmentFileBrowse.Location = New-Object System.Drawing.Point(835, 72)
$fragmentFileBrowse.Size = New-Object System.Drawing.Size(100, 32)
$fragmentFileBrowse.Text = '导入文件'
$fragmentFileBrowse.Anchor = 'Top,Right'
$fragmentTab.Controls.Add($fragmentFileBrowse)

$fragmentFileClear = New-Object System.Windows.Forms.Button
$fragmentFileClear.Location = New-Object System.Drawing.Point(950, 72)
$fragmentFileClear.Size = New-Object System.Drawing.Size(85, 32)
$fragmentFileClear.Text = '清空文件'
$fragmentFileClear.Anchor = 'Top,Right'
$fragmentTab.Controls.Add($fragmentFileClear)

$fragmentOutputLabel = New-Object System.Windows.Forms.Label
$fragmentOutputLabel.Location = New-Object System.Drawing.Point(20, 118)
$fragmentOutputLabel.Size = New-Object System.Drawing.Size(110, 28)
$fragmentOutputLabel.Text = '输出 Markdown'
$fragmentTab.Controls.Add($fragmentOutputLabel)

$fragmentOutputText = New-Object System.Windows.Forms.TextBox
$fragmentOutputText.Location = New-Object System.Drawing.Point(140, 116)
$fragmentOutputText.Size = New-Object System.Drawing.Size(680, 28)
$fragmentOutputText.Anchor = 'Top,Left,Right'
$fragmentOutputText.Text = Get-DefaultMarkdownPath '工作碎片整理'
$fragmentTab.Controls.Add($fragmentOutputText)

$fragmentOutputBrowse = New-Object System.Windows.Forms.Button
$fragmentOutputBrowse.Location = New-Object System.Drawing.Point(835, 114)
$fragmentOutputBrowse.Size = New-Object System.Drawing.Size(200, 32)
$fragmentOutputBrowse.Text = '选择保存位置'
$fragmentOutputBrowse.Anchor = 'Top,Right'
$fragmentTab.Controls.Add($fragmentOutputBrowse)

$fragmentTitleLabel = New-Object System.Windows.Forms.Label
$fragmentTitleLabel.Location = New-Object System.Drawing.Point(20, 160)
$fragmentTitleLabel.Size = New-Object System.Drawing.Size(110, 28)
$fragmentTitleLabel.Text = '标题'
$fragmentTab.Controls.Add($fragmentTitleLabel)

$fragmentTitleText = New-Object System.Windows.Forms.TextBox
$fragmentTitleText.Location = New-Object System.Drawing.Point(140, 158)
$fragmentTitleText.Size = New-Object System.Drawing.Size(680, 28)
$fragmentTitleText.Anchor = 'Top,Left,Right'
$fragmentTitleText.Text = '工作碎片整理 ' + (Get-Date).ToString('yyyy-MM-dd')
$fragmentTab.Controls.Add($fragmentTitleText)

$fragmentInputLabel = New-Object System.Windows.Forms.Label
$fragmentInputLabel.Location = New-Object System.Drawing.Point(20, 202)
$fragmentInputLabel.Size = New-Object System.Drawing.Size(110, 28)
$fragmentInputLabel.Text = '直接粘贴内容'
$fragmentTab.Controls.Add($fragmentInputLabel)

$fragmentInputText = New-Object System.Windows.Forms.TextBox
$fragmentInputText.Location = New-Object System.Drawing.Point(140, 202)
$fragmentInputText.Size = New-Object System.Drawing.Size(895, 190)
$fragmentInputText.Multiline = $true
$fragmentInputText.ScrollBars = 'Vertical'
$fragmentInputText.Anchor = 'Top,Left,Right'
$fragmentTab.Controls.Add($fragmentInputText)

$fragmentRunButton = New-Object System.Windows.Forms.Button
$fragmentRunButton.Location = New-Object System.Drawing.Point(140, 408)
$fragmentRunButton.Size = New-Object System.Drawing.Size(120, 36)
$fragmentRunButton.Text = '开始整理'
$fragmentTab.Controls.Add($fragmentRunButton)

$fragmentOpenOutputButton = New-Object System.Windows.Forms.Button
$fragmentOpenOutputButton.Location = New-Object System.Drawing.Point(276, 408)
$fragmentOpenOutputButton.Size = New-Object System.Drawing.Size(140, 36)
$fragmentOpenOutputButton.Text = '打开输出文件'
$fragmentTab.Controls.Add($fragmentOpenOutputButton)

$fragmentCopyButton = New-Object System.Windows.Forms.Button
$fragmentCopyButton.Location = New-Object System.Drawing.Point(432, 408)
$fragmentCopyButton.Size = New-Object System.Drawing.Size(140, 36)
$fragmentCopyButton.Text = '复制预览内容'
$fragmentTab.Controls.Add($fragmentCopyButton)

$fragmentStatus = New-Object System.Windows.Forms.Label
$fragmentStatus.Location = New-Object System.Drawing.Point(20, 458)
$fragmentStatus.Size = New-Object System.Drawing.Size(1020, 24)
$fragmentStatus.Text = '状态：等待整理。'
$fragmentStatus.Anchor = 'Top,Left,Right'
$fragmentTab.Controls.Add($fragmentStatus)

$fragmentPreview = New-Object System.Windows.Forms.TextBox
$fragmentPreview.Location = New-Object System.Drawing.Point(20, 492)
$fragmentPreview.Size = New-Object System.Drawing.Size(1040, 228)
$fragmentPreview.Multiline = $true
$fragmentPreview.ScrollBars = 'Both'
$fragmentPreview.ReadOnly = $true
$fragmentPreview.Font = $monoFont
$fragmentPreview.Anchor = 'Top,Bottom,Left,Right'
$fragmentTab.Controls.Add($fragmentPreview)

$messageIntro = New-Object System.Windows.Forms.Label
$messageIntro.Location = New-Object System.Drawing.Point(20, 20)
$messageIntro.Size = New-Object System.Drawing.Size(1020, 28)
$messageIntro.Text = '生成标准二次确认文案和工作流执行结果文案，可直接复制发给 QCLAW 或自己留档。'
$messageTab.Controls.Add($messageIntro)

$confirmGroup = New-Object System.Windows.Forms.GroupBox
$confirmGroup.Location = New-Object System.Drawing.Point(20, 60)
$confirmGroup.Size = New-Object System.Drawing.Size(500, 280)
$confirmGroup.Text = '确认文案'
$messageTab.Controls.Add($confirmGroup)

$confirmDetailsLabel = New-Object System.Windows.Forms.Label
$confirmDetailsLabel.Location = New-Object System.Drawing.Point(16, 32)
$confirmDetailsLabel.Size = New-Object System.Drawing.Size(100, 24)
$confirmDetailsLabel.Text = '操作内容'
$confirmGroup.Controls.Add($confirmDetailsLabel)

$confirmDetailsText = New-Object System.Windows.Forms.TextBox
$confirmDetailsText.Location = New-Object System.Drawing.Point(16, 58)
$confirmDetailsText.Size = New-Object System.Drawing.Size(460, 92)
$confirmDetailsText.Multiline = $true
$confirmDetailsText.ScrollBars = 'Vertical'
$confirmGroup.Controls.Add($confirmDetailsText)

$confirmConsequenceLabel = New-Object System.Windows.Forms.Label
$confirmConsequenceLabel.Location = New-Object System.Drawing.Point(16, 164)
$confirmConsequenceLabel.Size = New-Object System.Drawing.Size(140, 24)
$confirmConsequenceLabel.Text = '可能影响（可选）'
$confirmGroup.Controls.Add($confirmConsequenceLabel)

$confirmConsequenceText = New-Object System.Windows.Forms.TextBox
$confirmConsequenceText.Location = New-Object System.Drawing.Point(16, 190)
$confirmConsequenceText.Size = New-Object System.Drawing.Size(460, 42)
$confirmConsequenceText.Multiline = $true
$confirmConsequenceText.ScrollBars = 'Vertical'
$confirmGroup.Controls.Add($confirmConsequenceText)

$confirmGenerateButton = New-Object System.Windows.Forms.Button
$confirmGenerateButton.Location = New-Object System.Drawing.Point(16, 242)
$confirmGenerateButton.Size = New-Object System.Drawing.Size(120, 30)
$confirmGenerateButton.Text = '生成确认文案'
$confirmGroup.Controls.Add($confirmGenerateButton)

$confirmCopyButton = New-Object System.Windows.Forms.Button
$confirmCopyButton.Location = New-Object System.Drawing.Point(152, 242)
$confirmCopyButton.Size = New-Object System.Drawing.Size(120, 30)
$confirmCopyButton.Text = '复制结果'
$confirmGroup.Controls.Add($confirmCopyButton)
$resultGroup = New-Object System.Windows.Forms.GroupBox
$resultGroup.Location = New-Object System.Drawing.Point(540, 60)
$resultGroup.Size = New-Object System.Drawing.Size(520, 280)
$resultGroup.Text = '执行结果文案'
$messageTab.Controls.Add($resultGroup)

$resultTaskLabel = New-Object System.Windows.Forms.Label
$resultTaskLabel.Location = New-Object System.Drawing.Point(16, 30)
$resultTaskLabel.Size = New-Object System.Drawing.Size(80, 24)
$resultTaskLabel.Text = '任务名'
$resultGroup.Controls.Add($resultTaskLabel)

$resultTaskText = New-Object System.Windows.Forms.TextBox
$resultTaskText.Location = New-Object System.Drawing.Point(100, 28)
$resultTaskText.Size = New-Object System.Drawing.Size(390, 28)
$resultGroup.Controls.Add($resultTaskText)

$resultDetailsLabel = New-Object System.Windows.Forms.Label
$resultDetailsLabel.Location = New-Object System.Drawing.Point(16, 70)
$resultDetailsLabel.Size = New-Object System.Drawing.Size(80, 24)
$resultDetailsLabel.Text = '处理内容'
$resultGroup.Controls.Add($resultDetailsLabel)

$resultDetailsText = New-Object System.Windows.Forms.TextBox
$resultDetailsText.Location = New-Object System.Drawing.Point(100, 68)
$resultDetailsText.Size = New-Object System.Drawing.Size(390, 68)
$resultDetailsText.Multiline = $true
$resultDetailsText.ScrollBars = 'Vertical'
$resultGroup.Controls.Add($resultDetailsText)

$resultResultLabel = New-Object System.Windows.Forms.Label
$resultResultLabel.Location = New-Object System.Drawing.Point(16, 148)
$resultResultLabel.Size = New-Object System.Drawing.Size(80, 24)
$resultResultLabel.Text = '结果'
$resultGroup.Controls.Add($resultResultLabel)

$resultResultText = New-Object System.Windows.Forms.TextBox
$resultResultText.Location = New-Object System.Drawing.Point(100, 146)
$resultResultText.Size = New-Object System.Drawing.Size(390, 58)
$resultResultText.Multiline = $true
$resultResultText.ScrollBars = 'Vertical'
$resultGroup.Controls.Add($resultResultText)

$resultConfirmLabel = New-Object System.Windows.Forms.Label
$resultConfirmLabel.Location = New-Object System.Drawing.Point(16, 216)
$resultConfirmLabel.Size = New-Object System.Drawing.Size(80, 24)
$resultConfirmLabel.Text = '确认项'
$resultGroup.Controls.Add($resultConfirmLabel)

$resultConfirmText = New-Object System.Windows.Forms.TextBox
$resultConfirmText.Location = New-Object System.Drawing.Point(100, 214)
$resultConfirmText.Size = New-Object System.Drawing.Size(390, 28)
$resultConfirmText.Text = '无'
$resultGroup.Controls.Add($resultConfirmText)

$resultGenerateButton = New-Object System.Windows.Forms.Button
$resultGenerateButton.Location = New-Object System.Drawing.Point(100, 246)
$resultGenerateButton.Size = New-Object System.Drawing.Size(120, 30)
$resultGenerateButton.Text = '生成结果文案'
$resultGroup.Controls.Add($resultGenerateButton)

$resultCopyButton = New-Object System.Windows.Forms.Button
$resultCopyButton.Location = New-Object System.Drawing.Point(236, 246)
$resultCopyButton.Size = New-Object System.Drawing.Size(120, 30)
$resultCopyButton.Text = '复制结果'
$resultGroup.Controls.Add($resultCopyButton)

$messageOutputLabel = New-Object System.Windows.Forms.Label
$messageOutputLabel.Location = New-Object System.Drawing.Point(20, 358)
$messageOutputLabel.Size = New-Object System.Drawing.Size(120, 24)
$messageOutputLabel.Text = '生成结果'
$messageTab.Controls.Add($messageOutputLabel)

$messageSaveButton = New-Object System.Windows.Forms.Button
$messageSaveButton.Location = New-Object System.Drawing.Point(150, 352)
$messageSaveButton.Size = New-Object System.Drawing.Size(120, 32)
$messageSaveButton.Text = '保存为文件'
$messageTab.Controls.Add($messageSaveButton)

$messageOutputText = New-Object System.Windows.Forms.TextBox
$messageOutputText.Location = New-Object System.Drawing.Point(20, 392)
$messageOutputText.Size = New-Object System.Drawing.Size(1040, 328)
$messageOutputText.Multiline = $true
$messageOutputText.ScrollBars = 'Both'
$messageOutputText.Font = $monoFont
$messageOutputText.Anchor = 'Top,Bottom,Left,Right'
$messageTab.Controls.Add($messageOutputText)

$openProjectButton.Add_Click({
    Open-PathIfExists $script:ProjectRoot
})

$openReadmeButton.Add_Click({
    Open-PathIfExists (Join-Path $script:ProjectRoot 'README.md')
})

$openInboxButton.Add_Click({
    Open-PathIfExists $script:DefaultOutputRoot
})

$sampleTestButton.Add_Click({
    try {
        $homeLog.Text = "正在运行样例自测，请稍等..."
        $result = Invoke-WorkflowSelfTest
        $homeLog.Text = $result.Output
        if ($result.Success) {
            Show-InfoMessage '样例自测通过，可以开始用了。'
        } else {
            Show-ErrorMessage $result.Output '样例自测失败'
        }
    } catch {
        $homeLog.Text = $_.Exception.Message
        Show-ErrorMessage $_.Exception.Message '样例自测失败'
    }
})

$aiInputBrowse.Add_Click({
    $selected = Select-OpenFile -Filter 'JSON 文件 (*.json)|*.json|所有文件 (*.*)|*.*' -Title '选择 AI 导出 JSON 文件'
    if ($selected) {
        $aiInputText.Text = $selected
        if ([string]::IsNullOrWhiteSpace($aiTitleText.Text)) {
            $aiTitleText.Text = [System.IO.Path]::GetFileNameWithoutExtension($selected)
        }
        if ([string]::IsNullOrWhiteSpace($aiOutputText.Text)) {
            $aiOutputText.Text = Get-DefaultMarkdownPath 'AI对话归档'
        }
    }
})

$aiOutputBrowse.Add_Click({
    $selected = Select-SaveFile -Title '选择 Markdown 保存位置' -InitialPath $aiOutputText.Text
    if ($selected) {
        $aiOutputText.Text = $selected
    }
})

$aiOpenOutputButton.Add_Click({
    Open-PathIfExists $aiOutputText.Text
})

$aiCopyButton.Add_Click({
    Set-ClipboardText $aiPreview.Text
})
$aiRunButton.Add_Click({
    try {
        if ([string]::IsNullOrWhiteSpace($aiInputText.Text) -or -not (Test-Path -LiteralPath $aiInputText.Text)) {
            throw '请先选择一个有效的 JSON 文件。'
        }
        if ([string]::IsNullOrWhiteSpace($aiOutputText.Text)) {
            $aiOutputText.Text = Get-DefaultMarkdownPath 'AI对话归档'
        }
        if ([string]::IsNullOrWhiteSpace($aiTitleText.Text)) {
            $aiTitleText.Text = [System.IO.Path]::GetFileNameWithoutExtension($aiInputText.Text)
        }

        $aiStatus.Text = '状态：正在转换，请稍等...'
        $form.Refresh()

        $result = Invoke-NodeScript -RelativeScript 'scripts\convert-ai-chat.mjs' -Arguments @(
            '--input', $aiInputText.Text,
            '--output', $aiOutputText.Text,
            '--title', $aiTitleText.Text
        )

        if ($result.ExitCode -ne 0) {
            throw $result.Output
        }

        $aiPreview.Text = Read-Utf8Text $aiOutputText.Text
        if ([string]::IsNullOrWhiteSpace($result.Output)) {
            $aiStatus.Text = '状态：转换完成。'
        } else {
            $aiStatus.Text = '状态：转换完成。 ' + $result.Output
        }
    } catch {
        $aiStatus.Text = '状态：转换失败。'
        Show-ErrorMessage $_.Exception.Message 'AI 对话转换失败'
    }
})

$fragmentFileBrowse.Add_Click({
    $selected = Select-OpenFile -Filter '文本/JSON 文件 (*.txt;*.json)|*.txt;*.json|所有文件 (*.*)|*.*' -Title '选择工作碎片文件'
    if ($selected) {
        $fragmentFileText.Text = $selected
        if ([string]::IsNullOrWhiteSpace($fragmentTitleText.Text)) {
            $fragmentTitleText.Text = [System.IO.Path]::GetFileNameWithoutExtension($selected)
        }
        try {
            if ($selected.ToLower().EndsWith('.txt')) {
                $fragmentInputText.Text = Read-Utf8Text $selected
            }
        } catch {
        }
    }
})

$fragmentFileClear.Add_Click({
    $fragmentFileText.Text = ''
})

$fragmentOutputBrowse.Add_Click({
    $selected = Select-SaveFile -Title '选择整理结果保存位置' -InitialPath $fragmentOutputText.Text
    if ($selected) {
        $fragmentOutputText.Text = $selected
    }
})

$fragmentOpenOutputButton.Add_Click({
    Open-PathIfExists $fragmentOutputText.Text
})

$fragmentCopyButton.Add_Click({
    Set-ClipboardText $fragmentPreview.Text
})

$fragmentRunButton.Add_Click({
    $tempInputPath = $null
    try {
        if ([string]::IsNullOrWhiteSpace($fragmentOutputText.Text)) {
            $fragmentOutputText.Text = Get-DefaultMarkdownPath '工作碎片整理'
        }
        if ([string]::IsNullOrWhiteSpace($fragmentTitleText.Text)) {
            $fragmentTitleText.Text = '工作碎片整理 ' + (Get-Date).ToString('yyyy-MM-dd')
        }

        if (-not [string]::IsNullOrWhiteSpace($fragmentFileText.Text) -and (Test-Path -LiteralPath $fragmentFileText.Text)) {
            $inputPath = $fragmentFileText.Text
        } elseif (-not [string]::IsNullOrWhiteSpace($fragmentInputText.Text)) {
            $tempInputPath = Join-Path $script:TempRoot ('work-fragments-' + (Get-TimeStampTag) + '.txt')
            New-Utf8BomFile -Path $tempInputPath -Content $fragmentInputText.Text
            $inputPath = $tempInputPath
        } else {
            throw '请先粘贴工作碎片内容，或者导入一个 txt/json 文件。'
        }

        $fragmentStatus.Text = '状态：正在整理，请稍等...'
        $form.Refresh()

        $result = Invoke-NodeScript -RelativeScript 'scripts\organize-work-fragments.mjs' -Arguments @(
            '--input', $inputPath,
            '--output', $fragmentOutputText.Text,
            '--title', $fragmentTitleText.Text
        )

        if ($result.ExitCode -ne 0) {
            throw $result.Output
        }

        $fragmentPreview.Text = Read-Utf8Text $fragmentOutputText.Text
        if ([string]::IsNullOrWhiteSpace($result.Output)) {
            $fragmentStatus.Text = '状态：整理完成。'
        } else {
            $fragmentStatus.Text = '状态：整理完成。 ' + $result.Output
        }
    } catch {
        $fragmentStatus.Text = '状态：整理失败。'
        Show-ErrorMessage $_.Exception.Message '工作碎片整理失败'
    } finally {
        if ($tempInputPath -and (Test-Path -LiteralPath $tempInputPath)) {
            Remove-Item -LiteralPath $tempInputPath -Force -ErrorAction SilentlyContinue
        }
    }
})

$confirmGenerateButton.Add_Click({
    try {
        if ([string]::IsNullOrWhiteSpace($confirmDetailsText.Text)) {
            throw '请先填写操作内容。'
        }

        $args = @('--mode', 'confirm', '--details', $confirmDetailsText.Text)
        if (-not [string]::IsNullOrWhiteSpace($confirmConsequenceText.Text)) {
            $args += @('--consequence', $confirmConsequenceText.Text)
        }

        $result = Invoke-NodeScript -RelativeScript 'scripts\render-workflow-message.mjs' -Arguments $args
        if ($result.ExitCode -ne 0) {
            throw $result.Output
        }

        $messageOutputText.Text = $result.Output
    } catch {
        Show-ErrorMessage $_.Exception.Message '确认文案生成失败'
    }
})

$confirmCopyButton.Add_Click({
    Set-ClipboardText $messageOutputText.Text
})
$resultGenerateButton.Add_Click({
    try {
        if ([string]::IsNullOrWhiteSpace($resultTaskText.Text)) {
            throw '请先填写任务名。'
        }
        if ([string]::IsNullOrWhiteSpace($resultDetailsText.Text)) {
            throw '请先填写处理内容。'
        }
        if ([string]::IsNullOrWhiteSpace($resultResultText.Text)) {
            throw '请先填写结果。'
        }

        $confirmValue = $resultConfirmText.Text
        if ([string]::IsNullOrWhiteSpace($confirmValue)) {
            $confirmValue = '无'
        }

        $result = Invoke-NodeScript -RelativeScript 'scripts\render-workflow-message.mjs' -Arguments @(
            '--mode', 'result',
            '--task', $resultTaskText.Text,
            '--details', $resultDetailsText.Text,
            '--result', $resultResultText.Text,
            '--confirm', $confirmValue
        )

        if ($result.ExitCode -ne 0) {
            throw $result.Output
        }

        $messageOutputText.Text = $result.Output
    } catch {
        Show-ErrorMessage $_.Exception.Message '执行结果文案生成失败'
    }
})

$resultCopyButton.Add_Click({
    Set-ClipboardText $messageOutputText.Text
})

$messageSaveButton.Add_Click({
    try {
        if ([string]::IsNullOrWhiteSpace($messageOutputText.Text)) {
            throw '当前没有可保存的文案。'
        }

        $initialPath = Join-Path $script:DefaultOutputRoot ('工作流文案-' + (Get-TimeStampTag) + '.txt')
        $savePath = Select-SaveFile -Filter '文本文件 (*.txt)|*.txt|Markdown 文件 (*.md)|*.md|所有文件 (*.*)|*.*' -Title '保存文案结果' -InitialPath $initialPath
        if ($savePath) {
            New-Utf8BomFile -Path $savePath -Content $messageOutputText.Text
            Show-InfoMessage ('已保存：' + $savePath)
        }
    } catch {
        Show-ErrorMessage $_.Exception.Message '保存失败'
    }
})

[System.Windows.Forms.Application]::Run($form)
