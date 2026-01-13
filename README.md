# Imagic - 动态魔术引擎 (Dynamic Magic Engine)

本项目是一个基于 Flutter 开发的 Windows/iOS 跨平台魔术应用，支持高度自定义的魔术流程。

## 🔴 常见问题：无法识别 'flutter'

如果你在运行命令时遇到类似以下错误：
```
flutter : 无法将“flutter”项识别为 cmdlet...
```
这说明你的电脑上尚未安装 **Flutter SDK** 或者它没有被添加到系统环境变量 (PATH) 中。

---

## 🚀 快速开始 (环境配置)

### 1. 安装 Flutter SDK
1.  前往 [Flutter 官网](https://flutter.cn/docs/get-started/install/windows) 下载 Windows 版 SDK。
2.  解压到非系统盘目录（例如 `C:\src\flutter`）。
3.  **关键步骤**：将 `flutter\bin` 目录的完整路径添加到你的 **系统环境变量 Path** 中。
    *   *搜索 "编辑系统环境变量" -> "环境变量" -> "系统变量" -> Path -> 新建 -> 粘贴路径*。

### 2. 安装 Windows 开发环境
要在 Windows 上运行此应用，你需要：
1.  **开启开发者模式 (Developer Mode)**：
    *   Windows 10/11 要求开启此模式以支持软链接 (symlinks)。
    *   打开系统设置 -> 隐私和安全性 -> 开发者选项 -> 开启 "开发人员模式"。
2.  **安装 Visual Studio 2022** (不是 VS Code)：
    *   下载 Visual Studio Community 2022。
    *   安装时勾选 **"使用 C++ 的桌面开发"** (Desktop development with C++) 工作负载。

### 3. 运行应用
环境配置好后，在本项目根目录下打开终端 (PowerShell/CMD)：

```bash
# 1. 检查环境 (确保全绿)
flutter doctor

# 2. 获取依赖
flutter pub get

# 3. 运行 (Windows 模式)
flutter run -d windows
```

---

## 📖 功能说明
*   **默认流程**：三击出现 -> 长按变牌 -> 吹气消失。
*   **设置模式**：在主界面**单指快速上滑**，进入流程编辑器。
*   **资源文件**：支持直接加载本地图片和视频，配置会自动保存。
