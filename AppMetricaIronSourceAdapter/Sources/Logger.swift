import Foundation
import AppMetricaLogSwift
import AppMetricaLog

final class Logger {
    static var isLoggingEnabled: Bool = false

    enum LogCategory: String {
        case general = "General"
        case impressions = "Impressions"
    }

    private var logger: AppMetricaLogSwift.Logger

    init(category: LogCategory) {
        self.logger = AppMetricaLogSwift.Logger(channel: category.rawValue as LogChannel)
    }
    
    // TODO: [https://nda.ya.ru/t/3D5qG9OV7CLvuR] Add debug level; Add ability to set subsystem
    func log(level: AppMetricaLogSwift.LogLevel, message: String) {
        guard Self.isLoggingEnabled else { return }
        
        switch level {
        case .notify:
            logger.notify(message)
        case .info:
            logger.info(message)
        case .error:
            logger.error(message)
        case .warning:
            logger.warning(message)
        }
    }
}
