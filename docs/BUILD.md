# 构建与验证

## 项目结构

- `src/`：离线前端与四套 UI、内置背景、图标。
- `macos/App.swift`：macOS 原生窗口、文件选择、数据存储桥接。
- `desktop/`：Electron 主进程、隔离预加载桥接与存储验证。
- `scripts/`：检查与打包脚本。

## 本地预览

安装 Node.js 24+ 和 npm：

```sh
npm install
npm run check
npm start
```

也可以用本地 HTTP 服务预览 `src/`，浏览器版使用 IndexedDB，与桌面版存储分开。不要将自己的书架备份加入源码仓库。

## macOS 原生包

要求 macOS 13+、Apple Silicon、带 macOS SDK 的 Xcode / 开发工具、Python 3.11+。脚本使用当前主机架构编译，因此发布 arm64 包时必须在 Apple Silicon 主机运行。

```sh
python3 scripts/build_mac.py
# 输出 dist/静读.app
```

脚本构建临时 App、复制资源、临时签名并验证签名。发布商店或公证版本需自行配置 Apple 开发者证书与公证，当前仓库不包含任何证书。

## Windows x64 便携包

可以在 Mac / Linux / Windows 上使用 Python 3.11+ 打包：

```sh
python3 scripts/build_windows.py
```

脚本下载指定版本官方 Electron x64 Windows 运行库和 SHA256 校验表，匹配后解压、放入程序、检查 PE 架构，输出 `dist/QuietReader-3.0.0-Windows-x64.zip`。也可提供预先下载的文件：

```sh
python3 scripts/build_windows.py --runtime /path/electron-v45.0.0-win32-x64.zip --checksums /path/SHASUMS256.txt
```

这是一份完整便携文件夹，不是安装器；发布时保留运行库及第三方许可证。打包通过不等同于 Windows 实机测试。

## 检查范围

`node scripts/check.mjs` 检查 JavaScript 语法、DOM 控件引用、章节解析、存储键及路径穿越防护、窗口标题白名单、离线策略、四套 UI 的连接。

人工验证建议：四套界面切换，导入 UTF-8 / GB18030 / UTF-16，长章节自动滚动与续章，书签跳转，备份恢复，重启恢复，窄窗口，全屏，摸鱼快捷键及失焦隐藏。Windows 需在目标电脑完成这些项目。

## 安全边界

阅读内容通过文本节点渲染。Electron 关闭 Node 集成，启用 context isolation 和 sandbox；IPC 限定当前主框架与固定操作；原生数据桥限制 books/prefs 目录和键名。前端 CSP 禁止远程连接、外部脚本和对象，Electron 拒绝远程导航与新窗口。读取数据不依赖联网。

当前数据是本地明文 JSON，不提供加密、密码保护或云同步。请不要把敏感数据当作已加密内容保存。
