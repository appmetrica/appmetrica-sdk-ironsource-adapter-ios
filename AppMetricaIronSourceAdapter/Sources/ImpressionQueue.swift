import Foundation
import IronSource

actor ImpressionQueue {
    private var queue: [ISImpressionData] = []
    
    func enqueue(_ impressionData: ISImpressionData) {
        queue.append(impressionData)
    }
    
    func dequeueAll() -> [ISImpressionData] {
        defer { queue.removeAll(keepingCapacity: true) }
        return queue
    }
}
