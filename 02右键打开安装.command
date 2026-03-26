#!/bin/bash
# Claude Code 一键安装脚本（MiniMax 版 · macOS）
# 首次运行请【右键 → 打开】，之后可直接双击

# ── 颜色定义 ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
API_KEY="sk-****** 此处换成你的 API KEY ********"

echo ""
echo -e "${BOLD}=== Claude Code 安装脚本（MiniMax 版）===${NC}"
echo ""

# ── 清除 macOS 隔离属性（Gatekeeper）─────────────────
# 微信/邮件传输的文件会被系统标记为"隔离"，这里统一清除
xattr -dr com.apple.quarantine "$SCRIPT_DIR" 2>/dev/null

# ── PATH 初始化（覆盖 Node.js 常见安装路径）──────────────────
export PATH="/usr/local/bin:/usr/local/sbin:/opt/homebrew/bin:$PATH"

# ── 提前缓存 sudo 密码，全程只输一次 ──────────────────────
echo "安装过程需要管理员权限，请输入开机密码："
sudo -v
# 后台定时刷新缓存，防止长时间安装期间密码过期
( while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null ) &
SUDO_KEEPALIVE_PID=$!

# ── 检查并安装 Git（macOS 命令行开发者工具）──────────────
echo ""
echo "正在检查 Git..."

if git --version &>/dev/null 2>&1; then
    echo -e "${GREEN}✓ Git 已就绪：$(git --version)${NC}"
else
    echo "正在安装 Git（系统会弹出安装窗口，请点「安装」）..."
    xcode-select --install 2>/dev/null
    echo -e "${YELLOW}请在弹出的窗口中点「安装」${NC}"
    echo -e "${YELLOW}安装大约需要 5-20 分钟，请保持网络连接，完成后回到这里按回车${NC}"
    read -p "安装完成后，按回车键继续..."
    if ! git --version &>/dev/null 2>&1; then
        echo -e "${RED}Git 未安装成功，请在弹窗中点「安装」完成后重新运行本脚本${NC}"
        read -p "按回车键退出..."
        exit 1
    fi
    echo -e "${GREEN}✓ Git 安装完成${NC}"
fi

# ── 检查并安装 Node.js（直接从 nodejs.org 下载，无需 GitHub）──
echo ""
echo "正在检查 Node.js..."

NODE_OK=false
if command -v node &>/dev/null; then
    NODE_MAJOR=$(node --version | sed 's/v//' | cut -d. -f1)
    if [ "$NODE_MAJOR" -ge 18 ]; then
        NODE_OK=true
        echo -e "${GREEN}✓ Node.js 已就绪：$(node --version)${NC}"
    else
        echo -e "${YELLOW}Node.js 版本过低（$(node --version)），需要升级${NC}"
    fi
fi

if [ "$NODE_OK" = false ]; then
    NODE_VERSION="v20.19.1"
    PKG_URL_CN="https://npmmirror.com/mirrors/node/${NODE_VERSION}/node-${NODE_VERSION}.pkg"
    PKG_URL="https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}.pkg"
    echo "正在下载 Node.js ${NODE_VERSION}..."
    curl -# -L -o /tmp/node_installer.pkg "$PKG_URL_CN"
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}国内镜像下载失败，切换官方源重试...${NC}"
        curl -# -L -o /tmp/node_installer.pkg "$PKG_URL"
        if [ $? -ne 0 ]; then
            echo -e "${RED}下载失败，请检查网络后重试${NC}"
            read -p "按回车键退出..."
            exit 1
        fi
    fi
    echo "正在安装 Node.js（需要输入开机密码）..."
    sudo installer -pkg /tmp/node_installer.pkg -target /
    rm -f /tmp/node_installer.pkg
    export PATH="/usr/local/bin:$PATH"
    if node --version &>/dev/null 2>&1; then
        echo -e "${GREEN}✓ Node.js 安装完成：$(node --version)${NC}"
    else
        echo -e "${GREEN}✓ Node.js 安装完成（重新打开终端后生效）${NC}"
    fi
fi

# ── 安装 Claude Code，失败时切换国内镜像重试 ──────────
echo ""
echo "正在安装 Claude Code（可能需要 1-3 分钟）..."

sudo npm install -g @anthropic-ai/claude-code --registry=https://registry.npmmirror.com

