@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

:: Claude Code 一键安装脚本（MiniMax 版 · Windows）
:: 首次运行请【右键 - 以管理员身份运行】，或直接双击（会自动请求管理员权限）

:: ── 管理员权限检查与自动提升 ──────────────────────────────────
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo   需要管理员权限，正在请求授权...
    echo   如果弹出确认窗口，请点「是」
    echo.
    powershell -NoProfile -Command "Start-Process '%~dpnx0' -Verb RunAs"
    exit /b
)

:: 提升后工作目录会变成 System32，这里切回脚本所在目录
cd /d "%~dp0"

:: ── 配置区域（修改 API Key 后再运行）─────────────────────────
set "API_KEY=sk-****** 此处换成你的 API KEY ********"

echo.
echo   ============================================================
echo   =       Claude Code 安装脚本（MiniMax 版 · Windows）       =
echo   ============================================================
echo.

:: ── 检查 Windows 版本 ──────────────────────────────────────────
:: curl.exe 从 Windows 10 1803 开始内置
where curl.exe >nul 2>&1
if %errorlevel% neq 0 (
    echo   [错误] 当前 Windows 版本过旧，需要 Windows 10 1803 或更高版本
    echo   请先更新 Windows 系统后再运行本脚本
    echo.
    pause
    exit /b 1
)

:: ── 第 1 步：检查并安装 Git ────────────────────────────────────
echo   ----------------------------------------------------------
echo   [1/4] 正在检查 Git...
echo   ----------------------------------------------------------

where git >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=*" %%v in ('git --version 2^>nul') do echo   [OK] %%v
    goto :git_done
)

echo   Git 未安装，正在下载...
echo.

set "GIT_VERSION=2.47.1.2"
set "GIT_FILE=Git-%GIT_VERSION%-64-bit.exe"
set "GIT_URL_CN=https://registry.npmmirror.com/-/binary/git-for-windows/v2.47.1.windows.2/%GIT_FILE%"
set "GIT_URL_OFFICIAL=https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.2/%GIT_FILE%"

echo   正在从国内镜像下载 Git...
curl.exe -# -L -o "%TEMP%\%GIT_FILE%" "%GIT_URL_CN%"
if !errorlevel! neq 0 (
    echo   国内镜像下载失败，切换 GitHub 官方源重试...
    curl.exe -# -L -o "%TEMP%\%GIT_FILE%" "%GIT_URL_OFFICIAL%"
    if !errorlevel! neq 0 (
        echo   [错误] Git 下载失败，请检查网络连接后重试
        pause
        exit /b 1
    )
)

echo   正在安装 Git（静默安装，请稍候）...
"%TEMP%\%GIT_FILE%" /VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS="icons,ext\reg\shellhere,assoc,assoc_sh"
if !errorlevel! neq 0 (
    echo   [错误] Git 安装失败
    pause
    exit /b 1
)
del /f "%TEMP%\%GIT_FILE%" 2>nul

:: 将 Git 加入当前会话的 PATH
set "PATH=%PATH%;C:\Program Files\Git\cmd"
echo   [OK] Git 安装完成

:git_done
echo.

:: ── 第 2 步：检查并安装 Node.js ────────────────────────────────
echo   ----------------------------------------------------------
echo   [2/4] 正在检查 Node.js...
echo   ----------------------------------------------------------

set "NODE_OK=0"
where node >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=1 delims=." %%a in ('node --version 2^>nul') do (
        set "NODE_VER=%%a"
        set "NODE_VER=!NODE_VER:v=!"
    )
    if !NODE_VER! geq 18 (
        set "NODE_OK=1"
        for /f "tokens=*" %%v in ('node --version 2^>nul') do echo   [OK] Node.js %%v
    ) else (
        echo   Node.js 版本过低，需要升级
    )
)

if "!NODE_OK!"=="0" (
    echo   正在下载 Node.js v20...
    echo.

    set "NODE_VERSION=v20.19.1"
    set "NODE_FILE=node-!NODE_VERSION!-x64.msi"
    set "NODE_URL_CN=https://npmmirror.com/mirrors/node/!NODE_VERSION!/!NODE_FILE!"
    set "NODE_URL_OFFICIAL=https://nodejs.org/dist/!NODE_VERSION!/!NODE_FILE!"

    echo   正在从国内镜像下载 Node.js...
    curl.exe -# -L -o "%TEMP%\!NODE_FILE!" "!NODE_URL_CN!"
    if !errorlevel! neq 0 (
        echo   国内镜像下载失败，切换官方源重试...
        curl.exe -# -L -o "%TEMP%\!NODE_FILE!" "!NODE_URL_OFFICIAL!"
        if !errorlevel! neq 0 (
            echo   [错误] Node.js 下载失败，请检查网络连接后重试
            pause
            exit /b 1
        )
    )

    echo   正在安装 Node.js（静默安装，请稍候）...
    msiexec /i "%TEMP%\!NODE_FILE!" /qn /norestart
    if !errorlevel! neq 0 (
        echo   [错误] Node.js 安装失败
        pause
        exit /b 1
    )
    del /f "%TEMP%\!NODE_FILE!" 2>nul

    :: 将 Node.js 加入当前会话的 PATH
    set "PATH=%PATH%;C:\Program Files\nodejs"
    echo   [OK] Node.js 安装完成
)

