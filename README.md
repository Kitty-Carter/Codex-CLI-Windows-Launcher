# Codex CLI Windows Launcher

Windows launcher and helper scripts for Codex CLI and Cursor integration.

这个仓库用于在 Windows 上更方便地启动、检查和管理 Codex CLI。  
它主要面向不想频繁输入 PowerShell 命令的用户，提供一组可双击运行的 `.cmd` 启动入口和配套 PowerShell 脚本。

---

## 1. 项目用途

本项目不是 Codex CLI 本体，而是一个 Windows 辅助启动器。

它主要解决这些问题：

- 在 Windows 上快速启动 Codex CLI
- 一键启动 Cursor + Codex 工作流
- 检查当前 Codex 登录状态
- 重新登录 Codex
- 切换 Codex 账号
- 运行 Codex CLI 单次任务
- 避免在系统目录中误运行
- 尽量减少对全局环境变量的污染

推荐定位：

```text
Cursor + Codex：日常写代码主力
Codex CLI：快速命令行任务 / 自动化 / 脚本化备用
本仓库：Windows 懒人启动器和辅助脚本
```

---

## 2. 推荐放置位置

建议把本仓库文件放到：

```text
C:\DIY\Codex CLI
```

推荐目录结构：

```text
C:\DIY\Codex CLI
├── AGENTS.md
├── README.md
├── Codex-使用说明.md
├── 故障排查.md
├── codex.ps1
├── Check-CodexAccount.ps1
├── CodexAccountSwitcherGUI.ps1
├── Launch-Cursor-Codex.ps1
├── Run-CodexLoginOnce.ps1
├── 启动Cursor-Codex.cmd
├── 检查Codex账号.cmd
├── Codex换号.cmd
└── Codex重新登录.cmd
```

---

## 3. 文件说明

| 文件 | 作用 |
|---|---|
| `AGENTS.md` | 给 Codex 使用的项目级说明和行为规则 |
| `codex.ps1` | Codex CLI 的 Windows 启动脚本 |
| `Check-CodexAccount.ps1` | 检查当前 Codex 登录状态 |
| `CodexAccountSwitcherGUI.ps1` | Codex 账号切换辅助脚本 |
| `Launch-Cursor-Codex.ps1` | 启动 Cursor + Codex 工作流 |
| `Run-CodexLoginOnce.ps1` | 执行一次 Codex 登录流程 |
| `启动Cursor-Codex.cmd` | 双击启动 Cursor + Codex |
| `检查Codex账号.cmd` | 双击检查当前 Codex 账号 |
| `Codex换号.cmd` | 双击进行 Codex 换号 |
| `Codex重新登录.cmd` | 双击重新登录 Codex |
| `Codex-使用说明.md` | 详细使用说明 |
| `故障排查.md` | 常见问题和排查方法 |

---

## 4. 最常用入口

### 4.1 启动 Cursor + Codex

双击：

```text
启动Cursor-Codex.cmd
```

用途：

- 打开 Cursor
- 进入你选择的项目目录
- 为 Cursor / Codex 设置必要的临时环境
- 适合日常写代码

这是最推荐的日常入口。

---

### 4.2 检查 Codex 当前账号

双击：

```text
检查Codex账号.cmd
```

用途：

- 检查当前 Codex 是否已登录
- 检查当前使用的账号状态
- 排查 Codex 无法正常使用的问题

---

### 4.3 Codex 换号

双击：

```text
Codex换号.cmd
```

用途：

- 切换 Codex 当前账号
- 清理或更新当前登录状态
- 适合多个账号之间切换使用

---

### 4.4 Codex 重新登录

双击：

```text
Codex重新登录.cmd
```

用途：

- 当前 Codex 登录异常时重新登录
- 登录信息过期时重新授权
- Codex CLI 无法正常识别账号时排查

---

## 5. Codex CLI 常用命令

### 5.1 单次任务

Codex CLI 的单次任务命令是：

```powershell
codex exec "请用中文回答。Say hi."
```

注意：

```text
Codex CLI 单次任务：codex exec "问题"
Gemini CLI 单次提问：gemini -p "问题"
```

不要写成：

```powershell
codex -p "问题"
```

`codex -p` 不是 Codex CLI 的单次提问方式。

---

