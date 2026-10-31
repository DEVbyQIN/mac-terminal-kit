# NOTICE

本仓库自身代码以 MIT 发布（见 [LICENSE](LICENSE)）。它**不打包**任何第三方二进制，
安装时按固定版本从上游官方地址下载，或在运行时复用系统组件。

## 运行时下载 / 引用的第三方项目

| 项目 | 用途 | 版本（install.sh 固定） | 许可证 | 来源 |
|---|---|---|---|---|
| [starship](https://github.com/starship/starship) | 提示符 | 1.27.0 | ISC | GitHub Releases（`.sha256` 校验） |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | 灰字补全 | v0.7.1 | MIT | GitHub tag 源码 |
| [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) | 语法高亮 | 0.8.0 | BSD-3-Clause | GitHub tag 源码 |
| Apple Terminal.app | 宿主终端 | macOS 自带 | Apple EULA | 系统 |
| `python3` | 生成描述文件 | 系统自带 | PSF | 系统 |

## 本仓库内的第三方内容

`assets/*.terminal` 是 [mbadolato/iTerm2-Color-Schemes](https://github.com/mbadolato/iTerm2-Color-Schemes)
（MIT，主题版权归各主题作者）中两个配色的**原样副本**，取自 commit `3d8a6a1a983d7fe721aa6cb9a5b98066cd74303a`：

- `assets/tokyonight-storm.base.terminal` ← `terminal/TokyoNight Storm.terminal`
- `assets/catppuccin-latte.base.terminal` ← `terminal/Catppuccin Latte.terminal`

它们只包含颜色定义（背景/前景/16 色 ANSI/光标/选中色），由 `tools/make_profile.py`
叠加字体与窗口设置后生成 `terminal/*.terminal` 供 Terminal.app 导入。
如需替换配色，直接把同格式的文件放进 `assets/` 即可。

## 未包含的内容

- 任何字体文件（若需要中英等宽字体，请自行安装 [Sarasa-Gothic](https://github.com/be5invis/Sarasa-Gothic) 等，
  它们各自有独立许可证，其中 Sarasa-Gothic 采用 SIL OFL 1.1）
- 任何 macOS 系统资源（Terminal.app 的 plist、nib、颜色数据均不复制进仓库）
