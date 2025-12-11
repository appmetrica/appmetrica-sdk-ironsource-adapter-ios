import AppMetricaCore
import AppMetricaIronSourceAdapter
import IronSource
import SwiftUI

let levelPlayerDemoAppKey = "8545d445"

@main
struct SampleApp: App {
    init() {
        AppMetricaIronSourceAdapter.isLoggingEnabled = true
        AppMetricaIronSourceAdapter.shared.initialize()
        
        let requestBuilder = LPMInitRequestBuilder(appKey: levelPlayerDemoAppKey)
        let initRequest = requestBuilder.build()
        LevelPlay.initWith(initRequest) { config, error in
            print("config=\(String(describing: config)) error=\(String(describing: error))")
        }
        AppMetrica.activate(with: AppMetricaConfiguration(apiKey: "bfe507db-a6fd-4620-913a-a8815af9a907")!)
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
