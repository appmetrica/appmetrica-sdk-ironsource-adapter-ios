import AppMetricaCoreExtension
import IronSource

// Needed to make AdRevenueInfo Hashsable for Set
struct AdRevenueData: Hashable {
    let adRevenue: NSDecimalNumber
    let currency: String
    let adType: AdType
    let adNetwork: String?
    let adUnitID: String?
    let adUnitName: String?
    let adPlacementID: String?
    let adPlacementName: String?
    let precision: String?
}

extension AdRevenueInfo {
    var testRevenueData: AdRevenueData {
        return AdRevenueData(
            adRevenue: self.adRevenue,
            currency: self.currency,
            adType: self.adType,
            adNetwork: self.adNetwork,
            adUnitID: self.adUnitID,
            adUnitName: self.adUnitName,
            adPlacementID: self.adPlacementID,
            adPlacementName: self.adPlacementName,
            precision: self.precision
        )
    }
}

class MockIronSource: LevelPlay {
    static var addCalled = false
    static var removeCalled = false

    static func reset() {
        addCalled = false
        removeCalled = false
    }

    override open class func add(_ delegate: any LPMImpressionDataDelegate) {
        addCalled = true
    }

    override open class func remove(_ delegate: any LPMImpressionDataDelegate) {
        removeCalled = true
    }

    override class func sdkVersion() -> String {
        return "MockVersion"
    }
}

class MockAppMetrica: AppMetrica {
    private static var activationLock = NSLock()
    private static var _isActivated: Bool = false
    private static let state = StateActor()

    actor StateActor {
        private(set) var addCalled: Bool = false
        private(set) var reportAdRevenueCalled: Bool = false
        private(set) var reportedAdRevenues: [AdRevenueInfo] = []
        private(set) var reportAdRevenueCallCount: Int = 0
        private(set) var registerSourceCalled: Bool = false
        private(set) var registerSources: [String] = []
        private(set) var registerSourceCallCount: Int = 0

        func reset() {
            addCalled = false
            reportAdRevenueCalled = false
            reportedAdRevenues.removeAll()
            reportAdRevenueCallCount = 0
            registerSourceCalled = false
            registerSourceCallCount = 0
            registerSources.removeAll()
        }

        func setAddCalled() {
            addCalled = true
        }

        func reportAdRevenue(_ adRevenue: AdRevenueInfo) {
            reportAdRevenueCalled = true
            reportedAdRevenues.append(adRevenue)
            reportAdRevenueCallCount += 1
        }
        
        func registerSourceCalled(_ src: String) {
            registerSourceCalled = true
            registerSources.append(src)
            registerSourceCallCount += 1
        }
    }

    static func setIsActivated(_ value: Bool) {
        activationLock.lock()
        defer { activationLock.unlock() }
        _isActivated = value
    }

    override class var isActivated: Bool {
        activationLock.lock()
        defer { activationLock.unlock() }
        return _isActivated
    }

    static func reset() async {
        _isActivated = false
        await state.reset()
    }
    
    override class func registerAdRevenueNativeSource(_ source: String) {
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            await state.registerSourceCalled(source)
            semaphore.signal()
        }
        
        semaphore.wait()
    }

    override class func add(_ delegate: any ModuleActivationDelegate.Type) {
        Task {
            await state.setAddCalled()
        }
    }

    override open class func reportAdRevenue(
        _ adRevenue: AdRevenueInfo, onFailure: ((any Error) -> Void)? = nil
    ) {
        Task {
            await state.reportAdRevenue(adRevenue)
        }
    }
    
    override class func reportAdRevenue(
        _ adRevenue: AdRevenueInfo,
        isAutocollected: Bool,
        onFailure: ((any Error) -> Void)? = nil
    ) {
        Task {
            await state.reportAdRevenue(adRevenue)
        }
    }
    
    static var registerSourceCalled: Bool {
        get async {
            await state.registerSourceCalled
        }
    }
    
    static var registerSourceCallCount: Int {
        get async {
            await state.registerSourceCallCount
        }
    }
    
    static var registerSources: [String] {
        get async {
            await state.registerSources
        }
    }

    static var addCalled: Bool {
        get async {
            await state.addCalled
        }
    }

    static var reportAdRevenueCalled: Bool {
        get async {
            await state.reportAdRevenueCalled
        }
    }

    static var reportedAdRevenues: [AdRevenueInfo] {
        get async {
            await state.reportedAdRevenues
        }
    }

    static var reportAdRevenueCallCount: Int {
        get async {
            await state.reportAdRevenueCallCount
        }
    }
}

class MockISImpressionData: LPMImpressionData {
    let mockAdFormat: String?
    let mockRevenue: NSNumber?
    let mockAdNetwork: String?
    let mockPlacement: String?
    let mockPrecision: String?
    let mockMediationAdUnitName: String?
    let mockMediationAdUnitId: String?

    init(
        adUnit: String?, revenue: NSNumber?, adNetwork: String?, placement: String?, precision: String?,
        mediationAdUnitName: String?, mediationAdUnitId: String?
    ) {
        self.mockAdFormat = adUnit
        self.mockRevenue = revenue
        self.mockAdNetwork = adNetwork
        self.mockPlacement = placement
        self.mockPrecision = precision
        self.mockMediationAdUnitName = mediationAdUnitName
        self.mockMediationAdUnitId = mediationAdUnitId
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var adFormat: String? { return mockAdFormat }
    override var revenue: NSNumber? { return mockRevenue }
    override var adNetwork: String? { return mockAdNetwork }
    override var placement: String? { return mockPlacement }
    override var precision: String? { return mockPrecision }
    override var mediationAdUnitName: String? { return mockMediationAdUnitName }
    override var mediationAdUnitId: String? { return mockMediationAdUnitId }
}
