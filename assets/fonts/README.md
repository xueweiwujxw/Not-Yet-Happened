# Chapter font

`ChapterSans.otf` is a character subset of Noto Sans CJK SC Regular, licensed under the
SIL Open Font License 1.1 (see `OFL.txt`). Original copyright/name metadata is retained.
Source: https://github.com/notofonts/noto-cjk/blob/main/Sans/OTF/SimplifiedChinese/NotoSansCJKsc-Regular.otf
Upstream SHA-256: `2c76254f6fc379fddfce0a7e84fb5385bb135d3e399294f6eeb6680d0365b74b`.

Rebuild after editing Chinese content, using the optional development tool FontTools:

```bash
cat src/content/chapter_one.gd src/content/chapter_two.gd | pyftsubset /path/to/NotoSansCJKsc-Regular.otf --text-file=/dev/stdin --unicodes=U+0020-007E --output-file=assets/fonts/ChapterSans.otf
```

Runtime needs no Python or system CJK fonts. Tests check glyph coverage for chapter content.
The command above uses a POSIX shell. The subset covers both implemented chapters, not arbitrary
future Chinese text. Font subsetting is a development step; all four game platforms use the result.
