import Foundation

enum StationPage: String, CaseIterable, Identifiable {
    case overview = "通信总览", calls = "电话与记录", messages = "短信", sim = "SIM 与 eSIM", diagnostics = "运行日志"
    var id: Self { self }
    var symbol: String {
        switch self {
        case .overview: "square.grid.2x2"
        case .calls: "phone"
        case .messages: "message"
        case .sim: "simcard"
        case .diagnostics: "list.bullet.rectangle"
        }
    }
}

struct StationSnapshot {
    var connected = false
    var usb = "尚未检查"
    var firmware = "尚未检查"
    var sim = "尚未检查"
    var carrier = "尚未检查"
    var radio = "尚未检查"
    var signal = "尚未检查"
    var cardSuffix = "尚未检查"
    var calls: [ModemCallInfo] = []
    var checkedAt: Date?
}

struct CallRecord: Identifiable {
    let id = UUID()
    let number: String
    let date: Date
    var status: String
}

struct StationEvent: Identifiable {
    let id = UUID()
    let date = Date()
    let message: String // Fixed local messages only; never raw modem responses.
}

enum StationFailure: LocalizedError, Equatable {
    case blockedCommand, unavailable, timeout, rejected, otherManager, staleCall, invalidCard, stopped, multipleDevices
    var errorDescription: String? {
        switch self {
        case .blockedCommand: "安全策略已阻止这条模块命令。"
        case .unavailable: "模块未连接、接口不兼容或已被占用；没有抢占或重置设备。"
        case .timeout: "模块未及时响应，会话已关闭。请检查连接后重新开始。"
        case .rejected: "模块不支持或拒绝了此查询。"
        case .otherManager: "其他模块管理程序仍在运行。请先退出 4G Bridge、MaVo、DJOneHub 或 iPad Link，再开始检查。"
        case .staleCall: "来电已变化或结束，未发送拒接命令。"
        case .invalidCard: "无法确认 SIM 身份，未读取短信。"
        case .stopped: "监听已停止。"
        case .multipleDevices: "检测到多个受支持模块。为避免操作错设备，请仅连接供 SIM Station 使用的模块。"
        }
    }
}

enum StationPolicy {
    static let readCommands: Set<String> = ["AT", "AT+CGMR", "AT+CPIN?", "AT+QCCID", "AT+COPS?", "AT+CSQ", "AT+CLCC", "AT+CMGF?", "AT+CPMS?"]
    static func permits(_ command: String, messageConsent: Bool = false, rejectConsent: Bool = false) -> Bool {
        if readCommands.contains(command) { return true }
        if messageConsent && ["AT+CMGF=0", "AT+CMGF=1", "AT+CPMS=\"SM\"", "AT+CPMS=\"ME\"", "AT+CPMS=\"MT\"", "AT+CMGL=4"].contains(command) { return true }
        return rejectConsent && command == "ATH"
    }
    static func canReject(expected: ModemCallInfo, current: [ModemCallInfo]) -> Bool {
        current.count == 1 && current[0].index == expected.index &&
        current[0].number == expected.number && current[0].direction == .incoming &&
        current[0].status == .incoming && expected.status == .incoming
    }
    static func masked(_ value: String) -> String {
        guard value.count > 4 else { return "••••" }
        return "•••• " + value.suffix(4)
    }
}
