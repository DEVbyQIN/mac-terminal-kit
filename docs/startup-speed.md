# 为什么开窗慢：conda hook 与 nvm.sh，以及懒加载改法

> 本文是 [README](../README.md) 里「开个终端要等 4 秒」那一条的完整版：怎么测、改了什么、代价是什么、怎么回滚。
> 所有数字都在一台 **Intel MacBook Pro 2017（i5-7267U）/ macOS 13.7.1** 上实测。

## 1. 先定位，别猜

```bash
# 总耗时
/usr/bin/time -p zsh -i -c exit

# 分段：把 /etc/zshenv、~/.zshrc 里可疑的行逐段包进 /usr/bin/time
/usr/bin/time -p /opt/anaconda3/bin/conda shell.zsh hook >/dev/null
/usr/bin/time -p zsh -f -c 'export NVM_DIR=$HOME/.nvm; . $NVM_DIR/nvm.sh'
```

实测结果：

| 每次开窗都在跑 | 耗时 |
|---|---|
| `conda shell.zsh hook`（`conda init` 块的核心） | **2.1s**（其中 hook 文本生成 ~1.45s，末尾那句 `conda activate base` 更贵） |
| `source ~/.nvm/nvm.sh` | **1.1s** |
| 其余（uv / rustup / 提示符 / 插件） | ~0.3s |

## 2. 改法：把成本挪到真正用的时候

两段都改成「开窗只挂 PATH，用到才加载」。

### conda

```zsh
export PATH="/opt/anaconda3/bin:$PATH"      # 0.01s：python/pip 立刻可用

_conda_hook_cache="$HOME/.cache/conda/zsh-hook.zsh"
_conda_full_init() {                        # 只有 activate/deactivate 才走这里
  unset -f _conda_full_init
  if [[ -s "$_conda_hook_cache" && ! /opt/anaconda3/bin/conda -nt "$_conda_hook_cache" ]]; then
    source "$_conda_hook_cache" && return 0
  fi
  # 生成缓存，并去掉末尾的 `conda activate base`（激活哪个环境由你显式决定）
  if mkdir -p "${_conda_hook_cache:h}" 2>/dev/null \
     && /opt/anaconda3/bin/conda shell.zsh hook 2>/dev/null | sed '$d' >| "$_conda_hook_cache" 2>/dev/null \
     && [[ -s "$_conda_hook_cache" ]] && source "$_conda_hook_cache"; then
    return 0
  fi
  eval "$(/opt/anaconda3/bin/conda shell.zsh hook 2>/dev/null)"   # 缓存不可用时回退
}
conda() {
  case "$1" in
    activate|deactivate) [[ -n "${__CONDA_HOOK_LOADED-}" ]] && { command conda "$@"; return; }
                         export __CONDA_HOOK_LOADED=1; _conda_full_init && conda "$@" ;;
    *) command conda "$@" ;;            # 普通子命令直接用二进制
  esac
}
```

### nvm

```zsh
export NVM_DIR="$HOME/.nvm"
_alias="$(cat "$NVM_DIR/alias/default" 2>/dev/null)"
_c="("$NVM_DIR"/versions/node/v${_alias:-*}/bin(N))"
(( ${#_c} )) && export PATH="${_c[-1]}:$PATH"        # 0.08s：默认 node 立即可用
unset _alias _c
nvm() { unset -f nvm; . "$NVM_DIR/nvm.sh" && nvm "$@"; }
```

## 3. 效果

| 指标 | 改前 | 改后 |
|---|---|---|
| `zsh -i -c exit` | 4.3–5.8s | **0.09–0.25s** |
| 登录 shell `zsh -l -i -c exit` | 同上 | **0.21s** |

功能验证（都在改后实测通过的）：

```
node=v24.19.0  pnpm=11.21.0  python=3.12.2  starship=zsh
conda --version      → 24.11.3
conda activate base  → CONDA_DEFAULT_ENV=base，python 指向 /opt/anaconda3
nvm --version        → 0.40.3
```

## 4. 代价（按需发生）

| 操作 | 耗时 | 说明 |
|---|---|---|
| `conda activate` 首次 | 5.5s | 生成 hook 缓存 |
| `conda activate` 之后 | 2.0s | source 缓存 hook |
| `conda` 普通子命令 | ~1.9s | conda 二进制自身在这台 Intel 机器上的启动开销，改不掉 |

如果你固定只用某个环境，可以进一步省掉 activate 的 2 秒：直接把该环境的
`bin` 与 `CONDA_PREFIX` 写进 `~/.zshrc`，不用 `conda activate`。

## 5. 怎么回滚

```bash
# 方式一：恢复原文件（本仓库安装器会生成带时间戳的备份）
cp ~/.zshrc.bak-speedfix-<时间戳> ~/.zshrc

# 方式二：删掉懒加载块，让 conda 重新生成官方块
/opt/anaconda3/bin/conda init zsh
```

## 6. 其它可选优化（本次未做）

- **nvm 换成 mise**：`mise` 能同时管 node/python，启动开销更低；但本机已有 conda + nvm，三套并存是坑，不建议。
- **把 `~/.zsh_history` 换成 SQLite 方案**（如 `atuin`）：历史检索更强，但会接管 `⌃R`，与 fzf 冲突。
