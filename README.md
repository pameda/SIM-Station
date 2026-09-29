# SIM Station

独立的原生中文 macOS 本地 SIM 通信网关。**当前为 0.1.0 安全预览版，不是已完成双向通话的正式版本。**

与 4G Bridge、QDC507 iPad Link 分开运行和保存设置；不替换现有应用。

## 下载

[GitHub 预发布安装包、源码与 SHA256](https://github.com/pameda/SIM-Station/releases/tag/v0.1.0-preview)

下载 DMG 后，将 SIM Station 拖入 Applications。仅支持 Apple Silicon Mac 和 macOS 15 或更新版本。
此为未经公证的安全预览版，不要关闭系统安全保护来运行。

## 已实现

- 原生侧栏：通信总览、电话与记录、短信、SIM 与 eSIM、中文运行日志。
- 启动时监听关闭；用户手动开始后，查询 USB 标识、固件、SIM、运营商、信号和 CLCC 通话状态。
- 来电状态显示、内存通话记录、二次确认拒接；执行前再次核对来电，拒绝过期操作。
- 经确认读取模块短信，中文/Unicode/长短信解析，搜索及滚动全文查看；不自动删除或发送。
- eSIM 只读入口。仅凭 CPIN/ICCID 不能识别 eUICC，当前显示“未验证”，不虚构 EID 或 profile 列表。
- 不修改 Wi-Fi、VPN、DNS、4G 开关，不开放网络服务，不要求管理员、麦克风、通讯录、辅助功能或完全磁盘访问。

## 尚未完成

双向语音、拨号/接听、短信发送、系统通讯录、iMessage、加密历史存储、远程手机访问与真实 eUICC 状态读取。
上游的语音组件可能需要模块持久写入，目前不安装、不打包；必须单独审查并取得授权，完成真实通话才能标记可用。
此版本不能用于紧急呼叫，也不能替代现有手机。

## 使用

1. 打开 `dist/SIM Station.app`。菜单栏和主窗口均显示版本。
2. 使用模块前先退出占用同一模块的 4G Bridge/MaVo/DJOneHub/iPad Link。应用不会代你停止它们。
3. 点击“开始监听”。出现错误会停止，不自动重连、重置 USB 或回放命令。
4. 短信页“读取模块短信…”会再次确认。读取可能将模块短信标记为已读，短暂改变短信会话模式；不会发送、转发或删除短信。
5. 停止监听、换卡或退出会清空短信内存。通话记录仅在本次运行中保留，不持久化。

短信读取途中拔出/超时，临时 CMGF/CPMS 状态可能无法恢复；此时不会盲目重开设备写回。下一次读取会重新查询状态。
AT 接口目前限于上游验证过的 interface 2 / bulk 0x84、0x03；不符合的配置会安全失败，不宣称支持所有改装固件。

## 构建与测试

仅使用已安装的 Apple Xcode/Swift 工具链，没有 Swift 第三方依赖下载。

```sh
./script/build_and_run.sh --test
./script/build_and_run.sh --verify
```

Apple Silicon/macOS 15+。本地 ad-hoc 签名，未 Developer ID 签名或公证；其他电脑可能出现 Gatekeeper 提示。
不要关闭 SIP 或全局安全检查。

## 来源与许可

基于社区项目 [MaVo](https://github.com/moluncn/mavo)，固定提交 `0443dfdaf8aec086fd76ba2ee9152fd908114524`。
MIT 许可见 LICENSE，保留原始声明。[上游原始说明](https://github.com/moluncn/mavo/blob/0443dfdaf8aec086fd76ba2ee9152fd908114524/README.md)中的功能并不代表本分支已完成。
`Station/Protocol` 为列明的上游模型/解析器副本；`Sources/CModemBridge` 为上游 USB AT 实现。
应用不使用其 Logo，不携带模块语音二进制。此独立公开仓库只保留构建所需源码，不含原研究仓库的历史、特权安装器或拨号/删短信探针。

构建与测试结果见 TESTING.md，安全边界见 SECURITY.md。
