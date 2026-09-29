import SwiftUI

struct StationMessagesView: View {
    @ObservedObject var store: StationStore
    @State private var search = ""
    @State private var selected: String?
    @State private var confirmRead = false
    private var filtered: [SMSMessage] {
        store.messages.filter { search.isEmpty || $0.sender.localizedCaseInsensitiveContains(search) || $0.body.localizedCaseInsensitiveContains(search) }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("短信收件箱").font(.title2.bold())
                Spacer()
                Button("读取模块短信…", systemImage: "arrow.clockwise") { confirmRead = true }
                    .disabled(!store.monitoring || store.busy)
            }
            TextField("搜索发件人或短信内容", text: $search).textFieldStyle(.roundedBorder)
            VSplitView {
                List(filtered, selection: $selected) { sms in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(sms.sender).fontWeight(.semibold)
                            Spacer(); Text(sms.timestamp, style: .date).foregroundStyle(.secondary)
                        }
                        Text(sms.body).lineLimit(2).foregroundStyle(.secondary)
                    }.tag(sms.id).padding(.vertical, 5)
                }.frame(minHeight: 140, idealHeight: 230)
                ScrollView {
                    if let sms = store.messages.first(where: { $0.id == selected }) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(sms.sender).font(.title2.bold())
                            Text(sms.timestamp.formatted(date: .abbreviated, time: .standard)).foregroundStyle(.secondary)
                            Divider()
                            Text(sms.body).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }.padding()
                    } else {
                        ContentUnavailableView("选择短信查看全文", systemImage: "text.bubble", description: Text("正文可选择复制；长短信在此滚动查看。"))
                    }
                }.frame(minHeight: 180)
            }
            Text("仅内存保留最近 200 条，停止监听或换卡时清空。不会转发、发送或删除模块短信。")
                .font(.caption).foregroundStyle(.secondary)
        }.padding(24)
        .confirmationDialog("读取模块中的短信？", isPresented: $confirmRead) {
            Button("读取，不删除") { store.readMessages() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("将临时切换短信读取模式，并可能把模块中的未读短信标记为已读。正文只在本次运行内存中展示；不会发送、转发或删除短信。")
        }
    }
}
