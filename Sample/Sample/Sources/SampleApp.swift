import AppMetricaCore
import AppMetricaIronSourceAdapter
import IronSource
import SwiftUI

@main
struct SampleApp: App {
    init() {
        AppMetricaIronSourceAdapter.isLoggingEnabled = true
        AppMetricaIronSourceAdapter.shared.initialize()
        // Random UUIDs
        IronSource.initWithAppKey("53C14FD2-963A-44F2-B7AF-008283333558", adUnits: [IS_BANNER])
        AppMetrica.activate(with: AppMetricaConfiguration(apiKey: "B6DCFFC5-C431-4256-84D3-0FF89669F0B9")!)
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