if [ $? -ne 0 ]; then
    echo -e "${YELLOW}国内镜像失败，切换官方源重试...${NC}"
    sudo npm install -g @anthropic-ai/claude-code
    if [ $? -ne 0 ]; then
        echo -e "${RED}安装失败，请检查网络连接后重试${NC}"
        read -p "按回车键退出..."
        exit 1
    fi
fi

echo -e "${GREEN}✓ Claude Code 安装成功${NC}"

# ── 写入 MiniMax API 配置 ──────────────────────────────────
echo ""
echo "正在配置 MiniMax API..."

# 创建 Claude Code 配置目录
mkdir -p "$HOME/.claude"

# 写入 settings.json（MiniMax API 配置 + 预授权常用操作）
cat > "$HOME/.claude/settings.json" << EOF
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://api.minimaxi.com/anthropic",
    "ANTHROPIC_AUTH_TOKEN": "${API_KEY}",
    "API_TIMEOUT_MS": "3000000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
    "ANTHROPIC_MODEL": "MiniMax-M2.7",
    "ANTHROPIC_SMALL_FAST_MODEL": "MiniMax-M2.7",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "MiniMax-M2.7",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "MiniMax-M2.7",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "MiniMax-M2.7"
  },
  "permissions": {
    "allow": [
      "Edit",
      "Write",
      "Bash(python3:*)",
      "Bash(python:*)",
      "Bash(pip3 install:*)",
      "Bash(pip install:*)",
      "Bash(node:*)",
      "Bash(npm install:*)",
      "Bash(npx:*)",
      "Bash(open:*)",
      "Bash(ls:*)",
      "Bash(cat:*)",
      "Bash(head:*)",
      "Bash(tail:*)",
      "Bash(mkdir:*)",
      "Bash(cp:*)",
      "Bash(mv:*)",
      "Bash(rm:*)",
      "Bash(touch:*)",
      "Bash(find:*)",
      "Bash(grep:*)",
      "Bash(sort:*)",
      "Bash(wc:*)",
      "Bash(curl:*)",
      "Bash(chmod:*)"
    ]
  }
}
EOF

# 写入全局规则 CLAUDE.md（适合产品经理的预设）
cat > "$HOME/.claude/CLAUDE.md" << 'CLAUDEMD'
# 全局规则

- 所有回答使用中文
- 用通俗易懂的语言，避免技术术语；如果必须提到技术概念，用括号加一句话解释
- 修改文件前先说明要改什么、为什么改
- 分析数据时给出明确的结论和可执行的建议，不要只罗列数字
- 生成文件时使用中文文件名
- 生成网页时直接创建本地 HTML 文件，不要启动本地服务器
CLAUDEMD

# 写入 .claude.json（跳过首次引导流程 + 预信任家目录，直接可用）
cat > "$HOME/.claude.json" << EOF
{
  "hasCompletedOnboarding": true,
  "projects": {
    "${HOME}": {
      "hasTrustedProjectRoot": true
    }
  }
}
EOF

echo -e "${GREEN}✓ MiniMax API 配置完成${NC}"

# ── 清理旧版配置（如果之前运行过旧版脚本）──────────────────
if [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ]; then
    SHELL_RC="$HOME/.zshrc"
else
    SHELL_RC="$HOME/.bash_profile"
fi

if [ -f "$SHELL_RC" ]; then
    sed -i '' '/# >>> Claude Code Config >>>/,/# <<< Claude Code Config <<</d' "$SHELL_RC" 2>/dev/null
fi

# ── 完成 ────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║              ✅  安装成功！                          ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  接下来怎么用？按以下步骤操作：${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${BOLD}第一步：${NC}完全关闭这个窗口"
echo -e "          （点左上角红色叉号，或按 Command + Q）"
echo -e "          提示：在这个窗口里输入 claude 不会成功，必须重新打开才行，这是正常现象"
echo ""
echo -e "  ${BOLD}第二步：${NC}重新打开「终端」"
echo -e "          在 Finder → 应用程序 → 实用工具 → 终端"
echo -e "          或者按 Command + 空格，搜索「终端」打开"
echo ""
echo -e "  ${BOLD}第三步：${NC}输入 claude 然后按回车，即可开始使用"
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
kill "$SUDO_KEEPALIVE_PID" 2>/dev/null
read -p "  现在按回车键关闭此窗口..."
