//
//  InnovLogger.swift
//  VodGuiOne
//
//  Created by KIRILL SIMAGIN on 22/02/2024.
//

import Foundation
import OSLog

public struct LogCategory {
    public let name: String
    
    public init(name: String) {
        self.name = name
    }
}
extension LogCategory {
    static let ui = LogCategory(name: "UI")
    static let network = LogCategory(name: "Network")
    static let xr = LogCategory(name: "XR")
}
extension Bundle {
    private static let defaultBundleName = "k6.vod.ui"
    enum LoggerSubsystemSuffix: String {
        case vod, tv, pub, xr
        func append(to bundle: String) -> String {
            return bundle + "." + self.rawValue
        }
    }
    static var vodLoggerSubsystem: String {
        guard let bndl = Bundle.main.bundleIdentifier else {
            return Self.defaultBundleName
        }
        return LoggerSubsystemSuffix.vod.append(to: bndl)
    }
    static var xrLoggerSubsystem: String {
        guard let bndl = Bundle.main.bundleIdentifier else {
            return Self.defaultBundleName
        }
        return LoggerSubsystemSuffix.xr.append(to: bndl)
    }
}
extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    
    static func logger(for category: LogCategory, and subsytem: String = subsystem) -> Logger {
            return Logger(subsystem: subsystem, category: category.name)
        }
    
//    static let uiLogger = Logger(subsystem: subsystem, category: "UI")
    
    static let xr = Logger.logger(for: .xr, and: Bundle.xrLoggerSubsystem)
    static let ui = Logger.logger(for: .ui)
}
