import SwiftUI

struct StationRootView: View {
    @ObservedObject var store: StationStore
    @State private var selection: StationPage? = .overview
    var body: some View {
        NavigationSplitView {
            List(StationPage.allCases, selection: $selection) { page in
                Label(page.rawValue, systemImage: page.symbol).tag(page)
                    .padding(.vertical, 5)
            }
            .navigationTitle("SIM Station")
            .listStyle(.sidebar)
            .safeAreaInset(edge: .bottom) {
                VStack(alignment: .leading, spacing: 7) {
                    Label(store.monitoring ? "监听已开启" : "监听已关闭", systemImage: store.monitoring ? "checkmark.circle.fill" : "pause.circle")
                    Text("0.1.0 · 安全预览版").font(.caption).foregroundStyle(.secondary)
                }.padding().frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationSplitViewColumnWidth(min: 190, ideal: 215, max: 260)
        } detail: {
            VStack(spacing: 0) {
                if let issue = store.issue {
                    Label(issue, systemImage: "exclamationmark.triangle")
                        .font(.callout).foregroundStyle(.orange).padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Divider()
                }
                switch selection ?? .overview {
                case .overview: StationOverview(store: store)
                case .calls: StationCallsView(store: store)
                case .messages: StationMessagesView(store: store)
                case .sim: StationSIMView(store: store)
                case .diagnostics: StationLogsView(store: store)
                }
            }
            .navigationTitle((selection ?? .overview).rawValue)
            .toolbar {
                ToolbarItem {
                    if store.busy { ProgressView().controlSize(.small) }
                }
                ToolbarItem {
                    Button(store.monitoring ? "停止监听" : "开始监听", systemImage: store.monitoring ? "stop.circle" : "play.circle") {
                        if store.monitoring { store.stop() } else { store.start() }
                    }.disabled(store.busy)
                }
                ToolbarItem { SettingsLink { Image(systemName: "gearshape") } }
            }
        }
    }
}

struct StationCard<Content: View>: View {
    let title: String
    let symbol: String
    @ViewBuilder var content: Content
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 16) { content }
                .frame(maxWidth: .infinity, alignment: .leading).padding(14)
        } label: { Label(title, systemImage: symbol).font(.headline) }
    }
}

struct StationOverview: View {
    @ObservedObject var store: StationStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("你的本地通信中心").font(.largeTitle.bold())
                    Text("一张 SIM，一台 Mac。来电与短信，留在你身边。")
                        .foregroundStyle(.secondary)
                }.padding(.bottom, 6)
                StationCard(title: "QDC507", symbol: "antenna.radiowaves.left.and.right") {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(store.snapshot.connected ? "模块已连接" : "等待开始检查").font(.title2.bold())
                            Text(store.monitoring ? "只读轮询中 · 完成一轮后约 3 秒再次查询" : "点击右上角开始监听；应用不会自动占用模块。")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 42, weight: .light)).foregroundStyle(.tint)
                    }
                    Divider()
                    HStack {
                        metric("运营商", store.snapshot.carrier)
                        Spacer(); metric("信号", store.snapshot.signal)
                        Spacer(); metric("SIM", store.snapshot.sim)
                    }
                }
                StationCard(title: "通话能力", symbol: "phone.connection") {
                    Label("来电识别与通话音频分别验证", systemImage: "checkmark.shield")
                    Text("此预览版可查询来电并在确认后拒接。双向语音尚未完成模块兼容性与安全验证，拨号和接听暂不可用。")
                        .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
                StationCard(title: "网络与隐私", symbol: "lock.shield") {
                    Text(store.network)
                    Text("不改变 Wi-Fi、VPN、DNS 或 4G 开关。不启动网页服务，不安装模块组件。短信与通话记录仅保留在本次运行内存中。")
                        .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
            }.padding(28)
        }
    }
    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline)
        }
    }
}
