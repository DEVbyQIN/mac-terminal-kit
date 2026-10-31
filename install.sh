#!/usr/bin/env bash
# mac-terminal-kit —— 把「系统自带 Terminal.app」调好用的最小安装脚本
#
# 设计原则（对应「先找已有项目，不重复造轮子」）：
#   * 不装终端模拟器，只调 Terminal.app 自己的描述文件
#   * 提示符用现成的 Starship，补全/高亮用现成的 zsh 插件
#   * 全部装在 ~/.local 下，不碰 /usr/local，不需要 sudo
#   * 幂等：重复执行只会跳过已完成的步骤；每个被改动的文件都有备份
#
# 用法：
#   ./install.sh                 # 安装 + 生成并导入配色描述文件
#   ./install.sh --dry-run       # 只打印将要做什么
#   ./install.sh --no-open       # 生成描述文件但不自动导入（不弹终端窗口）
#   ./install.sh --no-shell      # 只调外观，不改 ~/.zshrc
#   ./install.sh --with-light    # 同时生成浅色描述文件
#   ./install.sh --dark-name "My Dark" --with-light --light-name "My Light"
#   ./install.sh --font "SFMono-Regular" --size 13 --scrollback 50000
set -euo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARSHIP_VERSION="1.27.0"
AUTOSUGGESTIONS_TAG="v0.7.1"
SYNTAX_HIGHLIGHTING_TAG="0.8.0"

DRY_RUN=0
NO_OPEN=0
NO_SHELL=0
WITH_LIGHT=0
SCROLLBACK=50000
FONT_PS="SFMono-Regular"
FONT_SIZE=13
DARK_NAME="Qin-Dark"      # 可用 --dark-name 改
LIGHT_NAME="Qin-Light"    # 可用 --light-name 改
THEMES_DIR="$KIT_DIR/terminal"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/mtk.XXXXXX")" || exit 1
trap 'rm -rf "$WORK"' EXIT

# ------------------------------------------------------------------ 输出helper
say()  { printf '%s\n' "$*"; }
step() { printf '\n\033[1m== %s\033[0m\n' "$*"; }
act()  { if [ "$DRY_RUN" = 1 ]; then printf '   [dry-run] %s\n' "$*"; else "$@"; fi; }
warn() { printf '\033[33m   ! %s\033[0m\n' "$*"; }

# ------------------------------------------------------------------ 参数
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)    DRY_RUN=1 ;;
    --no-open)    NO_OPEN=1 ;;
    --no-shell)   NO_SHELL=1 ;;
    --with-light) WITH_LIGHT=1 ;;
    --scrollback) SCROLLBACK="${2:?--scrollback 需要数字}"; shift ;;
    --font)       FONT_PS="${2:?--font 需要字体 PostScript 名}"; shift ;;
    --size)       FONT_SIZE="${2:?--size 需要字号}"; shift ;;
    --dark-name)  DARK_NAME="${2:?--dark-name 需要名字}"; shift ;;
    --light-name) LIGHT_NAME="${2:?--light-name 需要名字}"; shift ;;
    -h|--help)    sed -n '2,20p' "$0"; exit 0 ;;
    *) warn "未知参数 $1"; exit 2 ;;
  esac
  shift
done

# ------------------------------------------------------------------ 前置检查
step "环境检查"
[ "$(uname -s)" = "Darwin" ] || { warn "这是 macOS 专用脚本"; exit 1; }
case "$(uname -m)" in
  x86_64) STARSHIP_ASSET="starship-x86_64-apple-darwin.tar.gz" ;;
  arm64)  STARSHIP_ASSET="starship-aarch64-apple-darwin.tar.gz" ;;
  *) warn "未知架构 $(uname -m)"; exit 1 ;;
esac
say "  macOS $(sw_vers -productVersion) / $(uname -m)"
say "  Terminal.app $(plutil -extract CFBundleShortVersionString raw \
    /System/Applications/Utilities/Terminal.app/Contents/Info.plist 2>/dev/null || echo '?')"
command -v python3 >/dev/null || { warn "需要 python3 来合并描述文件"; exit 1; }

mkdir -p "$HOME/.local/bin" "$HOME/.local/share/zsh" "$HOME/.config/zsh" "$THEMES_DIR"

fetch() {  # fetch URL DEST
  if [ "$DRY_RUN" = 1 ]; then printf '   [dry-run] curl -fsSL %s -o %s\n' "$1" "$2"; else
    curl -fsSL --retry 3 --connect-timeout 15 "$1" -o "$2"
  fi
}

# ------------------------------------------------------------------ 1. Starship
step "1/4 提示符：Starship（现成项目）"
STARSHIP_BIN="$HOME/.local/bin/starship"
if [ -x "$STARSHIP_BIN" ]; then
  say "  已安装，跳过（$("$STARSHIP_BIN" --version 2>/dev/null || echo '版本未知')）"
