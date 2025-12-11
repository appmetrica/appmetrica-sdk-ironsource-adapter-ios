import AppMetricaIronSourceAdapter
import IronSource
import SwiftUI

struct ContentView: View {
    @State private var auctionId = "test_auction_id"
    @State private var adFormat = "rewarded_video"
    @State private var adNetwork = "test_network"
    @State private var instanceName = "test_instance"
    @State private var instanceId = "test_id"
    @State private var country = "US"
    @State private var placement = "test_placement"
    @State private var revenue = "0.05"
    @State private var precision = "high"
    @State private var ab = "test_ab"
    @State private var segmentName = "test_segment"
    @State private var lifetimeRevenue = "1.5"
    @State private var encryptedCPM = "test_encrypted_cpm"
    @State private var conversionValue = "10"
    
    @State private var lastAction = ""
    @State private var impressionsSent = 0
    
    let adUnits = [
        "rewarded_video",
        "interstitial",
        "banner",
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Group {
                    HStack {
                        Text("Auction ID").frame(width: 120, alignment: .leading)
                        TextField("", text: $auctionId)
                    }
                    HStack {
                        Text("Ad Unit").frame(width: 120, alignment: .leading)
                        Picker("", selection: $adFormat) {
                            ForEach(adUnits, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                    }
                    HStack {
                        Text("Ad Network").frame(width: 120, alignment: .leading)
                        TextField("", text: $adNetwork)
                    }
                    HStack {
                        Text("Instance Name").frame(width: 120, alignment: .leading)
                        TextField("", text: $instanceName)
                    }
                    HStack {
                        Text("Instance ID").frame(width: 120, alignment: .leading)
                        TextField("", text: $instanceId)
                    }
                    HStack {
                        Text("Country").frame(width: 120, alignment: .leading)
                        TextField("", text: $country)
                    }
                    HStack {
                        Text("Placement").frame(width: 120, alignment: .leading)
                        TextField("", text: $placement)
                    }
                    HStack {
                        Text("Revenue").frame(width: 120, alignment: .leading)
                        TextField("", text: $revenue)
                            .keyboardType(.decimalPad)
                    }
                    HStack {
                        Text("Precision").frame(width: 120, alignment: .leading)
                        TextField("", text: $precision)
                    }
                    HStack {
                        Text("AB").frame(width: 120, alignment: .leading)
                        TextField("", text: $ab)
                    }
                }
                Group {
                    HStack {
                        Text("Segment Name").frame(width: 120, alignment: .leading)
                        TextField("", text: $segmentName)
                    }
                    HStack {
                        Text("Lifetime Revenue").frame(width: 120, alignment: .leading)
                        TextField("", text: $lifetimeRevenue)
                            .keyboardType(.decimalPad)
                    }
                    HStack {
                        Text("Encrypted CPM").frame(width: 120, alignment: .leading)
                        TextField("", text: $encryptedCPM)
                    }
                    HStack {
                        Text("Conversion Value").frame(width: 120, alignment: .leading)
                        TextField("", text: $conversionValue)
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()
        }
        
        VStack {
            Text("Impressions Sent: \(impressionsSent)")
            Text("Last Action: \(lastAction)")
            
            Button("Send Impression Data") {
                sendImpressionData()
            }
            .padding(.all, 10.0)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }.padding(.bottom, 5.0)
    }
    
    private func sendImpressionData() {
        let impressionData = LPMImpressionData(dictionary: [
            kImpressionDataKeyAuctionId: auctionId,
            kImpressionDataKeyAdFormat: adFormat,
            kImpressionDataKeyAdUnit: adFormat,
            kImpressionDataKeyAdNetwork: adNetwork,
            kImpressionDataKeyInstanceName: instanceName,
            kImpressionDataKeyInstanceId: instanceId,
            kImpressionDataKeyCountry: country,
            kImpressionDataKeyPlacement: placement,
            kImpressionDataKeyRevenue: NSNumber(value: Double(revenue) ?? 0),
            kImpressionDataKeyPrecision: precision,
            kImpressionDataKeyAb: ab,
            kImpressionDataKeySegmentName: segmentName,
            kImpressionDataKeyLifetimeRevenue: NSNumber(value: Double(lifetimeRevenue) ?? 0),
            kImpressionDataKeyEncryptedCPM: encryptedCPM,
            kImpressionDataKeyConversionValue: NSNumber(value: Int(conversionValue) ?? 0),
        ])
        
        AppMetricaIronSourceAdapter.shared.impressionDataDidSucceed(impressionData)
        impressionsSent += 1
        lastAction = "Sent impression data #\(impressionsSent)"
    }
}

#Preview {
    ContentView()
}
