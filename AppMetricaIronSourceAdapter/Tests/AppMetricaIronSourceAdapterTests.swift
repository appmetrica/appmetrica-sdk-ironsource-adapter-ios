import AppMetricaCoreExtension
import IronSource
import XCTest

@testable import AppMetricaIronSourceAdapter

class AppMetricaIronSourceAdapterTests: XCTestCase {
    var adapter: AppMetricaIronSourceAdapter!

    override func setUp() async throws {
        try await super.setUp()
        await MockAppMetrica.reset()
        MockIronSource.reset()

        adapter = AppMetricaIronSourceAdapter(
            ironSourceType: MockIronSource.self, appMetricaType: MockAppMetrica.self)
        AppMetricaIronSourceAdapter._shared = adapter
    }

    func testInitialization() async {
        let called = await MockAppMetrica.addCalled
        XCTAssertTrue(called, "AppMetrica.add should be called during initialization")
    }

    func testInitialize() async {
        adapter.initialize()
        XCTAssertTrue(MockIronSource.addCalled, "IronSource.add should be called during initialization")
        
        let registerSourceCalled = await MockAppMetrica.registerSourceCalled
        XCTAssertTrue(registerSourceCalled, "AppMetrica.registerSource should be called")
        
        let registerSources = await MockAppMetrica.registerSources
        XCTAssertEqual(registerSources, ["ironsource"])
    }

    func testDoubleInitialization() {
        adapter.initialize()
        XCTAssertTrue(
            MockIronSource.addCalled, "IronSource.add should be called during first initialization")

        MockIronSource.addCalled = false
        adapter.initialize()
        XCTAssertFalse(
            MockIronSource.addCalled, "IronSource.add should not be called during second initialization")
    }

    func testImpressionDataProcessing() async throws {
        let impressionData = MockISImpressionData(
            adUnit: "rewarded_video",
            revenue: NSNumber(value: 1.0),
            adNetwork: "TestNetwork",
            placement: "TestPlacement",
            precision: "Precise",
            mediationAdUnitName: "AdUnitName",
            mediationAdUnitId: "AdUnitId"
        )

        MockAppMetrica.setIsActivated(true)
        adapter.impressionDataDidSucceed(impressionData)

        try await Task.sleep(nanoseconds: 100_000_000)

        let reportAdRevenueCalled = await MockAppMetrica.reportAdRevenueCalled
        XCTAssertTrue(reportAdRevenueCalled, "AppMetrica.reportAdRevenue should be called")

        let reportedAdRevenues = await MockAppMetrica.reportedAdRevenues
        XCTAssertFalse(reportedAdRevenues.isEmpty, "Reported ad revenues should not be empty")

        if let firstRevenue = reportedAdRevenues.first {
            XCTAssertEqual(firstRevenue.adRevenue, NSDecimalNumber(value: 1.0))
            XCTAssertEqual(firstRevenue.currency, "USD")
            XCTAssertEqual(firstRevenue.adType, .rewarded)
            XCTAssertEqual(firstRevenue.adNetwork, "TestNetwork")
            XCTAssertEqual(firstRevenue.adPlacementName, "TestPlacement")
            XCTAssertEqual(firstRevenue.precision, "Precise")
            XCTAssertEqual(firstRevenue.adUnitName, "AdUnitName")
            XCTAssertEqual(firstRevenue.adUnitID, "AdUnitId")
            XCTAssertEqual(firstRevenue.payload, [
                "layer": "native",
                "source": "ironsource",
                "original_source": "ad-revenue-ironsource-v9",
                "original_ad_type": "rewarded_video",
            ])
        } else {
            XCTFail("No ad revenue reported")
        }
    }

    func testImpressionDataProcessingWithNilRevenue() async throws {
        let impressionData = MockISImpressionData(
            adUnit: "rewarded_video",
            revenue: nil,
            adNetwork: "TestNetwork",
            placement: "TestPlacement",
            precision: "Precise",
            mediationAdUnitName: "AdUnitName",
            mediationAdUnitId: "AdUnitId"
        )

        MockAppMetrica.setIsActivated(true)
        adapter.impressionDataDidSucceed(impressionData)

        try await Task.sleep(nanoseconds: 100_000_000)

        let reportAdRevenueCalled = await MockAppMetrica.reportAdRevenueCalled
        XCTAssertFalse(
            reportAdRevenueCalled, "AppMetrica.reportAdRevenue should not be called when revenue is nil")
    }

