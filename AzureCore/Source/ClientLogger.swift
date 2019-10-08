//
//  ClientLogger.swift
//  AzureCore
//
//  Created by Brandon Siegel on 10/3/19.
//  Copyright © 2019 Azure SDK Team. All rights reserved.
//

import Foundation
import os.log

public enum ClientLogLevel: Int {
    case error, warning, info, debug
}

public protocol ClientLogger {
    var level: ClientLogLevel { get set }

    func debug(_: @autoclosure @escaping () -> String?)
    func info(_: @autoclosure @escaping () -> String?)
    func warning(_: @autoclosure @escaping () -> String?)
    func error(_: @autoclosure @escaping () -> String?)

    func log(_: @escaping () -> String?, atLevel: ClientLogLevel)
}

extension ClientLogger {
    public func debug(_ message: @escaping () -> String?) {
        log(message, atLevel: .debug)
    }

    public func info(_ message: @escaping () -> String?) {
        log(message, atLevel: .info)
    }

    public func warning(_ message: @escaping () -> String?) {
        log(message, atLevel: .warning)
    }

    public func error(_ message: @escaping () -> String?) {
        log(message, atLevel: .error)
    }

    public static func `default`() -> ClientLogger {
        if #available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
            return OSLogAdapter()
        } else {
            return NSLogger()
        }
    }
}

// MARK: - Implementations

public class NullLogger: ClientLogger {
    // Force the least verbose log level so consumers can check & avoid calling the logger entirely if desired
    public var level: ClientLogLevel {
        get { return .error }
        set { _ = newValue }
    }

    public func log(_ message: () -> String?, atLevel messageLevel: ClientLogLevel) { }
}

public class PrintLogger: ClientLogger {
    public var level: ClientLogLevel

    public init(level: ClientLogLevel = .warning) {
        self.level = level
    }

    public func log(_ message: () -> String?, atLevel messageLevel: ClientLogLevel) {
        if messageLevel.rawValue >= level.rawValue, let msg = message() {
            let tag = String(describing: messageLevel).uppercased()
            print("\(tag): \(msg)")
        }
    }
}

public class NSLogger: ClientLogger {
    public var level: ClientLogLevel

    public init(level: ClientLogLevel = .warning) {
        self.level = level
    }

    public func log(_ message: () -> String?, atLevel messageLevel: ClientLogLevel) {
        if messageLevel.rawValue >= level.rawValue, let msg = message() {
            let tag = String(describing: messageLevel).uppercased()
            NSLog("%@: %@", tag, msg)
        }
    }
}

@available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
public class OSLogAdapter: ClientLogger {
    // Force the most verbose log level so that all messages are forwarded to the OSLog framework
    public var level: ClientLogLevel {
        get { return .debug }
        set { _ = newValue }
    }

    private let osLogger: OSLog

    public init(withLogger osLogger: OSLog) {
        self.osLogger = osLogger
    }

    public convenience init(subsystem: String = "com.azure", category: String = "Pipeline") {
        self.init(withLogger: OSLog(subsystem: subsystem, category: category))
    }

    public func log(_ message: @escaping () -> String?, atLevel messageLevel: ClientLogLevel) {
        if let msg = message() {
            os_log("%@", log: osLogger, type: osLogTypeFor(messageLevel), msg)
        }
    }

    private func osLogTypeFor(_ level: ClientLogLevel) -> OSLogType {
        switch level {
        case .error:
            return .error
        case .warning:
            // os_log has no 'warning', mapped to 'error' as per suggestion by
            // https://forums.swift.org/t/logging-levels-for-swifts-server-side-logging-apis-and-new-os-log-apis/20365
            return .error
        case .info:
            return .info
        case .debug:
            return .debug
        }
    }
}
