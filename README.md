# Manic EMU - 多平台复古游戏模拟器 (CN)

[![AGPLv3 License](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

Manic EMU 是基于iOS平台的模块化游戏模拟器解决方案，采用Swift架构实现高性能多平台模拟，具备优雅的现代用户界面设计。项目严格遵循AGPLv3开源协议，开发者引用代码时需特别注意协议合规性要求。

## 核心特性

### 模拟器基础架构
- 多核心支持：整合 VBA-M (GBA)、Nestopia (NES)、Snes9x (SNES)、Gambatte (GB/GBC)、melonDS (NDS)、Cytrus (3DS) 等模拟器核心
- DeltaCore 中间层：实现统一输入管理、渲染管道、存档系统及皮肤框架
- 预编译依赖：VBA-M/Nestopia/Snes9x/Gambatte（稳定版二进制）
- 源码级集成：melonDS 和 Cytrus（需参考官方编译指南）

### 用户交互系统
- 动态触感
- 自适应屏幕旋转布局
- 支持压感触控动态效果的皮肤
- AirPlay投屏

### 数据管理系统
- 游戏库（支持封面元数据自定义）
- 多端同步方案（iCloud）
- 存档管理工具（即时存档/读档/导出）

### 功能套件
- 滤镜系统（基于Core Image框架）
- 金手指
- 倍速
- 外设支持

## 数据交互协议
- **导入协议**：WiFi传输/剪贴板解析/WebDAV/SMB/Drag&Drop
- **压缩格式**：7z/ZIP/RAR（libarchive实现）
- **云服务**：百度云/阿里云/iCloud Drive/Google Drive/Dropbox/OneDrive

## 开发注意事项
1. **编译环境**：Xcode 15+ / iOS SDK 15+ / Swift 5.9+
2. **协议合规**：二次开发必须保持AGPLv3协议继承性

## 致谢声明
本项目构建于众多优秀开源项目之上，正因为有这些开源项目才让Manic EMU诞生：
- 模拟器核心开发团队
- 框架支持：DeltaCore的架构设计
- 工具链：RetroArch社区的技术积累
- 其他依赖项：见SPM、Podfile清单



# Manic EMU - Multi-Platform Retro Game Emulator

[![AGPLv3 License](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

**Manic EMU** is a modular game emulator solution designed for the iOS platform. Built with Swift, it delivers high-performance, multi-platform emulation combined with a sleek, modern user interface. The project is strictly licensed under the **AGPLv3**, so developers must ensure full compliance when using or modifying the code.

## Core Features

### Emulator Architecture
- **Multi-Core Support**: Integrated emulator cores include VBA-M (GBA), Nestopia (NES), Snes9x (SNES), Gambatte (GB/GBC), melonDS (NDS), and Cytrus (3DS)
- **DeltaCore Middleware**: Provides unified input management, rendering pipeline, save system, and skin framework
- **Precompiled Dependencies**: Stable binaries for VBA-M, Nestopia, Snes9x, and Gambatte
- **Source-Level Integration**: melonDS and Cytrus must be compiled according to their official build guides

### User Interaction System
- Haptic feedback
- Adaptive screen rotation layouts
- Pressure-sensitive skin effects
- AirPlay streaming support

### Data Management System
- Game Library (with customizable cover metadata)
- Cross-device sync via iCloud
- Save state management (instant save/load/export)

### Feature Suite
- Filter system (powered by Core Image)
- Cheat code support
- Fast-forward gameplay
- Peripheral compatibility

## Data Exchange Protocols
- **Import Methods**: WiFi transfer, clipboard parsing, WebDAV, SMB, Drag & Drop
- **Compression Formats**: 7z, ZIP, RAR (via libarchive)
- **Cloud Services**: iCloud Drive, Google Drive, Dropbox, OneDrive, BaiduYun, AliYun

## Development Notes
1. **Build Environment**: Requires Xcode 15+, iOS SDK 15+, and Swift 5.9+
2. **License Compliance**: All derivative works must retain AGPLv3 licensing

## Acknowledgements
This project is made possible by the contributions of many outstanding open-source projects:
- Developers of the emulator cores
- Architectural design of DeltaCore
- Toolchain support from the RetroArch community
- Additional dependencies (see `SPM` and `Podfile` listings)
