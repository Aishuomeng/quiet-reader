# 静读 · Quiet Reader

一个离线、开源的桌面 TXT 小说阅读器。全窗口背景，四套完整界面，在自己的节奏里读完一个故事。

[下载发行包](https://github.com/aishuomeng/quiet-reader/releases) · [使用指南](docs/USER_GUIDE.md) · [构建说明](docs/BUILD.md) · [更新记录](CHANGELOG.md)

## 四套 UI

| 套装 | 风格 | 适合的场景 |
| --- | --- | --- |
| 标准版 · 山居 | 山湖全景、深色半透明阅读面板 | 日常阅读、沉浸阅读 |
| 二次元版 · 樱语 | 海边晚霞、樱花、柔和紫粉玻璃面板 | 温柔明亮的阅读空间 |
| 科技版 · 轨道 | 深蓝网格、青色线条、方形控件 | 喜欢简洁科技感的读者 |
| 摸鱼版 · 工作台 | 绿色工具栏、表格行样式、一键隐藏正文 | 希望降低界面存在感的读者 |

顶部「主题套装」按钮可以随时切换。每套都有配套书架、目录、设置、按钮和弹窗；书籍、书签和阅读进度共用。切换套装会载入该套装推荐外观，重新选择自定义图片即可继续调整。

## 界面预览

| 标准版 | 二次元版 |
| --- | --- |
| ![标准版](docs/images/standard.png) | ![二次元版](docs/images/anime.png) |
| 科技版 | 摸鱼版 · 隐藏正文 |
| ![科技版](docs/images/tech.png) | ![摸鱼版](docs/images/stealth.png) |

## 阅读功能

- 导入或拖入 TXT；支持 UTF-8、GB18030、带 BOM 的 UTF-16 文本，单本最多 30 MB。
- 自动识别常见中文章节标题及 Chapter / Book / Part 标题，目录和正文搜索。
- 字号、字体、行距、正文宽度、文字颜色；自选背景、缩放、位置、明暗、模糊、面板透明度。
- 平滑自动滚动、速度调节、自动续章；手动滚动或离开窗口时暂停。
- 书签、阅读位置自动保存，书架 JSON 备份与恢复。
- 原生桌面窗口、全屏与专注模式；无需账号，无需服务器，不发送阅读数据。

## 下载与打开

- **macOS Apple Silicon**：解压 `QuietReader-3.0.0-macOS-arm64.zip`，打开「静读.app」。也可以拖到「应用程序」，并将替身放到桌面。本地构建采用临时签名，尚未获得 Apple 公证。
- **Windows 10 / 11 x64 预览版**：完整解压 `QuietReader-3.0.0-Windows-x64.zip`，双击 `QuietReader.exe`。运行包内「Create Desktop Shortcut.cmd」可创建桌面快捷方式，也可以右键创建。不要只复制 EXE；它需要旁边的运行库。

Windows 包已校验官方 Electron 运行库 SHA256、x64 可执行文件和包内资源，但尚未经过 Windows 实机运行验证，也没有发布者代码签名。请通过 Releases 中的 SHA256SUMS.txt 核对下载。

## 数据与隐私

macOS 原生版的数据保存在 `~/Library/Application Support/QuietReader/`；Windows 在 `%APPDATA%\QuietReader\`。不会随源码或发行包上传。通过书架「导出备份」可迁移电脑；恢复会追加书籍，保留现有书架。

摸鱼模式只是界面隐藏功能，不是安全隔离或加密功能。它不会控制系统截图、录屏或其他程序。

## 开发

```sh
npm install
npm run check
npm start
```

Electron 固定为 45.0.0。Mac 发行包使用 AppKit + WKWebView，Windows 发行包使用 Electron；两者共用相同前端。详细环境和打包命令见 [BUILD.md](docs/BUILD.md)。

## 开源许可

代码采用 [MIT License](LICENSE)。示例小说为本项目原创示例，随项目开放使用；背景为本项目生成的原创视觉素材，来源见 [ASSETS.md](docs/ASSETS.md)。Electron 和 Chromium 的第三方许可证保留在 Windows 发行包中。导入小说的版权归各自权利人所有。