    func testImpressionDataProcessingWithZeroRevenue() async throws {
        let impressionData = MockISImpressionData(
            adUnit: "rewarded_video",
            revenue: NSNumber(value: 0.0),
            adNetwork: "TestNetwork",
            placement: "TestPlacement",
            precision: "Precise",
            mediationAdUnitName: "AdUnitName",
            mediationAdUnitId: "AdUnitId"
        )

        MockAppMetrica.setIsActivated(true)
        adapter.impressionDataDidSucceed(impressionData)

        try await Task.sleep(nanoseconds: 100_000_000)

        let reportAdRevenueCalled = await MockAppMetrica.reportAdRevenueCalled
        let adRevenue = await MockAppMetrica.reportedAdRevenues.first?.adRevenue
        XCTAssertTrue(
            reportAdRevenueCalled, "AppMetrica.reportAdRevenue should be called even with zero revenue")
        XCTAssertEqual(adRevenue, NSDecimalNumber(value: 0.0))
    }

    func testImpressionDataProcessingWithNilAdUnit() async throws {
        let impressionData = MockISImpressionData(
            adUnit: nil,
            revenue: NSNumber(value: 1.0),
            adNetwork: "TestNetwork",
            placement: "TestPlacement",
            precision: "Precise",
            mediationAdUnitName: "AdUnitName",
            mediationAdUnitId: "AdUnitId"
        )

        MockAppMetrica.setIsActivated(true)
        adapter.impressionDataDidSucceed(impressionData)

        try await Task.sleep(nanoseconds: 100_000_000)

        let reportAdRevenueCalled = await MockAppMetrica.reportAdRevenueCalled
        let adType = await MockAppMetrica.reportedAdRevenues.first?.adType

        XCTAssertTrue(
            reportAdRevenueCalled, "AppMetrica.reportAdRevenue should be called even with nil adUnit")
        XCTAssertEqual(adType, .unknown)
    }

    func testImpressionDataProcessingWithUnknownAdUnit() async throws {
        let impressionData = MockISImpressionData(
            adUnit: "UNKNOWN_AD_UNIT",
            revenue: NSNumber(value: 1.0),
            adNetwork: "TestNetwork",
            placement: "TestPlacement",
            precision: "Precise",
            mediationAdUnitName: "AdUnitName",
            mediationAdUnitId: "AdUnitId"
        )

        MockAppMetrica.setIsActivated(true)
        adapter.impressionDataDidSucceed(impressionData)

        try await Task.sleep(nanoseconds: 100_000_000)

        let reportAdRevenueCalled = await MockAppMetrica.reportAdRevenueCalled
        let adType = await MockAppMetrica.reportedAdRevenues.first?.adType

        XCTAssertTrue(
            reportAdRevenueCalled, "AppMetrica.reportAdRevenue should be called even with other adUnit")
        XCTAssertEqual(adType, .other)
    }

    func testImpressionDataProcessingWhenAppMetricaNotActivated() async throws {
        let impressionData = MockISImpressionData(
            adUnit: "rewarded_video",
            revenue: NSNumber(value: 1.0),
            adNetwork: "TestNetwork",
            placement: "TestPlacement",
            precision: "Precise",
            mediationAdUnitName: "AdUnitName",
            mediationAdUnitId: "AdUnitId"
        )

        MockAppMetrica.setIsActivated(false)
        adapter.impressionDataDidSucceed(impressionData)

        try await Task.sleep(nanoseconds: 100_000_000)

        let reportAdRevenueCalled = await MockAppMetrica.reportAdRevenueCalled

        XCTAssertFalse(
            reportAdRevenueCalled,
            "AppMetrica.reportAdRevenue should not be called when AppMetrica is not activated")
    }

    func testImpressionDataProcessingWithNilImpressionData() async throws {
        MockAppMetrica.setIsActivated(true)
        adapter.impressionDataDidSucceed(nil)

        try await Task.sleep(nanoseconds: 100_000_000)

        let reportAdRevenueCalled = await MockAppMetrica.reportAdRevenueCalled

        XCTAssertFalse(
            reportAdRevenueCalled,
            "AppMetrica.reportAdRevenue should not be called with nil impressionData")
    }

    func testDeinitializationRemovesDelegate() async throws {
        var localAdapter: AppMetricaIronSourceAdapter? = AppMetricaIronSourceAdapter(
            ironSourceType: MockIronSource.self, appMetricaType: MockAppMetrica.self)
        localAdapter?.initialize()

        XCTAssertTrue(MockIronSource.addCalled, "IronSource.add should be called during initialization")

        localAdapter = nil

        XCTAssertTrue(
            MockIronSource.removeCalled, "IronSource.remove should be called during deinitialization")
    }

    func testWillActivate() {
        // This method is empty in the implementation, but we should test it's called
        let configuration = ModuleActivationConfiguration(apiKey: "test-api-key")
        AppMetricaIronSourceAdapter.willActivate(with: configuration)
        // No assertion needed as the method is empty, but we ensure it doesn't crash
    }

