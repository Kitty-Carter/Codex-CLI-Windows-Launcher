# AI 工具懒人总说明

## 当前状态

- Gemini CLI：已配置完成，可以使用。
- Codex CLI：已配置完成，可以使用。
- Cursor 里的 Codex 扩展：已经可以正常回复中文。
- 日常写代码优先用 Cursor + Codex。
- 快速命令、脚本、自动化任务优先用 Codex CLI。
- Gemini CLI 作为备用 AI CLI 工具保留。

## 最常用入口

### 启动 Cursor + Codex

双击：

```text
C:\DIY\Codex CLI\启动Cursor-Codex.cmd
```

它会让你选择真正想打开的项目文件夹，并临时给 Cursor 设置代理。

### 检查 Codex 当前账号

双击：

```text
C:\DIY\Codex CLI\检查Codex账号.cmd
```

### Codex 换号

双击：

```text
C:\DIY\Codex CLI\Codex换号.cmd
```

### Codex 重新登录

双击：

```text
C:\DIY\Codex CLI\Codex重新登录.cmd
```

### Codex CLI 单次任务

```powershell
cd "C:\DIY\Codex CLI"
codex exec "请用中文回答。Say hi."
```

### Gemini CLI 单次任务

```powershell
gemini -p "请用中文回答。Say hi."
```

## 重要提醒

- Codex CLI 的单次提问是 `codex exec`，不是 `codex -p`。
- Gemini CLI 的单次提问是 `gemini -p`。
- 不要长期设置 Windows 全局代理环境变量。
- 不要删除 `C:\Users\zyp31\.codex\auth.json`。
- 不要删除 `C:\Users\zyp31\.codex\config.toml`。
- 不要在 `C:\Windows`、`C:\Windows\System32`、`C:\Program Files` 里运行 Codex 或 Gemini。
