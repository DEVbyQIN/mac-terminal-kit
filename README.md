# mac-terminal-kit

> 把 macOS **自带的 Terminal.app** 调成「看着舒服、选得动大段输出、开窗只要 0.2 秒」。
> 不换终端模拟器，不写新软件：只做配置胶水，全部建立在现成项目之上。

```bash
git clone https://github.com/<you>/mac-terminal-kit.git
cd mac-terminal-kit
./install.sh --dry-run    # 先看它要做什么
./install.sh              # 装（只写 ~/.local 与 ~/.config，不需要 sudo）
```

---

## 它解决什么

| 常见抱怨 | 本项目的做法 |
|---|---|
| 「选中一大段输出好难」 | 用 Terminal 自带的**标记（Marks）**：`⇧⌘A` 直接选中上一条命令的整段输出；`⌘↑/⌘↓` 在命令之间跳 |
| 「终端不好看」 | 社区 `.terminal` 配色（TokyoNight Storm / Catppuccin Latte）+ 可调字号、回滚 5 万行、Option-as-Meta |
| 「提示符太素」 | [Starship](https://github.com/starship/starship) 单文件配置：目录 / git 分支状态 / 命令耗时，**不依赖 Nerd Font 图标** |
| 「记不住快捷键」 | [CHEATSHEET.md](CHEATSHEET.md)：从 Apple 官方手册提炼的高频键位 |
| 「开个终端要等 4 秒」 | 附带 conda / nvm **懒加载**方案（实测 4.5s → 0.15s），见 [docs/startup-speed.md](docs/startup-speed.md) |

---

## 组成

```
mac-terminal-kit/
├── install.sh                  # 安装（幂等；--dry-run / --no-open / --no-shell / --with-light）
├── uninstall.sh                # 回滚（含从 ~/.zshrc 摘除配置块）
├── set-default.sh              # 把描述文件设为默认（需「自动化」授权，失败给手动步骤）
├── CHEATSHEET.md               # 快捷键速查
├── docs/startup-speed.md       # conda/nvm 懒加载：原理、实测、回滚
├── assets/                     # 上游配色原件（保留出处，便于换主题）
│   ├── tokyonight-storm.base.terminal
│   └── catppuccin-latte.base.terminal
├── tools/make_profile.py       # 把「配色 + 字体 + 回滚行数」合成 .terminal 描述文件
├── zsh/
│   ├── starship.toml           # 克制版提示符（无图标依赖）
│   └── terminal-kit.zsh        # 历史策略 / 键位 / 加载两个插件 / 别名
└── terminal/Qin-Dark.terminal  # 预生成的深色描述文件（也可直接双击导入）
```

安装后落到机器上的东西（**只有这些**）：

| 路径 | 是什么 |
|---|---|
| `~/.local/bin/starship` | 官方 Release 二进制，SHA-256 校验 |
| `~/.local/share/zsh/{zsh-autosuggestions,zsh-syntax-highlighting}` | 插件官方 tag 源码（纯 zsh，无编译） |
| `~/.config/starship.toml`、`~/.config/zsh/terminal-kit.zsh` | 提示符与壳层配置 |
| `~/.zshrc` 末尾 3 行 `source` 块 | 唯一动到既有配置的地方，原文件带时间戳备份 |
| Terminal 描述文件 | 只进 Terminal 自己的设置，不动系统 |

---

## 常用参数

```bash
./install.sh --dry-run                    # 预演，不写任何文件
./install.sh --no-open                    # 生成描述文件但不弹窗导入
./install.sh --no-shell                   # 只改外观，不动 ~/.zshrc
./install.sh --with-light                 # 额外生成浅色描述文件
./install.sh --dark-name "My Dark" --light-name "My Light" --with-light
./install.sh --font "SFMono-Regular" --size 13 --scrollback 50000
```

> **描述文件名 = 文件名**：Terminal 导入 `.terminal` 时用文件名当描述文件名，文件内的
> `name` 字段会被忽略。所以 `Qin-Dark.terminal` 导入后就叫 `Qin-Dark`；想换名字就改文件名再导入。

## 设为默认外观

```bash
./set-default.sh              # 需要 macOS「自动化」授权；没授权会打印手动步骤
```

手动等价操作：Terminal → 设置（⌘,）→ 描述文件 → 选中 → 左下角齿轮 → 「设为默认」。

---

## 回滚

```bash
./uninstall.sh            # 删掉装入的文件、从 ~/.zshrc 移除配置块
./uninstall.sh --dry-run
```

Terminal 里已导入的描述文件需在设置里手动删；`~/.zshrc.bak-mtk-*` 系列备份保留不动。

---

## 已知边界（先看这里，避免白折腾）

Terminal.app 2.x（macOS 13 及更早）**做不到**：

- 24-bit 真彩（`termstandard/colors` 记为 *since macOS 26*）→ 主题只保证 16 色安全
- 字体连字（ligature）
- **选中即复制**（copy-on-select）：选完必须 ⌘C
- **选中后按删除键删掉选区**：终端里「屏幕文字」和「输入行」分属终端与 shell 两层，这是终端类通病，不是本项目的缺陷
- OSC 52（程序直接写系统剪贴板）→ tmux 里 yank 要用 `copy-pipe "pbcopy"`
- 普通点击移动输入光标（必须 `⌥` + 点击，且只在当前输入行内）

---

## 依赖与兼容

- macOS 13 Ventura 实测（Terminal 2.13，Intel MacBook Pro 2017）；需要 `python3`（系统自带）
- 不依赖 Homebrew：macOS 13 在 Homebrew 已是 Tier 3，Intel + Ventura 基本没有预编译 bottle，
  所以 Starship 与插件都直接取官方 Release / tag 源码
- 上游版本固定：Starship `1.27.0`、zsh-autosuggestions `v0.7.1`、zsh-syntax-highlighting `0.8.0`

## 致谢 / 上游项目

- 配色：[mbadolato/iTerm2-Color-Schemes](https://github.com/mbadolato/iTerm2-Color-Schemes)（MIT）
- 提示符：[Starship](https://github.com/starship/starship)（ISC）
- 插件：[zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)（MIT）、
  [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)（BSD-3-Clause）
- 快捷键与能力边界：[Apple 官方《Terminal 键盘快捷键》](https://support.apple.com/guide/terminal/trmlshtcts/2.13/mac/13)

见 [NOTICE.md](NOTICE.md)。

## License

[MIT](LICENSE) © 2026 QIN-SMART