    func testDidActivateProcessesQueuedImpressionData() async throws {
        let configuration = ModuleActivationConfiguration(apiKey: "test-api-key")

        // Queue some impression data
        let impressionData1 = MockISImpressionData(
            adUnit: "rewarded_video",
            revenue: NSNumber(value: 1.0),
            adNetwork: "TestNetwork1",
            placement: "TestPlacement1",
            precision: "Precise",
            mediationAdUnitName: "AdUnitName1",
            mediationAdUnitId: "AdUnitId1"
        )

        let impressionData2 = MockISImpressionData(
            adUnit: "interstitial",
            revenue: NSNumber(value: 2.0),
            adNetwork: "TestNetwork2",
            placement: "TestPlacement2",
            precision: "Precise",
            mediationAdUnitName: "AdUnitName2",
            mediationAdUnitId: "AdUnitId2"
        )

        // Simulate queueing impression data when AppMetrica is not activated
        MockAppMetrica.setIsActivated(false)
        adapter.impressionDataDidSucceed(impressionData1)
        adapter.impressionDataDidSucceed(impressionData2)

        // Verify that no ad revenue is reported yet
        var reportAdRevenueCalled = await MockAppMetrica.reportAdRevenueCalled
        XCTAssertFalse(
            reportAdRevenueCalled,
            "AppMetrica.reportAdRevenue should not be called when AppMetrica is not activated")

        // Simulate AppMetrica activation
        MockAppMetrica.setIsActivated(true)

        // Call didActivate
        AppMetricaIronSourceAdapter.didActivate(with: configuration)

        // We need to wait for the async task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        reportAdRevenueCalled = await MockAppMetrica.reportAdRevenueCalled
        let reportAdRevenueCallCount = await MockAppMetrica.reportAdRevenueCallCount
        let adRevenuesCount = await MockAppMetrica.reportedAdRevenues.count
        XCTAssertTrue(reportAdRevenueCalled, "AppMetrica.reportAdRevenue should be called after activation")
        XCTAssertEqual(reportAdRevenueCallCount, 2,
                       "AppMetrica.reportAdRevenue should be called twice for two queued items")
        XCTAssertEqual(adRevenuesCount, 2, "Two ad revenues should be reported")

        // Check if both expected ad revenues are present (order doesn't matter)
        let expectedAdRevenues: Set<AdRevenueData> = [
            AdRevenueData(
                adRevenue: NSDecimalNumber(value: 1.0),
                currency: "USD",
                adType: .rewarded,
                adNetwork: "TestNetwork1",
                adUnitID: "AdUnitId1",
                adUnitName: "AdUnitName1",
                adPlacementID: nil,
                adPlacementName: "TestPlacement1",
                precision: "Precise"),
            AdRevenueData(
                adRevenue: NSDecimalNumber(value: 2.0),
                currency: "USD",
                adType: .interstitial,
                adNetwork: "TestNetwork2",
                adUnitID: "AdUnitId2",
                adUnitName: "AdUnitName2",
                adPlacementID: nil,
                adPlacementName: "TestPlacement2",
                precision: "Precise"),
        ]

        let reportedAdRevenues = await Set(MockAppMetrica.reportedAdRevenues.map { $0.testRevenueData })

        XCTAssertEqual(reportedAdRevenues, expectedAdRevenues, "Reported ad revenues should match expected values")
    }

    func testDidActivateWithNoQueuedData() async throws {
        let configuration = ModuleActivationConfiguration(apiKey: "test-api-key")

        // Ensure no impression data is queued
        MockAppMetrica.setIsActivated(true)

        AppMetricaIronSourceAdapter.didActivate(with: configuration)

        // We still need to wait for the async task to complete, even if it does nothing
        try await Task.sleep(nanoseconds: 100_000_000)

        let reportAdRevenueCalled = await MockAppMetrica.reportAdRevenueCalled
        XCTAssertFalse(reportAdRevenueCalled,
                       "AppMetrica.reportAdRevenue should not be called when there's no queued data")
    }

    func testConcurrentImpressionDataProcessing() async throws {
        MockAppMetrica.setIsActivated(true)

        let expectations = (0..<100).map { _ in expectation(description: "Impression data processed") }

        DispatchQueue.concurrentPerform(iterations: 100) { index in
            let impressionData = MockISImpressionData(
                adUnit: "rewarded_video",
                revenue: NSNumber(value: Double(index)),
                adNetwork: "TestNetwork",
                placement: "TestPlacement",
                precision: "Precise",
                mediationAdUnitName: "AdUnitName",
                mediationAdUnitId: "AdUnitId"
            )

            self.adapter.impressionDataDidSucceed(impressionData)
            expectations[index].fulfill()
        }

        await fulfillment(of: expectations, timeout: 5.0)

        try await Task.sleep(nanoseconds: 500_000_000)  // Wait for all impressions to be processed

        let reportedAdRevenues = await MockAppMetrica.reportedAdRevenues
        XCTAssertEqual(reportedAdRevenues.count, 100, "All 100 impression data should be processed")

        let uniqueRevenues = Set(reportedAdRevenues.map { $0.adRevenue.doubleValue })
        XCTAssertEqual(uniqueRevenues.count, 100, "All revenues should be unique")
    }

