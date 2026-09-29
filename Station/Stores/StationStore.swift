import AppKit
import Combine
import SystemConfiguration

@MainActor
final class StationStore: ObservableObject {
    @Published var snapshot = StationSnapshot()
    @Published var monitoring = false
    @Published var busy = false
    @Published var issue: String?
    @Published var messages: [SMSMessage] = []
    @Published var records: [CallRecord] = []
    @Published var events: [StationEvent] = []
    @Published var network = "尚未检查"
    private var session: StationSession?
    private var generation = UUID()
    private var activeCallID: UUID?
    private var observer: NSObjectProtocol?

    init() {
        event("应用已启动；模块监听关闭，未修改系统网络。")
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.stop(reason: "Mac 即将睡眠，已停止监听；唤醒后请手动开始。") }
        }
    }
    func start() {
        guard !monitoring else { return }
        let others = NSWorkspace.shared.runningApplications.contains { app in
            let name = (app.localizedName ?? "").lowercased()
            return ["4g bridge", "mavo", "djonehub", "qdc507 ipad link"].contains { name.contains($0) }
        }
        guard !others else { issue = StationFailure.otherManager.localizedDescription; event("开始监听被阻止：其他管理程序运行中。"); return }
        generation = UUID()
        let token = generation
        monitoring = true; busy = true; issue = nil
        messages = []; records = []; activeCallID = nil
        let session = StationSession()
        self.session = session
        session.onSnapshot = { [weak self] value in
            guard let self, self.generation == token, self.monitoring else { return }
            self.snapshot = value; self.busy = false
            self.updateCallHistory(value.calls)
            self.refreshNetwork()
        }
        session.onMessages = { [weak self] items in
            guard let self, self.generation == token, self.monitoring else { return }
            self.messages = Array(items.sorted { $0.timestamp > $1.timestamp }.prefix(200))
            self.busy = false
            self.event("短信读取完成；正文仅保留在当前内存中，未删除模块短信。")
        }
        session.onCardChanged = { [weak self] in
            guard let self, self.generation == token else { return }
            self.messages = []; self.records = []; self.activeCallID = nil
            self.event("SIM 身份变化，已清空本次短信与通话记录。")
        }
        session.onFailure = { [weak self] failure in
            guard let self, self.generation == token else { return }
            self.stop(reason: "监听已停止：" + failure.localizedDescription)
            self.issue = failure.localizedDescription
        }
        event("用户已开始只读设备查询与来电轮询。")
        session.start()
    }
    func stop(reason: String = "用户已停止监听，释放模块接口。") {
        generation = UUID(); session?.stop(); session = nil
        monitoring = false; busy = false
        snapshot = StationSnapshot()
        messages = []; activeCallID = nil
        event(reason)
    }
    func readMessages() {
        guard monitoring, !busy else { return }
        busy = true
        event("用户已确认读取短信；不会发送或删除短信。")
        session?.readMessages()
    }
    func reject(_ expected: ModemCallInfo) {
        guard monitoring, !busy else { return }
        busy = true
        let token = generation
        session?.reject(expected) { [weak self] ended in
            guard let self, self.generation == token else { return }
            self.busy = false
            self.event(ended ? "已确认来电结束。" : "拒接结果尚未确认；不会自动重试。")
        }
    }
    func clearMemory() { messages = []; records = []; activeCallID = nil; event("本次短信与通话记录已从界面内存清空；模块内容未改变。") }
    private func updateCallHistory(_ calls: [ModemCallInfo]) {
        if let call = calls.first {
            if activeCallID == nil {
                let record = CallRecord(number: call.number ?? "未知号码", date: Date(), status: label(call.status))
                records.insert(record, at: 0); activeCallID = record.id
                records = Array(records.prefix(200))
                event(call.direction == .incoming ? "检测到来电。" : "检测到模块通话。")
            } else if let index = records.firstIndex(where: { $0.id == activeCallID }) {
                records[index].status = label(call.status)
            }
        } else if let index = records.firstIndex(where: { $0.id == activeCallID }) {
            records[index].status = "已结束（未验证通话音频）"
            activeCallID = nil; event("模块报告通话结束。")
        }
    }
    private func label(_ status: ModemCallStatus) -> String {
        switch status {
        case .incoming: "来电中"
        case .waiting: "呼叫等待"
        case .dialing: "拨号中"
        case .alerting: "正在振铃"
        case .active: "模块报告已接通"
        case .held: "保持中"
        }
    }
    private func refreshNetwork() {
        guard let store = SCDynamicStoreCreate(nil, "SIM Station" as CFString, nil, nil),
              let state = SCDynamicStoreCopyValue(store, "State:/Network/Global/IPv4" as CFString) as? [String: Any],
              let interface = state["PrimaryInterface"] as? String else { network = "没有默认 IPv4 接口"; return }
        network = "当前默认接口：\(interface) · 未修改网络优先级"
    }
    private func event(_ text: String) { events.insert(StationEvent(message: text), at: 0); events = Array(events.prefix(300)) }
}
