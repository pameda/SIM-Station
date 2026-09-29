import XCTest
@testable import SIMStation

final class StationTests: XCTestCase {
    func testDefaultSnapshotIsNotConnected() { XCTAssertFalse(StationSnapshot().connected) }
    func testCommandsDenyPersistentChanges() {
        for command in ["AT+CFUN=1,1", "AT+CGATT=1", "AT+QCFG=\"usbnet\",1", "AT+CMGD=1", "ATD123;", "ATA", "AT+CSIM=10", "AT+CMGS=1"] {
            XCTAssertFalse(StationPolicy.permits(command, messageConsent: true, rejectConsent: true))
        }
    }
    func testSMSConsentRequired() {
        XCTAssertFalse(StationPolicy.permits("AT+CMGL=4"))
        XCTAssertTrue(StationPolicy.permits("AT+CMGL=4", messageConsent: true))
    }
    func testRejectConsentRequired() {
        XCTAssertFalse(StationPolicy.permits("ATH"))
        XCTAssertTrue(StationPolicy.permits("ATH", rejectConsent: true))
    }
    func testInjectionBlocked() {
        XCTAssertFalse(StationPolicy.permits("AT+CSQ\rAT+CFUN=1,1"))
        XCTAssertNil(CallATParser.normalizedDialNumber("123\rATH"))
    }
    func testCLCC() {
        let info = CallATParser.parseCLCCResponse("+CLCC: 1,1,4,0,0,\"123\",129\r\nOK")
        XCTAssertEqual(info.count, 1)
        XCTAssertEqual(info.first?.status, .incoming)
        XCTAssertEqual(info.first?.number, "123")
    }
    func testStaleRejectDenied() throws {
        let expected = try XCTUnwrap(CallATParser.parseCLCC("+CLCC: 1,1,4,0,0,\"123\",129"))
        let changed = try XCTUnwrap(CallATParser.parseCLCC("+CLCC: 1,1,4,0,0,\"456\",129"))
        XCTAssertTrue(StationPolicy.canReject(expected: expected, current: [expected]))
        XCTAssertFalse(StationPolicy.canReject(expected: expected, current: [changed]))
        XCTAssertFalse(StationPolicy.canReject(expected: expected, current: []))
        XCTAssertFalse(StationPolicy.canReject(expected: expected, current: [expected, changed]))
    }
    func testActiveCallCannotBeRejectedAsIncoming() throws {
        let info = try XCTUnwrap(CallATParser.parseCLCC("+CLCC: 1,1,0,0,0,\"123\",129"))
        XCTAssertFalse(StationPolicy.canReject(expected: info, current: [info]))
    }
    func testPrivacyMask() { XCTAssertEqual(StationPolicy.masked("123456789"), "•••• 6789") }
    func testUnknownSignal() { XCTAssertNil(ATResponseParser.parseCSQ("+CSQ: 99,99\r\nOK")) }
    func testSIMReady() { XCTAssertTrue(ATResponseParser.parseSIMReady("+CPIN: READY\r\nOK")) }
    func testMalformedPDU() { XCTAssertThrowsError(try SMSPDUDecoder.decode("0000")) }
    func testUnicodePDUEncoder() throws {
        let parts = try SMSPDUEncoder.encode(destination: "123", body: "你好 🌍")
        XCTAssertEqual(parts.count, 1)
        XCTAssertTrue(parts[0].pdu.contains("4F60597D"))
    }
    func testMultipartPDUEncoder() throws {
        let parts = try SMSPDUEncoder.encode(destination: "123", body: String(repeating: "🌍", count: 75))
        XCTAssertGreaterThan(parts.count, 1)
        XCTAssertEqual(parts.last?.sequence, parts.count)
    }
    func testStreamFraming() {
        var framer = CallURCStreamFramer()
        XCTAssertTrue(framer.consume("RI").isEmpty)
        XCTAssertEqual(framer.consume("NG\r\n"), [.ring])
    }
    func testBlockedCommandsNeverReachTransport() {
        let fake = FakeTransport()
        let io = GuardedStationTransport(fake)
        XCTAssertThrowsError(try io.command("AT+CFUN=1,1"))
        XCTAssertTrue(fake.commands.isEmpty)
    }
    func testGuardedRead() throws {
        let fake = FakeTransport()
        let io = GuardedStationTransport(fake)
        _ = try io.command("AT+CSQ")
        XCTAssertEqual(fake.commands, ["AT+CSQ"])
    }
    func testSessionInitializationDoesNotOpenDevice() {
        let fake = FakeTransport()
        let session = StationSession(transport: fake)
        XCTAssertEqual(fake.opens, 0)
        withExtendedLifetime(session) {}
    }
    func testSessionReportsFailureWithoutRetryingWrites() {
        let fake = FakeTransport(); fake.failure = .timeout
        let session = StationSession(transport: fake)
        let done = expectation(description: "failure callback")
        session.onFailure = { error in XCTAssertEqual(error, .timeout); done.fulfill() }
        session.start()
        wait(for: [done], timeout: 3)
        XCTAssertTrue(fake.commands.allSatisfy { StationPolicy.readCommands.contains($0) })
        XCTAssertGreaterThan(fake.closes, 0)
    }
}

final class FakeTransport: StationTransport {
    var commands: [String] = []
    var opens = 0
    var closes = 0
    var failure: StationFailure?
    var identity: String { "2CA3:4006" }
    func open() throws { opens += 1 }
    func close() { closes += 1 }
    func transact(_ command: String) throws -> String {
        commands.append(command)
        if let failure { throw failure }
        return "OK\r\n"
    }
}
