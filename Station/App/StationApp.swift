import AppKit
import SwiftUI

@main
struct StationApp: App {
    @NSApplicationDelegateAdaptor(StationDelegate.self) private var delegate
    @StateObject private var store = StationStore()
    var body: some Scene {
        WindowGroup("SIM Station", id: "main") {
            StationRootView(store: store)
                .frame(minWidth: 880, minHeight: 620)
        }
        .defaultSize(width: 1080, height: 760)
        Settings { StationSettingsView(store: store).frame(width: 490).padding(24) }
        MenuBarExtra("SIM Station", systemImage: "phone.connection") {
            StationMenu(store: store)
        }
    }
}

final class StationDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

private struct StationMenu: View {
    @ObservedObject var store: StationStore
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        Text(store.monitoring ? "模块监听已开启" : "模块监听已关闭")
        Button("打开通信中心") { openWindow(id: "main"); NSApp.activate(ignoringOtherApps: true) }
        if store.monitoring { Button("停止监听") { store.stop() } }
        Divider()
        Text("0.1.0 · 安全预览版")
        Button("退出 SIM Station") { NSApp.terminate(nil) }.keyboardShortcut("q")
    }
}
