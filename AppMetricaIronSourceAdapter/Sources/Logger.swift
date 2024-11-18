import Foundation
import os

final class Logger {
    static var isLoggingEnabled: Bool = false

    enum LogCategory: String {
        case general = "General"
        case impressions = "Impressions"
    }

    private let osLog: OSLog
    private let category: LogCategory

    private var logger: Any?

    init(subsystem: String, category: LogCategory) {
        self.category = category
        self.osLog = OSLog(subsystem: subsystem, category: category.rawValue)
        if #available(iOS 14.0, *) {
            self.logger = os.Logger(subsystem: subsystem, category: category.rawValue)
        }
    }

    func log(
        level: OSLogType, message: String, file: String = #file, function: String = #function,
        line: Int = #line
    ) {
        guard Self.isLoggingEnabled else { return }

        let metadata = "\(URL(fileURLWithPath: file).lastPathComponent):\(line) \(function)"

        if #available(iOS 14.0, *) {
            guard let logger = logger as? os.Logger else { return }
            switch level {
            case .debug:
                logger.debug("\(metadata, privacy: .public) \(message, privacy: .public)")
            case .info:
                logger.info("\(metadata, privacy: .public) \(message, privacy: .public)")
            case .error:
                logger.error("\(metadata, privacy: .public) \(message, privacy: .public)")
            case .fault:
                logger.critical("\(metadata, privacy: .public) \(message, privacy: .public)")
            default:
                logger.notice("\(metadata, privacy: .public) \(message, privacy: .public)")
            }
        } else {
            os_log("%{public}@ %{public}@", log: osLog, type: level, metadata, message)
        }
    }
}
