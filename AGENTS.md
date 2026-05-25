# Codex Global Instructions

## Language and OS

- 默认使用中文回答。
- 我的系统是 Windows。
- 给命令时优先使用 PowerShell。
- 路径中如果有空格，请自动加引号。
- 先给结论，再给步骤。

## Main working folder

- 我经常在 `C:\DIY\Codex CLI` 里面运行 Codex。
- 这个目录既包含 Codex 工具脚本，也可能包含我的临时工作内容。
- 不要随意修改以下核心工具文件，除非我明确要求“修改 Codex 配置/脚本/换号工具”：
  - `C:\DIY\Codex CLI\codex.ps1`
  - `C:\DIY\Codex CLI\启动Cursor-Codex.cmd`
  - `C:\DIY\Codex CLI\Launch-Cursor-Codex.ps1`
  - `C:\DIY\Codex CLI\Codex换号.cmd`
  - `C:\DIY\Codex CLI\CodexAccountSwitcherGUI.ps1`
  - `C:\DIY\Codex CLI\Codex重新登录.cmd`
  - `C:\DIY\Codex CLI\检查Codex账号.cmd`
  - `C:\DIY\Codex CLI\Check-CodexAccount.ps1`
  - `C:\DIY\Codex CLI\AGENTS.md`
  - `C:\DIY\Codex CLI\backup`
  - `C:\DIY\Codex CLI\logs`

## Safety

- 修改文件前，先说明准备修改什么。
- 不要自动执行危险命令。
- 危险操作包括但不限于：删除文件、清空目录、格式化、修改系统目录、修改注册表、修改全局环境变量、推送 Git、暴露密钥。
- 如果操作可能影响系统设置、账号、API Key、代理、重要文件、Git 历史或账单，必须先提醒我确认。
- 不要在 `C:\Windows`、`C:\Windows\System32`、`C:\Program Files`、`C:\Program Files (x86)` 里工作。
- 不要泄露 `.env`、`auth.json`、token、API Key、cookie、密码或凭据。

## Coding style

- 优先给最小可行方案。
- 代码要简单、清晰、可运行。
- 调试时先判断最可能原因，再给验证步骤。
- 创建文件时说明文件名和位置。
- 运行命令前简要解释命令作用。
- 不要过度设计。

## Proxy preference

- 我经常访问中国大陆地区网站。
- 不要建议我长期使用全局代理。
- 如果 Codex 需要代理，只使用临时进程级代理。
- 不要污染整个 Windows 或 PowerShell 的全局环境变量。