### 5.2 进入指定目录后运行 Codex

```powershell
cd "你的项目目录"
codex exec "请分析这个项目的结构，不要修改任何文件。"
```

如果路径中有空格，必须加英文双引号：

```powershell
cd "C:\DIY\Codex CLI"
```

---

## 6. 推荐使用方式

### 6.1 日常写代码

优先使用：

```text
Cursor + Codex
```

入口：

```text
启动Cursor-Codex.cmd
```

适合：

- 正式写代码
- 阅读项目
- 修改文件
- 长时间开发
- 需要编辑器上下文

---

### 6.2 快速命令行任务

使用：

```powershell
codex exec "你的问题"
```

适合：

- 快速解释报错
- 检查命令含义
- 生成小脚本
- 分析单个问题
- 自动化任务

---

### 6.3 账号异常排查

优先顺序：

```text
1. 检查Codex账号.cmd
2. Codex重新登录.cmd
3. Codex换号.cmd
4. 查看 故障排查.md
```

---

## 7. 安全提醒

不要公开上传以下内容：

```text
logs/
backup/
.env
*.key
*.token
*.pem
cursor-path.txt
cursor-last-workspace.txt
```

不要泄露：

```text
API Key
token
账号认证文件
个人密码
本机敏感路径
```

不要随便删除：

```text
%USERPROFILE%\.codex\auth.json
%USERPROFILE%\.codex\config.toml
```

如果你不确定这些文件是否可以删除，请先备份。

---

## 8. 不建议运行 Codex 的目录

不要在这些系统目录中运行 Codex 或 Gemini：

```text
C:\Windows
C:\Windows\System32
C:\Program Files
C:\Program Files (x86)
```

原因：

- 这些是系统目录
- 误操作风险高
- AI 工具可能误读或误改系统文件
- 不适合作为项目工作目录

建议在具体项目目录中运行，例如：

```text
C:\DIY\MyProject
D:\Projects\MyApp
```

---

## 9. 推荐提示词

### 9.1 只分析，不修改

```text
请用中文回答。先分析当前目录结构，不要修改任何文件。
```

### 9.2 分析报错

```text
请用中文回答。先判断最可能原因，再给排查步骤。下面是报错：
```

### 9.3 让 Codex 先给计划

```text
请先告诉我你准备查看哪些文件、准备做什么，不要直接修改文件。等我确认后再继续。
```

### 9.4 修改文件前确认

```text
如果需要修改文件，请先列出将要修改的文件和原因，等我确认后再执行。
```

---

## 10. 常见问题

### 10.1 Codex 无法识别当前账号

先双击：

```text
检查Codex账号.cmd
```

如果仍然异常，再尝试：

```text
Codex重新登录.cmd
```

---

### 10.2 需要切换账号

双击：

```text
Codex换号.cmd
```

如果切换后仍然异常，建议关闭所有相关终端和 Cursor，再重新启动。

---

### 10.3 PowerShell 出现 `>>`

说明 PowerShell 进入了多行输入状态。

处理方式：

```text
按 Ctrl + C
```

直到回到正常提示符：

```powershell
PS C:\...>
```

---

### 10.4 路径中有空格导致命令失败

Windows 路径有空格时，要加英文双引号。

错误示例：

```powershell
cd C:\DIY\Codex CLI
```

正确示例：

```powershell
cd "C:\DIY\Codex CLI"
```

---

### 10.5 `.cmd` 窗口一闪而过

可以手动打开 PowerShell，然后运行：

```powershell
cd "C:\DIY\Codex CLI"
.\启动Cursor-Codex.cmd
```

这样可以看到具体报错。

---

## 11. 与 Gemini CLI 的区别

Codex CLI 单次任务：

```powershell
codex exec "问题"
```

Gemini CLI 单次提问：

```powershell
gemini -p "问题"
```

推荐分工：

```text
Cursor + Codex：主力写代码
Codex CLI：快速任务和自动化
Gemini CLI：备用问答和结果复核
```

---

## 12. 下载方式

点击 GitHub 页面上的绿色按钮：

```text
Code → Download ZIP
```

下载后解压，把文件放到：

```text
C:\DIY\Codex CLI
```

然后优先双击：

```text
启动Cursor-Codex.cmd
```

---

## 13. License

This project is released under the MIT License.
