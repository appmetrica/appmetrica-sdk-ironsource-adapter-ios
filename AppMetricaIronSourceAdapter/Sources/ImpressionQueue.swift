import Foundation
import IronSource

actor ImpressionQueue {
    private var queue: [LPMImpressionData] = []
    
    func enqueue(_ impressionData: LPMImpressionData) {
        queue.append(impressionData)
    }
    
    func dequeueAll() -> [LPMImpressionData] {
        defer { queue.removeAll(keepingCapacity: true) }
        return queue
    }
}
