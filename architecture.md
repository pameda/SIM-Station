# SIM Station — 独立 Mac 本地通信网关

## 本次实现边界

原生 SwiftUI 主窗口、中文侧栏、设备只读检查、可显式启动/停止的来电监听、通话记录、短信读取与全文查看、eSIM 只读状态入口、安全诊断。
程序启动不打开 USB，不读取短信，不修改网络。不替换 4G Bridge 或 iPad Link。

基于 MaVo MIT 源码，固定提交 `0443dfdaf8aec086fd76ba2ee9152fd908114524`。
新产品只编译列明的协议模型/解析器和 C AT transport，不编译上游 AppState、ModemService、ADB、语音安装器、特权网络 helper、拨号/删短信探针。
上游图标和模块语音二进制不进入应用包。保留 MIT 与第三方声明。

## 分层

- Station/App：场景与版本信息。
- Station/Views：原生导航、来电面板、短信全文、卡片状态、诊断。
- Station/Services：串行 USB 事务、严格命令白名单、显式会话生命周期。
- Station/Stores：主线程状态、去重、中文事件记录。
- 历史存储：当前仅内存；AES-GCM、Keychain 和保留策略仍为后续工作，不声称已经实现。
- 复用解析器：ATResponseParser、CallATParser、SMSPDUDecoder、SMSPDUEncoder 及必要模型。

## 安全边界

eSIM 不发送 APDU，不下载/启用/删除 profile；CPIN/ICCID 不能证明 eUICC 能力，界面必须显示“未验证”。
来电监听不等于双向通话；拨号/接听在语音链路未审查和实机验证前不可用。
只读检查有明确的 AT allowlist。短信读取需单独确认，因 CMGF/CPMS 会改变会话设置，CMGL 可能把未读标记为已读；绝不执行 CMGD。
其他管理程序运行或 USB 被占用时停止，不抢占、不重置设备。
模块拔出、AT 超时、睡眠后停止会话，必须重新开始；不能回放旧动作。
不开放网络端口、不变更 DNS/服务顺序/数据开关，不自动发送短信，不记录正文/号码到日志。

## 后续硬件关卡

双向语音需要审查对应固件的音频通道和模块 runtime，再取得独立安装/通话授权。不能因上游存在拨号代码而宣称通话可用。
远程访问、iMessage、4G 接管、通讯录系统权限、自动持久化与 30 天密钥管理不在本次安全预览包中启用。
