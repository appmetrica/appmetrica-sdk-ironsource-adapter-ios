import AppMetricaCore
import IronSource
import os.log

extension AdType {
    init(adUnit: String?) {
        guard let adUnit = adUnit else {
            self = .unknown
            return
        }
        
        switch adUnit
        {
        case ISAdUnit.is_AD_UNIT_REWARDED_VIDEO().value:
            self = .rewarded
        case ISAdUnit.is_AD_UNIT_INTERSTITIAL().value:
            self = .interstitial
        case ISAdUnit.is_AD_UNIT_BANNER().value:
            self = .banner
        case ISAdUnit.is_AD_UNIT_NATIVE_AD().value:
            self = .native
        default:
            self = .other
        }
    }
}