echo.

:: ── 第 3 步：安装 Claude Code ──────────────────────────────────
echo   ----------------------------------------------------------
echo   [3/4] 正在安装 Claude Code（可能需要 1-3 分钟）...
echo   ----------------------------------------------------------
echo.

call npm install -g @anthropic-ai/claude-code --registry=https://registry.npmmirror.com 2>nul
if !errorlevel! neq 0 (
    echo   国内镜像失败，切换官方源重试...
    call npm install -g @anthropic-ai/claude-code
    if !errorlevel! neq 0 (
        echo   [错误] Claude Code 安装失败，请检查网络连接后重试
        pause
        exit /b 1
    )
)

echo   [OK] Claude Code 安装成功
echo.

:: ── 第 4 步：写入 MiniMax API 配置 ────────────────────────────
echo   ----------------------------------------------------------
echo   [4/4] 正在配置 MiniMax API...
echo   ----------------------------------------------------------
echo.

:: 创建配置目录
if not exist "%USERPROFILE%\.claude" mkdir "%USERPROFILE%\.claude"

:: 用 PowerShell 写入 settings.json（避免 batch 转义问题）
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$settingsDir = Join-Path $env:USERPROFILE '.claude';" ^
  "$settingsPath = Join-Path $settingsDir 'settings.json';" ^
  "$apiKey = '%API_KEY%';" ^
  "$json = '{' + [Environment]::NewLine;" ^
  "$json += '  \"env\": {' + [Environment]::NewLine;" ^
  "$json += '    \"ANTHROPIC_BASE_URL\": \"https://api.minimaxi.com/anthropic\",' + [Environment]::NewLine;" ^
  "$json += '    \"ANTHROPIC_AUTH_TOKEN\": \"' + $apiKey + '\",' + [Environment]::NewLine;" ^
  "$json += '    \"API_TIMEOUT_MS\": \"3000000\",' + [Environment]::NewLine;" ^
  "$json += '    \"CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC\": \"1\",' + [Environment]::NewLine;" ^
  "$json += '    \"ANTHROPIC_MODEL\": \"MiniMax-M2.7\",' + [Environment]::NewLine;" ^
  "$json += '    \"ANTHROPIC_SMALL_FAST_MODEL\": \"MiniMax-M2.7\",' + [Environment]::NewLine;" ^
  "$json += '    \"ANTHROPIC_DEFAULT_SONNET_MODEL\": \"MiniMax-M2.7\",' + [Environment]::NewLine;" ^
  "$json += '    \"ANTHROPIC_DEFAULT_OPUS_MODEL\": \"MiniMax-M2.7\",' + [Environment]::NewLine;" ^
  "$json += '    \"ANTHROPIC_DEFAULT_HAIKU_MODEL\": \"MiniMax-M2.7\"' + [Environment]::NewLine;" ^
  "$json += '  },' + [Environment]::NewLine;" ^
  "$json += '  \"permissions\": {' + [Environment]::NewLine;" ^
  "$json += '    \"allow\": [' + [Environment]::NewLine;" ^
  "$json += '      \"Edit\",' + [Environment]::NewLine;" ^
  "$json += '      \"Write\",' + [Environment]::NewLine;" ^
  "$json += '      \"Bash(python3:*)\",' + [Environment]::NewLine;" ^
  "$json += '      \"Bash(python:*)\",' + [Environment]::NewLine;" ^
  "$json += '      \"Bash(pip3 install:*)\",' + [Environment]::NewLine;" ^
  "$json += '      \"Bash(pip install:*)\",' + [Environment]::NewLine;" ^
  "$json += '      \"Bash(node:*)\",' + [Environment]::NewLine;" ^
  "$json += '      \"Bash(npm install:*)\",' + [Environment]::NewLine;" ^
  "$json += '      \"Bash(npx:*)\",' + [Environment]::NewLine;" ^
  "$json += '      \"Bash(start:*)\",' + [Environment]::NewLine;" ^
  "$json += '      \"Bash(ls:*)\",' + [Environment]::NewLine;" ^
  "$json += '      \"Bash(dir:*)\",' + [Environment]::NewLine;" ^
  "$json += '      \"Bash(type:*)\",' + [Environment]::NewLine;" ^
  "$json += '      \"Bash(cat:*)\",' + [Environment]::NewLine;" ^
  "$json += '      \"Bash(head:*)\",' + [Environment]::NewLine;" ^
  "$json += '      \"Bash(tail:*)\",' + [Environment]::NewLine;" ^
  "$json += '      \"Bash(mkdir:*)\",' + [Environment]::NewLine;" ^
  "$json += '      \"Bash(copy:*)\",' + [Environment]::NewLine;" ^
  "$json += '      \"Bash(cp:*)\",' + [Environment]::NewLine;" ^
  "$json += '      \"Bash(move:*)\",' + [Environment]::NewLine;" ^
  "$json += '      \"Bash(mv:*)\",' + [Environment]::NewLine;" ^
  "$json += '      \"Bash(del:*)\",' + [Environment]::NewLine;" ^
  "$json += '      \"Bash(rm:*)\",' + [Environment]::NewLine;" ^
  "$json += '      \"Bash(find:*)\",' + [Environment]::NewLine;" ^
  "$json += '      \"Bash(findstr:*)\",' + [Environment]::NewLine;" ^
  "$json += '      \"Bash(grep:*)\",' + [Environment]::NewLine;" ^
  "$json += '      \"Bash(sort:*)\",' + [Environment]::NewLine;" ^
  "$json += '      \"Bash(wc:*)\",' + [Environment]::NewLine;" ^
  "$json += '      \"Bash(curl:*)\"' + [Environment]::NewLine;" ^
  "$json += '    ]' + [Environment]::NewLine;" ^
  "$json += '  }' + [Environment]::NewLine;" ^
  "$json += '}';" ^
  "[System.IO.File]::WriteAllText($settingsPath, $json, [System.Text.UTF8Encoding]::new($false))"

