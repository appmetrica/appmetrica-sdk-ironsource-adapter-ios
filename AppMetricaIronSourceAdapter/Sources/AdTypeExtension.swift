import AppMetricaCore
import IronSource
import os.log

extension AdType {
    
    private static let adUnitRewarded = "rewarded_video";
    private static let adUnitInterstitial = "interstitial";
    private static let adUnitBanner = "banner";
    
    init(adUnit: String?) {
        switch adUnit {
        case Self.adUnitRewarded:
            self = .rewarded
        case Self.adUnitInterstitial:
            self = .interstitial
        case Self.adUnitBanner:
            self = .banner
        case nil:
            self = .unknown
        default:
            self = .other
        }
    }
}
