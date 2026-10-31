#!/usr/bin/env bash
# mac-terminal-kit —— 卸载脚本：撤销 install.sh 的全部改动
#
# 会做：
#   1. 删除 ~/.local/bin/starship
#   2. 删除 ~/.local/share/zsh/{zsh-autosuggestions,zsh-syntax-highlighting}
#   3. 删除 ~/.config/zsh/terminal-kit.zsh 与 ~/.config/starship.toml
#   4. 从 ~/.zshrc 删除 "# >>> mac-terminal-kit >>>" 到 "# <<< mac-terminal-kit <<<" 的块
#
# 不会做（需要手动）：
#   * Terminal 里已导入的描述文件："Qin-Dark" 等请在 设置 → 描述文件 里手动删除
#   * 备份文件 ~/.zshrc.bak-mtk-* 保留不动，确认无误后可自行删除
set -euo pipefail

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

act() { if [ "$DRY_RUN" = 1 ]; then printf '   [dry-run] %s\n' "$*"; else "$@"; fi; }
step() { printf '\n\033[1m== %s\033[0m\n' "$*"; }

step "删除 ~/.local 下的文件"
for p in "$HOME/.local/bin/starship" \
         "$HOME/.local/share/zsh/zsh-autosuggestions" \
         "$HOME/.local/share/zsh/zsh-syntax-highlighting" \
         "$HOME/.config/zsh/terminal-kit.zsh" \
         "$HOME/.config/starship.toml"; do
  if [ -e "$p" ]; then
    act rm -rf "$p"
    if [ "$DRY_RUN" = 1 ]; then printf '   [dry-run] 将删除 %s\n' "$p"; else printf '   已删除 %s\n' "$p"; fi
  else
    printf '   不存在，跳过 %s\n' "$p"
  fi
done

step "从 ~/.zshrc 删除 source 块"
if grep -q "mac-terminal-kit" "$HOME/.zshrc" 2>/dev/null; then
  if [ "$DRY_RUN" = 0 ]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.bak-mtk-uninstall-$(date +%Y%m%d%H%M%S)"
    python3 - "$HOME/.zshrc" <<'PY'
import re, sys
path = sys.argv[1]
src = open(path, encoding="utf-8").read()
out = re.sub(r"\n?# >>> mac-terminal-kit >>>.*?# <<< mac-terminal-kit <<<\n?",
             "\n", src, flags=re.S)
open(path, "w", encoding="utf-8").write(out)
PY
  fi
  printf '   已移除配置块（原文件已备份）\n'
else
  printf '   ~/.zshrc 里没有本套配置，跳过\n'
fi

step "完成"
cat <<'EOF'
已撤销安装。还剩一件手动的事：
  Terminal → 设置 → 描述文件 → 删除 "Qin-Dark" / "Qin-Light"（如已导入）
当前已经打开的窗口会继续用旧描述文件，新开窗口即恢复默认外观。
EOF