:: 用 PowerShell 写入 CLAUDE.md
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$p = Join-Path (Join-Path $env:USERPROFILE '.claude') 'CLAUDE.md';" ^
  "$L = [System.Collections.Generic.List[string]]::new();" ^
  "$L.Add('# 全局规则');" ^
  "$L.Add('');" ^
  "$L.Add('- 所有回答使用中文');" ^
  "$L.Add('- 用通俗易懂的语言，避免技术术语；如果必须提到技术概念，用括号加一句话解释');" ^
  "$L.Add('- 修改文件前先说明要改什么、为什么改');" ^
  "$L.Add('- 分析数据时给出明确的结论和可执行的建议，不要只罗列数字');" ^
  "$L.Add('- 生成文件时使用中文文件名');" ^
  "$L.Add('- 生成网页时直接创建本地 HTML 文件，不要启动本地服务器');" ^
  "[System.IO.File]::WriteAllLines($p, $L, [System.Text.UTF8Encoding]::new($false))"

:: 用 PowerShell 写入 .claude.json（跳过首次引导流程）
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$configPath = Join-Path $env:USERPROFILE '.claude.json';" ^
  "$homePath = $env:USERPROFILE -replace '\\', '/';" ^
  "$json = '{' + [Environment]::NewLine;" ^
  "$json += '  \"hasCompletedOnboarding\": true,' + [Environment]::NewLine;" ^
  "$json += '  \"projects\": {' + [Environment]::NewLine;" ^
  "$json += '    \"' + $homePath + '\": {' + [Environment]::NewLine;" ^
  "$json += '      \"hasTrustedProjectRoot\": true' + [Environment]::NewLine;" ^
  "$json += '    }' + [Environment]::NewLine;" ^
  "$json += '  }' + [Environment]::NewLine;" ^
  "$json += '}';" ^
  "[System.IO.File]::WriteAllText($configPath, $json, [System.Text.UTF8Encoding]::new($false))"

echo   [OK] MiniMax API 配置完成

:: ── 安装完成 ────────────────────────────────────────────────────
echo.
echo   ============================================================
echo   =                                                          =
echo   =               [OK] 安装成功！                            =
echo   =                                                          =
echo   ============================================================
echo.
echo   ----------------------------------------------------------
echo     接下来怎么用？按以下步骤操作：
echo   ----------------------------------------------------------
echo.
echo     第一步：关闭这个窗口（点右上角 X 号，或按 Alt + F4）
echo.
echo     第二步：打开 PowerShell
echo             按 Win 键，搜索「PowerShell」，点击打开
echo             （或在桌面空白处右键 - 选「在终端中打开」）
echo.
echo     第三步：输入 claude 然后按回车，即可开始使用
echo.
echo   ----------------------------------------------------------
echo     提示：在当前窗口输入 claude 可能不会成功，
echo           这是正常现象，必须重新打开一个新窗口才行。
echo   ----------------------------------------------------------
echo.

pause
