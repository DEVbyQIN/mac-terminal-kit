#!/usr/bin/env python3
"""把社区配色（iTerm2-Color-Schemes 的 .terminal）合成为带字体/回滚设置的
Terminal.app 描述文件。

为什么需要它：.terminal 文件本身就是「描述文件」的 plist，但社区版只含配色，
不含字体、回滚行数、Option-as-Meta 这些设置；而这几项恰好是「用起来更顺手」
的部分。这个小脚本只做字段拼接，不发明任何新格式。

用法：
    python3 make_profile.py --base assets/tokyonight-storm.base.terminal \
        --name "Qin-Dark" --font SFMono-Regular --size 13 --scrollback 50000 \
        --out terminal/Qin-Dark.terminal
"""
from __future__ import annotations

import argparse
import plistlib
import sys


def font_archive(postscript_name: str, size: float) -> bytes:
    """生成与 Terminal.app 自身一致的 NSKeyedArchiver(NSFont) 数据。

    结构与系统自带描述文件里的 Font 字段逐键对齐：
        $objects = [$null, {NSSize, NSfFlags, NSName(UID2), $class(UID3)},
                    <PostScript 名>, {$classes, $classname}]
    """
    archive = {
        "$version": 100000,
        "$archiver": "NSKeyedArchiver",
        "$top": {"root": plistlib.UID(1)},
        "$objects": [
            "$null",
            {
                "$class": plistlib.UID(3),
                "NSName": plistlib.UID(2),
                "NSSize": float(size),
                "NSfFlags": 16,
            },
            postscript_name,
            {"$classes": ["NSFont", "NSObject"], "$classname": "NSFont"},
        ],
    }
    return plistlib.dumps(archive, fmt=plistlib.FMT_BINARY, sort_keys=True)


def build_profile(base: dict, name: str, font: str, size: float,
                  scrollback: int, rows: int, cols: int) -> dict:
    profile = dict(base)  # 配色、选中色、光标色等全部沿用上游
    profile.update(
        {
            "name": name,
            "type": "Window Settings",
            "ProfileCurrentVersion": 2.07,
            # 字体：终端默认字体族是 SF Mono；换成别的字体只改 --font 的 PostScript 名
            "Font": font_archive(font, size),
            "FontAntialias": True,
            "FontHeightSpacing": 1.0,
            "FontWidthSpacing": 1.0,
            # 回滚：够用即可，避免「限制为可用内存」在大输出时吃内存
            "ShouldLimitScrollback": True,
            "ScrollbackLines": int(scrollback),
            # 让 Option 当 Meta 用：⌥← / ⌥→ / ⌥D / ⌥⌫ 才能在 zsh 里按词操作
            "useOptionAsMetaKey": True,
            "CursorBlink": True,
            "rowCount": int(rows),
            "columnCount": int(cols),
        }
    )
    return profile


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--base", required=True, help="社区配色的 .terminal 文件")
    ap.add_argument("--name", required=True, help="新描述文件显示名")
    ap.add_argument("--font", default="SFMono-Regular", help="字体 PostScript 名")
    ap.add_argument("--size", type=float, default=13.0, help="字号")
    ap.add_argument("--scrollback", type=int, default=50000, help="回滚行数上限")
    ap.add_argument("--rows", type=int, default=36)
    ap.add_argument("--cols", type=int, default=100)
    ap.add_argument("--out", required=True, help="输出的 .terminal 路径")
    args = ap.parse_args()

    with open(args.base, "rb") as fh:
        base = plistlib.load(fh)
    if not isinstance(base, dict) or "BackgroundColor" not in base:
        print(f"错误：{args.base} 看起来不是 Terminal.app 描述文件", file=sys.stderr)
        return 2

    profile = build_profile(base, args.name, args.font, args.size,
                            args.scrollback, args.rows, args.cols)
    with open(args.out, "wb") as fh:
        plistlib.dump(profile, fh, fmt=plistlib.FMT_XML, sort_keys=True)
    print(f"已生成 {args.out}（{args.name}，字体 {args.font} {args.size}pt，"
          f"回滚 {args.scrollback} 行）")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
