import AppMetricaCore
import AppMetricaCoreExtension
import Foundation
import IronSource
import os.log

/// A class that adapts IronSource SDK events for use with AppMetrica.
///
/// This adapter allows you to track ad revenue from IronSource in AppMetrica.
/// It handles the integration between IronSource's impression data and AppMetrica's
/// ad revenue reporting system.
@objc(AMAAppMetricaIronSourceAdapter)
public final class AppMetricaIronSourceAdapter: NSObject {

    /// The shared instance of the AppMetricaIronSourceAdapter.
    ///
    /// Use this property to access the singleton instance of the adapter.
    /// This ensures that only one instance of the adapter is used throughout your app.
    @objc(sharedInstance)
    public static let shared = AppMetricaIronSourceAdapter()

    /// Controls whether debug logging is enabled for this adapter.
    ///
    /// When set to `true`, the adapter will output debug information to the console.
    /// This can be useful for diagnosing issues or understanding the adapter's behavior.
    /// By default, logging is disabled to prevent unnecessary console output in production environments.
    ///
    /// - Note: Enable this only when needed for debugging, as it may impact performance.
    @objc public static var isLoggingEnabled: Bool {
        get { Logger.isLoggingEnabled }
        set { Logger.isLoggingEnabled = newValue }
    }

    private static func log(
        _ message: StaticString, type: OSLogType = .debug, log: OSLog, _ args: CVarArg...
    ) {
        guard isLoggingEnabled else { return }
        os_log(message, log: log, type: type, args)
    }

    /// Initializes the AppMetricaIronSourceAdapter.
    ///
    /// This method sets up the adapter to start receiving impression data from IronSource
    /// and reporting it to AppMetrica. It should be called once, typically early in your app's lifecycle.
    ///
    /// - Important: This Adapter must be activated before IronSource is activated. The order in which
    /// AppMetrica and the adapter are activated does not matter, but AppMetrica should be activated
    /// exactly once during the app's lifecycle.
    ///
    /// This method is thread-safe and can be called from any thread. If called multiple times,
    /// subsequent calls will have no effect.
    ///
    /// ## Example Usage
    /// ```swift
    /// AppMetricaIronSourceAdapter.shared.initialize()
    /// IronSource.initWithAppKey("<#API key#>", adUnits: [<#Ad units#>])
    /// AppMetrica.activate(with: AppMetricaConfiguration(apiKey: "<#API key#>")!)
    /// ```
    @objc public func initialize() {
        initializationLock.lock()
        defer { initializationLock.unlock() }

        guard !isInitialized else {
            Self.generalLogger.log(
                level: .info,
                message: "AppMetricaIronSourceAdapter is already initialized. Skipping initialization.")
            return
        }

        ironSourceProxy.add(self)
        appMetricaProxy.registerAdRevenueNativeSource("ironsource")
        
        isInitialized = true
        Self.generalLogger.log(
            level: .info,
            message:
                "AppMetricaIronSourceAdapter initialized with IronSource SDK version: \(IronSource.sdkVersion())"
        )
    }

    // Internal property for dependency injection in tests
    internal static var _shared: AppMetricaIronSourceAdapter = shared

    private let impressionQueue = ImpressionQueue()
    private var isInitialized = false
    private let initializationLock = NSLock()

    private static let generalLogger = Logger(
        subsystem: "io.appmetrica.IronSourceAdapter", category: .general)
    private static let impressionsLogger = Logger(
        subsystem: "io.appmetrica.IronSourceAdapter", category: .impressions)

    private let ironSourceProxy: IronSource.Type
    private let appMetricaProxy: AppMetrica.Type

    internal init(
        ironSourceType: IronSource.Type = IronSource.self,
        appMetricaType: AppMetrica.Type = AppMetrica.self
    ) {
        self.ironSourceProxy = ironSourceType
        self.appMetricaProxy = appMetricaType
        super.init()
        appMetricaType.add(Self.self)
    }

    deinit {
        if isInitialized {
            ironSourceProxy.remove(self)
        }
    }

    private func processQueuedImpressionData() async {
        let queuedData = await impressionQueue.dequeueAll()
        for impressionData in queuedData {
            processImpressionData(impressionData)
        }
    }

    private func processImpressionData(_ impressionData: ISImpressionData) {
        guard let revenue = impressionData.revenue?.doubleValue else {
            Self.impressionsLogger.log(level: .error, message: "Impression revenue is nil")
            return
        }

        let adRevenue = MutableAdRevenueInfo(
            adRevenue: NSDecimalNumber(value: revenue),
            currency: "USD"
        )

        adRevenue.adType = AdType(adUnit: impressionData.ad_unit)
        adRevenue.adNetwork = impressionData.ad_network
        adRevenue.adPlacementName = impressionData.placement
        adRevenue.precision = impressionData.precision
        adRevenue.adUnitName = impressionData.instance_name
        adRevenue.payload = [
            "layer": "native",
            "source": "ironsource",
        ]

        Self.impressionsLogger.log(
            level: .debug,
            message:
                "Processing impression data: revenue=\(revenue), adType=\(adRevenue.adType.rawValue), adNetwork=\(adRevenue.adNetwork ?? "unknown")"
        )
        appMetricaProxy.reportAdRevenue(adRevenue)
    }
}

extension AppMetricaIronSourceAdapter: ISImpressionDataDelegate {
    public func impressionDataDidSucceed(_ impressionData: ISImpressionData!) {
        guard let impressionData = impressionData else {
            Self.impressionsLogger.log(level: .error, message: "Impression data is nil")
            return
        }

        Self.impressionsLogger.log(
            level: .debug, message: "Received impression data: \(impressionData)")

        Task {
            await impressionQueue.enqueue(impressionData)
            if appMetricaProxy.isActivated {
                await processQueuedImpressionData()
            }
        }
    }
}

extension AppMetricaIronSourceAdapter: ModuleActivationDelegate {
    public static func willActivate(with configuration: ModuleActivationConfiguration) {
        // No implementation needed
    }

    public static func didActivate(with configuration: ModuleActivationConfiguration) {
        Task {
            await _shared.processQueuedImpressionData()
        }
    }
}