    func testImpressionDataProcessingDuringActivation() async throws {
        MockAppMetrica.setIsActivated(false)

        let impressionData = MockISImpressionData(
            adUnit: "rewarded_video",
            revenue: NSNumber(value: 1.0),
            adNetwork: "TestNetwork",
            placement: "TestPlacement",
            precision: "Precise",
            mediationAdUnitName: "AdUnitName",
            mediationAdUnitId: "AdUnitId"
        )

        let processingTask = Task {
            for _ in 0..<100 {
                self.adapter.impressionDataDidSucceed(impressionData)
                try await Task.sleep(nanoseconds: 10_000_000)
            }
        }

        try await Task.sleep(nanoseconds: 500_000_000)

        MockAppMetrica.setIsActivated(true)
        AppMetricaIronSourceAdapter.didActivate(with: ModuleActivationConfiguration(apiKey: "test-api-key"))

        try await processingTask.value

        try await Task.sleep(nanoseconds: 500_000_000)

        let reportedAdRevenues = await MockAppMetrica.reportedAdRevenues
        XCTAssertGreaterThan(reportedAdRevenues.count, 0, "Some ad revenues should be reported")
        XCTAssertLessThanOrEqual(reportedAdRevenues.count, 100, "Not all ad revenues may be reported due to race condition")
    }
    
    func testValueMappingFromIronSourceToAppMetrica() async throws {
        MockAppMetrica.setIsActivated(true)

        let testCases: [(adUnit: String?, expectedAdType: AdType)] = [
            ("rewarded_video", .rewarded),
            ("interstitial", .interstitial),
            ("banner", .banner),
//            ("native_ad", .native),
            ("other_ad_unit", .other),
            (nil, .unknown)
        ]

        for (index, testCase) in testCases.enumerated() {
            let impressionData = MockISImpressionData(
                adUnit: testCase.adUnit,
                revenue: NSNumber(value: Double(index) + 1.0),
                adNetwork: "TestNetwork\(index)",
                placement: "TestPlacement\(index)",
                precision: "TestPrecision\(index)",
                mediationAdUnitName: "TestAdUnitName\(index)",
                mediationAdUnitId: "TestAdUnitId\(index)"
            )

            adapter.impressionDataDidSucceed(impressionData)

            try await Task.sleep(nanoseconds: 100_000_000)

            let reportedAdRevenues = await MockAppMetrica.reportedAdRevenues
            XCTAssertEqual(reportedAdRevenues.count, index + 1, "Expected \(index + 1) reported ad revenues")

            if let lastReportedAdRevenue = reportedAdRevenues.last {
                XCTAssertEqual(lastReportedAdRevenue.adRevenue, NSDecimalNumber(value: Double(index) + 1.0), "Incorrect revenue value")
                XCTAssertEqual(lastReportedAdRevenue.currency, "USD", "Currency should always be USD")
                XCTAssertEqual(lastReportedAdRevenue.adType, testCase.expectedAdType, "Incorrect ad type for \(testCase.adUnit ?? "<nil>")")
                XCTAssertEqual(lastReportedAdRevenue.adNetwork, "TestNetwork\(index)", "Incorrect ad network")
                XCTAssertEqual(lastReportedAdRevenue.adPlacementName, "TestPlacement\(index)", "Incorrect placement name")
                XCTAssertEqual(lastReportedAdRevenue.precision, "TestPrecision\(index)", "Incorrect precision")
                XCTAssertEqual(lastReportedAdRevenue.adUnitName, "TestAdUnitName\(index)", "Incorrect instance name")
                XCTAssertEqual(lastReportedAdRevenue.adUnitID, "TestAdUnitId\(index)", "Incorrect instance name")
            } else {
                XCTFail("No ad revenue reported for test case \(index)")
            }
        }
    }

    func testMemoryLeakInAdapter() {
        weak var weakAdapter: AppMetricaIronSourceAdapter?

        autoreleasepool {
            let localAdapter = AppMetricaIronSourceAdapter(
                ironSourceType: MockIronSource.self, appMetricaType: MockAppMetrica.self)
            weakAdapter = localAdapter
            localAdapter.initialize()
        }

        XCTAssertNil(weakAdapter, "Adapter should be deallocated")
    }
}
