import SwiftUI

struct StationSIMView: View {
    @ObservedObject var store: StationStore
    var body: some View {
        Form {
            Section("设备与卡片") {
                LabeledContent("USB 标识", value: store.snapshot.usb)
                LabeledContent("固件", value: store.snapshot.firmware)
                LabeledContent("SIM 状态", value: store.snapshot.sim)
                LabeledContent("卡片编号", value: store.snapshot.cardSuffix)
                LabeledContent("运营商", value: store.snapshot.carrier)
                LabeledContent("无线制式", value: store.snapshot.radio)
            }
            Section("eSIM · 只读") {
                LabeledContent("eUICC 能力", value: "未验证")
                Text("检测到 SIM 并不代表支持 eSIM。需要兼容的 eUICC 卡片与经验证的只读协议，才能显示 EID 和套餐列表。")
                    .foregroundStyle(.secondary)
                Label("此版本不下载、不启用、不删除套餐", systemImage: "lock.shield")
            }
        }.formStyle(.grouped)
    }
}

struct StationLogsView: View {
    @ObservedObject var store: StationStore
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("运行日志").font(.title2.bold())
            Text("中文事件摘要 · 仅内存最近 300 条 · 不记录号码、短信正文或原始 AT 响应")
                .font(.callout).foregroundStyle(.secondary)
            List(store.events) { event in
                HStack(alignment: .top, spacing: 16) {
                    Text(event.date, style: .time).monospacedDigit().foregroundStyle(.secondary)
                    Text(event.message).textSelection(.enabled)
                }.padding(.vertical, 6)
            }
        }.padding(24)
    }
}

struct StationSettingsView: View {
    @ObservedObject var store: StationStore
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("SIM Station", systemImage: "phone.connection").font(.title.bold())
            Text("版本 0.1.0（1）· 安全预览版").foregroundStyle(.secondary)
            Divider()
            Text("本地运行，独立于 4G Bridge。启动时监听关闭，不修改网络，不安装特权服务。")
            Text("本次记录仅保留在内存中。加密历史存储尚未启用，不会静默写入明文记录。")
            Button("清空本次记录") { store.clearMemory() }
            Divider()
            Text("采用 MaVo 的 MIT 许可协议解析与 USB 通信代码。未包含上游图标、模块语音二进制或后台安装器。")
                .font(.caption).foregroundStyle(.secondary)
            Text("此工具不是运营商基站，也不提供紧急呼叫保障。")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}
