import CryptoKit
import Foundation

/// Every device operation is serialized. No automatic reconnect or action replay.
final class StationSession {
    private let queue = DispatchQueue(label: "local.simstation.session")
    private let io: GuardedStationTransport
    private var timer: DispatchSourceTimer?
    private var active = false
    private var cardHash: String?
    private var snapshot = StationSnapshot()
    var onSnapshot: ((StationSnapshot) -> Void)?
    var onFailure: ((StationFailure) -> Void)?
    var onMessages: (([SMSMessage]) -> Void)?
    var onCardChanged: (() -> Void)?
    init(transport: StationTransport = USBStationTransport()) { io = GuardedStationTransport(transport) }
    func start() {
        queue.async {
            guard !self.active else { return }
            do {
                try self.io.open()
                self.active = true
                try self.sample(full: true)
                let timer = DispatchSource.makeTimerSource(queue: self.queue)
                timer.schedule(deadline: .now() + 3, repeating: 3)
                timer.setEventHandler { [weak self] in self?.poll() }
                self.timer = timer
                timer.resume()
            } catch { self.fail(error) }
        }
    }
    func stop() { queue.async { self.stopOnQueue() } }
    private func stopOnQueue() {
        timer?.cancel(); timer = nil
        active = false; io.close(); cardHash = nil
    }
    private func fail(_ error: Error) {
        stopOnQueue()
        let safe = error as? StationFailure ?? .unavailable
        DispatchQueue.main.async { self.onFailure?(safe) }
    }
    private func poll() {
        guard active else { return }
        do { try sample(full: false) } catch { fail(error) }
    }
    private func cardIdentity() throws -> String {
        let response = try io.command("AT+QCCID")
        guard let value = ATResponseParser.parseICCID(response), !value.isEmpty else { throw StationFailure.invalidCard }
        return value
    }
    private func acceptCard(_ value: String) {
        let hash = SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined()
        if let cardHash, cardHash != hash { DispatchQueue.main.async { self.onCardChanged?() } }
        cardHash = hash
    }
    private func sample(full: Bool) throws {
        snapshot.connected = true; snapshot.usb = io.identity
        if full {
            let firmware = try io.command("AT+CGMR")
            snapshot.firmware = ATResponseParser.normalizedLines(firmware).filter { $0 != "OK" && $0 != "AT+CGMR" }.joined(separator: " ")
        }
        let ready = ATResponseParser.parseSIMReady(try io.command("AT+CPIN?"))
        snapshot.sim = ready ? "已就绪" : "未就绪 / 需要 PIN"
        if ready {
            let value = try cardIdentity(); acceptCard(value)
            snapshot.cardSuffix = StationPolicy.masked(value)
        } else {
            if cardHash != nil { DispatchQueue.main.async { self.onCardChanged?() } }
            cardHash = nil; snapshot.cardSuffix = "未就绪"
        }
        let carrier = ATResponseParser.parseOperator(try io.command("AT+COPS?"))
        snapshot.carrier = carrier.name ?? "未注册"
        snapshot.radio = carrier.technology ?? "未知"
        snapshot.signal = ATResponseParser.parseCSQ(try io.command("AT+CSQ")).map { "\($0) dBm" } ?? "未知"
        snapshot.calls = CallATParser.parseCLCCResponse(try io.command("AT+CLCC"))
        snapshot.checkedAt = Date()
        let result = snapshot
        DispatchQueue.main.async { self.onSnapshot?(result) }
    }
    func reject(_ expected: ModemCallInfo, completion: @escaping (Bool) -> Void) {
        queue.async {
            do {
                guard self.active else { throw StationFailure.stopped }
                let live = CallATParser.parseCLCCResponse(try self.io.command("AT+CLCC"))
                guard StationPolicy.canReject(expected: expected, current: live) else { throw StationFailure.staleCall }
                _ = try self.io.command("ATH", rejecting: true)
                try self.sample(full: false)
                let ended = self.snapshot.calls.isEmpty
                DispatchQueue.main.async { completion(ended) }
            } catch { self.fail(error); DispatchQueue.main.async { completion(false) } }
        }
    }
    func readMessages() {
        queue.async {
            guard self.active else { return }
            do {
                let card = try self.cardIdentity(); self.acceptCard(card)
                let modeReply = try self.io.command("AT+CMGF?")
                let modes = ATResponseParser.normalizedLines(modeReply).filter { $0.hasPrefix("+CMGF:") }
                guard let mode = modes.first?.split(separator: ":").last?.trimmingCharacters(in: .whitespaces), ["0", "1"].contains(mode) else { throw StationFailure.rejected }
                let wasText = mode == "1"
                let oldStorage = ATResponseParser.parseCPMSStorage(try self.io.command("AT+CPMS?"))
                guard let oldStorage, ["SM", "ME", "MT"].contains(oldStorage) else { throw StationFailure.rejected }
                _ = try self.io.command("AT+CMGF=0", messages: true)
                var stored: [ModemStoredPDU] = []
                for storage in ["SM", "ME"] {
                    do {
                        _ = try self.io.command("AT+CPMS=\"\(storage)\"", messages: true)
                        let response = try self.io.command("AT+CMGL=4", messages: true)
                        stored += ATResponseParser.parseCMGL(response).map {
                            ModemStoredPDU(index: $0.index, status: $0.status, declaredLength: $0.declaredLength, rawPDU: $0.rawPDU, storage: storage)
                        }
                    } catch StationFailure.rejected { continue }
                }
                _ = try self.io.command("AT+CPMS=\"\(oldStorage)\"", messages: true)
                if wasText { _ = try self.io.command("AT+CMGF=1", messages: true) }
                guard try self.cardIdentity() == card else {
                    DispatchQueue.main.async { self.onCardChanged?() }
                    throw StationFailure.invalidCard
                }
                let result = SMSPDUDecoder.assemble(stored)
                DispatchQueue.main.async { self.onMessages?(result) }
            } catch { self.fail(error) }
        }
    }
}
