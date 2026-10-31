# mac-terminal-kit —— 壳层增强（纯增量，整段可删）
#
# 回滚：删掉本文件，并删除 ~/.zshrc 里 "# >>> mac-terminal-kit >>>" 到
#       "# <<< mac-terminal-kit <<<" 之间的三行即可，其它配置不受影响。
#
# 依赖（install.sh 会装到 ~/.local 下，不需要 sudo）：
#   ~/.local/bin/starship                          提示符（现成项目 Starship）
#   ~/.local/share/zsh/zsh-autosuggestions         灰字自动补全
#   ~/.local/share/zsh/zsh-syntax-highlighting     命令语法高亮

# ---------------------------------------------------------------- 历史与行编辑
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY        # 历史里记时间戳
setopt HIST_IGNORE_ALL_DUPS    # 命令重复只留最后一次
setopt HIST_REDUCE_BLANKS      # 去掉多余空白
setopt HIST_VERIFY             # `!$` 之类先展开给你确认再执行
setopt SHARE_HISTORY           # 多个窗口共享历史
setopt AUTO_CD                 # 直接输目录名就 cd 过去
setopt INTERACTIVE_COMMENTS    # 交互 shell 里允许 # 注释

bindkey -e                       # 用 emacs 键位（macOS 默认习惯）
bindkey '^[[H'     beginning-of-line     # Home
bindkey '^[[F'     end-of-line           # End
bindkey '^[[1;3D'  backward-word         # Option-←  按词后退
bindkey '^[[1;3C'  forward-word          # Option-→  按词前进
bindkey '^[[1;5D'  backward-word         # Ctrl-←
bindkey '^[[1;5C'  forward-word          # Ctrl-→
bindkey '^R'       history-incremental-search-backward  # Ctrl-R 反查历史

# ---------------------------------------------------------------- 提示符
if command -v starship >/dev/null 2>&1; then
  export STARSHIP_CONFIG="$HOME/.config/starship.toml"
  eval "$(starship init zsh)"
elif [ -x "$HOME/.local/bin/starship" ]; then
  export STARSHIP_CONFIG="$HOME/.config/starship.toml"
  eval "$("$HOME/.local/bin/starship" init zsh)"
fi

# ---------------------------------------------------------------- 灰字补全 + 语法高亮
# 注意：zsh-syntax-highlighting 必须最后加载，否则高亮会被后面的 widget 覆盖
ZSH_KIT_SHARE="$HOME/.local/share/zsh"
if [ -r "$ZSH_KIT_SHARE/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$ZSH_KIT_SHARE/zsh-autosuggestions/zsh-autosuggestions.zsh"
  # 补全来源：历史（默认行为，这里显式写出来方便改）
  ZSH_AUTOSUGGEST_STRATEGY=(history)
fi
if [ -r "$ZSH_KIT_SHARE/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source "$ZSH_KIT_SHARE/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# ---------------------------------------------------------------- 顺手别名（只影响交互）
alias ll='ls -lahG'
alias la='ls -lahG'
alias l='ls -lahG'
alias ..='cd ..'
alias ...='cd ../..'
