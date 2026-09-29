import CModemBridge
import Foundation
import IOKit

protocol StationTransport: AnyObject {
    func open() throws
    func close()
    var identity: String { get }
    func transact(_ command: String) throws -> String
}

/// Used exclusively on StationSession's serial queue. No voice/ADB API is exposed.
final class USBStationTransport: StationTransport {
    private var handle: OpaquePointer?
    func open() throws {
        guard knownDeviceCount() <= 1 else { throw StationFailure.multipleDevices }
        if handle == nil { handle = mavo_modem_create() }
        guard let handle, mavo_modem_open(handle) == MAVO_MODEM_OK else {
            close()
            throw StationFailure.unavailable
        }
    }
    func close() {
        if let handle { mavo_modem_destroy(handle) }
        handle = nil
    }
    var identity: String {
        guard let handle else { return "未连接" }
        return String(format: "%04X:%04X", mavo_modem_vendor_id(handle), mavo_modem_product_id(handle))
    }
    func transact(_ command: String) throws -> String {
        guard let handle else { throw StationFailure.unavailable }
        var buffer = [CChar](repeating: 0, count: 65_536)
        let result = command.withCString { ptr in
            mavo_modem_command(handle, ptr, 3_000, &buffer, buffer.count)
        }
        guard result == MAVO_MODEM_OK else { close(); throw StationFailure.timeout }
        let response = String(cString: buffer)
        let lines = ATResponseParser.normalizedLines(response)
        guard !lines.contains(where: { $0 == "ERROR" || $0.hasPrefix("+CME ERROR") || $0.hasPrefix("+CMS ERROR") }) else { throw StationFailure.rejected }
        guard lines.contains("OK") else { throw StationFailure.rejected }
        return response
    }
    deinit { close() }

    private func knownDeviceCount() -> Int {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOUSBHostDevice"), &iterator) == KERN_SUCCESS else { return 0 }
        defer { IOObjectRelease(iterator) }
        var count = 0
        while case let device = IOIteratorNext(iterator), device != 0 {
            let vid = IORegistryEntryCreateCFProperty(device, "idVendor" as CFString, nil, 0)?.takeRetainedValue() as? NSNumber
            let pid = IORegistryEntryCreateCFProperty(device, "idProduct" as CFString, nil, 0)?.takeRetainedValue() as? NSNumber
            if (vid?.intValue == 0x2CA3 && pid?.intValue == 0x4006) || (vid?.intValue == 0x2C7C && pid?.intValue == 0x0125) { count += 1 }
            IOObjectRelease(device)
        }
        return count
    }
}

final class GuardedStationTransport {
    private let transport: StationTransport
    init(_ transport: StationTransport) { self.transport = transport }
    var identity: String { transport.identity }
    func open() throws { try transport.open() }
    func close() { transport.close() }
    func command(_ command: String, messages: Bool = false, rejecting: Bool = false) throws -> String {
        guard StationPolicy.permits(command, messageConsent: messages, rejectConsent: rejecting) else { throw StationFailure.blockedCommand }
        return try transport.transact(command)
    }
}
