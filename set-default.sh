#!/usr/bin/env bash
# 把指定描述文件设为「新窗口的默认外观」。
#
# 前置条件：macOS 需要先给「自动化」授权（系统设置 → 隐私与安全性 → 自动化），
# 否则 osascript 会报 -10004 权限违例 —— 这也是为什么 install.sh 不自动做这一步。
#
# 用法：./set-default.sh [描述文件名]，默认 Qin-Dark
set -euo pipefail

PROFILE="${1:-Qin-Dark}"

manual() {
  cat <<EOF
自动化授权不可用，改用手动两步（10 秒）：
  1) Terminal → 设置（⌘,）→ 描述文件 → 选中 "$PROFILE"
  2) 左下角齿轮 → 「设为默认」
EOF
}

if ! out=$(osascript -e "tell application \"Terminal\" to set default settings to settings set \"$PROFILE\"" 2>&1); then
  manual
  exit 1
fi
osascript -e "tell application \"Terminal\" to set startup settings to settings set \"$PROFILE\"" >/dev/null 2>&1 || true
# 已开着的窗口也一起换（失败不影响默认设置）
osascript -e "tell application \"Terminal\" to set current settings of every window to settings set \"$PROFILE\"" >/dev/null 2>&1 || true

echo "已把 \"$PROFILE\" 设为新窗口/启动时的默认外观。"
echo "当前已打开的窗口（能改的都改了）也切换过去了；⌘N 新开一个窗口确认效果。"
