import SwiftUI

struct StationCallsView: View {
    @ObservedObject var store: StationStore
    @State private var showReject = false
    @State private var pending: ModemCallInfo?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                StationCard(title: "当前通话", symbol: "phone.badge.waveform") {
                    if let call = store.snapshot.calls.first {
                        Text(call.number ?? "未知号码").font(.largeTitle.monospacedDigit())
                        Text(call.status == .incoming ? "有电话呼入" : "模块检测到通话活动")
                        HStack {
                            Button("接听 · 音频未验证") {}.disabled(true)
                            if call.status == .incoming {
                                Button("拒接…", role: .destructive) { pending = call; showReject = true }.disabled(store.busy)
                            }
                        }
                    } else {
                        ContentUnavailableView(store.monitoring ? "当前没有来电" : "来电监听已关闭", systemImage: "phone", description: Text("开始监听后，显示模块报告的来电。"))
                    }
                }
                StationCard(title: "本次通话记录", symbol: "clock") {
                    if store.records.isEmpty {
                        Text("尚无记录。不会生成演示来电或虚假通话记录。").foregroundStyle(.secondary)
                    }
                    ForEach(store.records) { record in
                        HStack {
                            Image(systemName: "phone.arrow.down.left").foregroundStyle(.tint)
                            VStack(alignment: .leading) {
                                Text(record.number).textSelection(.enabled)
                                Text(record.status).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(record.date, style: .time).foregroundStyle(.secondary)
                        }
                        Divider()
                    }
                }
                Text("拨号、双向音频和系统通讯录将在完成兼容性验证后接入。此版本不申请麦克风或通讯录权限。")
                    .font(.callout).foregroundStyle(.secondary)
            }.padding(28)
        }
        .confirmationDialog("拒接当前来电？", isPresented: $showReject) {
            Button("拒接来电", role: .destructive) { if let pending { store.reject(pending) } }
            Button("取消", role: .cancel) {}
        } message: { Text("会重新核对模块当前来电；来电改变后不会执行旧操作。") }
    }
}