else
  BASEURL="https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}"
  fetch "$BASEURL/$STARSHIP_ASSET"       "$WORK/starship.tar.gz"
  fetch "$BASEURL/$STARSHIP_ASSET.sha256" "$WORK/starship.sha256"
  if [ "$DRY_RUN" = 0 ]; then
    EXPECTED="$(awk '{print $1}' "$WORK/starship.sha256")"
    ACTUAL="$(shasum -a 256 "$WORK/starship.tar.gz" | awk '{print $1}')"
    [ "$EXPECTED" = "$ACTUAL" ] || { warn "校验和不符，已中止"; exit 1; }
    tar xzf "$WORK/starship.tar.gz" -C "$WORK"
    install -m 0755 "$WORK/starship" "$STARSHIP_BIN"
  fi
  say "  已安装 starship ${STARSHIP_VERSION} → $STARSHIP_BIN"
fi

# ------------------------------------------------------------------ 2. zsh 插件
step "2/4 补全与高亮：zsh-autosuggestions / zsh-syntax-highlighting（现成项目）"
install_plugin() {  # install_plugin 仓库 标签 目标目录名
  local repo="$1" tag="$2" dir="$3" dest="$HOME/.local/share/zsh/$3"
  if [ -d "$dest" ]; then say "  已存在 $dir，跳过"; return 0; fi
  fetch "https://codeload.github.com/$repo/tar.gz/refs/tags/$tag" "$WORK/$dir.tar.gz"
  if [ "$DRY_RUN" = 0 ]; then
    mkdir -p "$dest"
    tar xzf "$WORK/$dir.tar.gz" -C "$dest" --strip-components=1
  fi
  say "  已安装 $dir @ $tag → $dest"
}
install_plugin "zsh-users/zsh-autosuggestions" "$AUTOSUGGESTIONS_TAG" "zsh-autosuggestions"
install_plugin "zsh-users/zsh-syntax-highlighting" "$SYNTAX_HIGHLIGHTING_TAG" "zsh-syntax-highlighting"

# ------------------------------------------------------------------ 3. shell 配置
if [ "$NO_SHELL" = 1 ]; then
  step "3/4 壳层配置：已按 --no-shell 跳过"
else
  step "3/4 壳层配置：starship.toml + terminal-kit.zsh + 在 ~/.zshrc 里挂一行"
  act cp "$KIT_DIR/zsh/starship.toml" "$HOME/.config/starship.toml"
  act cp "$KIT_DIR/zsh/terminal-kit.zsh" "$HOME/.config/zsh/terminal-kit.zsh"
  say "  已写入 ~/.config/starship.toml 与 ~/.config/zsh/terminal-kit.zsh"

  if grep -q "mac-terminal-kit" "$HOME/.zshrc" 2>/dev/null; then
    say "  ~/.zshrc 已包含本套配置，跳过追加"
  else
    if [ "$DRY_RUN" = 0 ]; then
      cp "$HOME/.zshrc" "$HOME/.zshrc.bak-mtk-$(date +%Y%m%d%H%M%S)" 2>/dev/null || true
      {
        printf '\n# >>> mac-terminal-kit >>>\n'
        printf '[ -f "$HOME/.config/zsh/terminal-kit.zsh" ] && source "$HOME/.config/zsh/terminal-kit.zsh"\n'
        printf '# <<< mac-terminal-kit <<<\n'
      } >> "$HOME/.zshrc"
    else
      printf '   [dry-run] 在 ~/.zshrc 末尾追加 3 行 source 块（原文件先备份）\n'
    fi
    say "  已追加 source 块到 ~/.zshrc（原文件已备份）"
  fi
fi

# ------------------------------------------------------------------ 4. 描述文件
step "4/4 外观：生成 Terminal.app 描述文件并导入"
make_theme() {  # make_theme 基础配色 描述文件名 输出名
  local base="$1" name="$2" out="$THEMES_DIR/$3"
  if [ "$DRY_RUN" = 1 ]; then
    printf '   [dry-run] make_profile.py --base %s --name %s --out %s\n' "$base" "$name" "$out"
    return 0
  fi
  python3 "$KIT_DIR/tools/make_profile.py" \
    --base "$base" --name "$name" --font "$FONT_PS" --size "$FONT_SIZE" \
    --scrollback "$SCROLLBACK" --out "$out" >/dev/null
  say "  已生成 $(basename "$out")（$name，字体 $FONT_PS $FONT_SIZE pt，回滚 $SCROLLBACK 行）"
  if [ "$NO_OPEN" = 0 ]; then
    act open -a Terminal "$out"
    say "  已交给 Terminal 导入（会弹出新窗口，说明描述文件生效）"
  fi
}
make_theme "$KIT_DIR/assets/tokyonight-storm.base.terminal" "$DARK_NAME"  "$DARK_NAME.terminal"
if [ "$WITH_LIGHT" = 1 ]; then
  make_theme "$KIT_DIR/assets/catppuccin-latte.base.terminal" "$LIGHT_NAME" "$LIGHT_NAME.terminal"
fi

# ------------------------------------------------------------------ 收尾
step "完成"
cat <<EOF
接下来只差两步（Terminal 没有可脚本化的「设为默认」，只能点）：

  1) 设为默认外观：Terminal → 设置（⌘,）→ 描述文件 → 选中 "$DARK_NAME"
     → 左下角齿轮 → 「设为默认」
  2) 新开一个窗口（⌘N）看效果；不想要就 ⌘, 换回 "Basic"

回滚全部改动：  ./uninstall.sh
快捷键速查表：  CHEATSHEET.md
EOF
