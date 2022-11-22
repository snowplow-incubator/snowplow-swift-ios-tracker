//
//  Logger.swift
//  Snowplow
//
//  Copyright (c) 2013-2022 Snowplow Analytics Ltd. All rights reserved.
//
//  This program is licensed to you under the Apache License Version 2.0,
//  and you may not use this file except in compliance with the Apache License
//  Version 2.0. You may obtain a copy of the Apache License Version 2.0 at
//  http://www.apache.org/licenses/LICENSE-2.0.
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the Apache License Version 2.0 is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
//  express or implied. See the Apache License Version 2.0 for the specific
//  language governing permissions and limitations there under.
//
//  Authors: Alex Benini
//  License: Apache License Version 2.0
//

import Foundation

//func SPLogTrack(_ errorOrException: Any?, _ format: String)

//#define SPLogTrack(optionalErrorOrException, format, ...) [SPLogger diagnostic:NSStringFromClass(self.class) message:[[NSString alloc] initWithFormat:format, ##__VA_ARGS__] errorOrException:optionalErrorOrException]
//#define SPLogError(format, ...) [SPLogger error:NSStringFromClass(self.class) message:[[NSString alloc] initWithFormat:format, ##__VA_ARGS__]]
//#define SPLogDebug(format, ...) [SPLogger debug:NSStringFromClass(self.class) message:[[NSString alloc] initWithFormat:format, ##__VA_ARGS__]]
//#define SPLogVerbose(format, ...) [SPLogger verbose:NSStringFromClass(self.class) message:[[NSString alloc] initWithFormat:format, ##__VA_ARGS__]]

public class Logger: NSObject {
    private static var _logLevel: LogLevel = .off
    public class var logLevel: LogLevel {
        get {
            return _logLevel
        }
        set(logLevel) {
            _logLevel = logLevel
            if logLevel == .off {
                #if SNOWPLOW_DEBUG
                _logLevel = .debug
                #elseif DEBUG
                _logLevel = .error
                #else
                _logLevel = .off
                #endif
            }
        }
    }

    public static var delegate: LoggerDelegate?

    public class func diagnostic(_ tag: String, message: String, errorOrException: Any?) {
        log(.error, tag: tag, message: message)
        trackError(withTag: tag, message: message, errorOrException: errorOrException)
    }

    public class func error(_ tag: String, message: String) {
        log(.error, tag: tag, message: message)
    }

    public class func debug(_ tag: String, message: String) {
        log(.debug, tag: tag, message: message)
    }

    public class func verbose(_ tag: String, message: String) {
        log(.verbose, tag: tag, message: message)
    }

    // MARK: - Private methods

    private class func log(_ level: LogLevel, tag: String, message: String) {
        if level.rawValue > logLevel.rawValue {
            return
        }
        if let delegate {
            switch level {
            case .off:
                // do nothing.
                break
            case .error:
                delegate.error(tag, message: message)
            case .debug:
                delegate.debug(tag, message: message)
            case .verbose:
                delegate.verbose(tag, message: message)
            @unknown default:
                break
            }
            return
        }
        #if SNOWPLOW_TEST
        // NSLog doesn't work on test target
        let output = "[\(["Off", "Error", "Error", "Debug", "Verbose"][level])] \(tag): \(message)"
        print("\(output.utf8CString)")
        #elseif DEBUG
        // Log should be printed only during debugging
        print("[\(["Off", "Error", "Debug", "Verbose"][level])] \(tag): \(message)")
        #endif
    }

    private class func trackError(withTag tag: String, message: String, errorOrException: Any?) {
        var error: Error?
        var exception: NSException?
        if errorOrException is Error {
            error = errorOrException as? Error
        } else if errorOrException is NSException {
            exception = errorOrException as? NSException
        }

        // Construct userInfo
        var userInfo: [String : NSObject] = [:]
        userInfo["tag"] = tag as NSObject
        userInfo["message"] = message as NSObject
        userInfo["error"] = error as NSObject?
        userInfo["exception"] = exception as NSObject?

        // Send notification to tracker
        NotificationCenter.default.post(
            name: NSNotification.Name("SPTrackerDiagnostic"),
            object: self,
            userInfo: userInfo)
    }
}
