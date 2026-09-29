# 测试记录 — 2026-09-29

## 自动化

- SIM Station XCTest：19 项通过，0 失败。
- 覆盖默认未连接、白名单/命令注入拦截、短信/拒接确认、CLCC、陈旧/多路来电拦截、脱敏、CSQ、SIM、坏 PDU、Unicode/Emoji 编码、多段编码、URC 分片、模拟超时与构造时不打开设备。
- 上游 Swift 自测通过：calls、PDU/UDH、CMGL/URC、buffering、storage、merge。
- 上游 CUACProbe 内存环形缓冲、Float32/PCM16、flush 自测通过；仅算法，不是实际音频验证。
- 上游 CModemBridge 生命周期/空闲读取中断自测通过；未打开真实 USB。

首轮 C 测试遭遇 CommandLineTools macOS 27 SDK 与 Xcode 链接器不匹配；显式指定 Xcode Developer/SDKROOT 后全部通过，未修改系统全局选择器。

## 构建与运行

- SwiftPM GUI target 构建通过，使用原生 SwiftUI/AppKit。
- Info.plist 校验、本地 ad-hoc 签名校验通过。
- 应用 bundle 启动和进程存在检查通过；默认监听关闭。
- 原生界面检查工具返回 `Sky Computer Use native pipe closed before response`；未完成自动点击/截图视觉验收。

## 未执行的实机项目

设备识别、热插拔、真实来电、拒接、真实短信读取、eUICC 卡片、麦克风/扬声器双向音频、长时间锁屏、SIM 更换均未在此版本实测。
没有拨号、发送/删除短信、安装模块组件、改变 Wi-Fi/4G/系统网络，也没有停止 4G Bridge。
