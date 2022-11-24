//  SPSessionConfiguration.swift
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

public protocol SessionConfigurationProtocol: AnyObject {
    /// The amount of time that can elapse before the
    /// session id is updated while the app is in the
    /// foreground.
    var foregroundTimeoutInSeconds: Int { get set }
    /// The amount of time that can elapse before the
    /// session id is updated while the app is in the
    /// background.
    var backgroundTimeoutInSeconds: Int { get set }
    /// The amount of time that can elapse before the
    /// session id is updated while the app is in the
    /// foreground.
    var foregroundTimeout: Measurement<UnitDuration> { get set }
    /// The amount of time that can elapse before the
    /// session id is updated while the app is in the
    /// background.
    var backgroundTimeout: Measurement<UnitDuration> { get set }
    /// The callback called everytime the session is updated.
    var onSessionStateUpdate: ((_ sessionState: SessionState) -> Void)? { get set }
}

/// This class represents the configuration from of the applications session.
/// The SessionConfiguration can be used to setup the behaviour of sessions.
///
/// A session is a context which is appended to each event sent.
/// The values it brings can change based on:
/// - the timeout set for the inactivity of app when in foreground;
/// - the timeout set for the inactivity of app when in background.
///
/// Session data is maintained for the life of the application being installed on a device.
/// A new session will be created if the session information is not accessed within a configurable timeout.
public class SessionConfiguration: Configuration, SessionConfigurationProtocol {
    public var backgroundTimeoutInSeconds: Int
    public var foregroundTimeoutInSeconds: Int
    public var onSessionStateUpdate: ((_ sessionState: SessionState) -> Void)?

    public convenience override init() {
        self.init(foregroundTimeoutInSeconds: 1800, backgroundTimeoutInSeconds: 1800)
    }

    public convenience init?(dictionary: [String : NSObject]) {
        let foregroundTimeout = dictionary["foregroundTimeout"] as? Int ?? TrackerDefaults.foregroundTimeout
        let backgroundTimeout = dictionary["backgroundTimeout"] as? Int ?? TrackerDefaults.backgroundTimeout
        self.init(foregroundTimeoutInSeconds: foregroundTimeout, backgroundTimeoutInSeconds: backgroundTimeout)
    }

    /// This will setup the session behaviour of the tracker.
    /// - Parameters:
    ///   - foregroundTimeout: The timeout set for the inactivity of app when in foreground.
    ///   - backgroundTimeout: The timeout set for the inactivity of app when in background.
    public convenience init(foregroundTimeout: Measurement<UnitDuration>, backgroundTimeout: Measurement<UnitDuration>) {
        let foreground = foregroundTimeout.converted(to: .seconds)
        let foregroundInSeconds = Int(floor(foreground.value))
        let background = backgroundTimeout.converted(to: .seconds)
        let backgroundInSeconds = Int(floor(background.value))
        self.init(foregroundTimeoutInSeconds: foregroundInSeconds, backgroundTimeoutInSeconds: Int(backgroundInSeconds))
    }

    /// This will setup the session behaviour of the tracker.
    /// - Parameters:
    ///   - foregroundTimeout: The timeout set for the inactivity of app when in foreground.
    ///   - backgroundTimeout: The timeout set for the inactivity of app when in background.
    public init(foregroundTimeoutInSeconds foregroundTimeout: Int, backgroundTimeoutInSeconds backgroundTimeout: Int) {
        self.backgroundTimeoutInSeconds = backgroundTimeout
        self.foregroundTimeoutInSeconds = foregroundTimeout
    }

    public var foregroundTimeout: Measurement<UnitDuration> {
        get {
            return Measurement(value: Double(foregroundTimeoutInSeconds), unit: .seconds)
        }
        set(foregroundTimeout) {
            let foreground = foregroundTimeout.converted(to: .seconds)
            foregroundTimeoutInSeconds = Int(floor(foreground.value))
        }
    }

    public var backgroundTimeout: Measurement<UnitDuration> {
        get {
            return Measurement(value: Double(backgroundTimeoutInSeconds), unit: .seconds)
        }
        set(backgroundTimeout) {
            let background = backgroundTimeout.converted(to: .seconds)
            backgroundTimeoutInSeconds = Int(floor(background.value))
        }
    }

    /// The callback called everytime the session is updated.

    // MARK: - Builders

    func onSessionStateUpdate(_ value: ((_ sessionState: SessionState) -> Void)?) -> Self {
        onSessionStateUpdate = value
        return self
    }

    // MARK: - NSCopying

    public override func copy(with zone: NSZone? = nil) -> Any {
        let copy = SessionConfiguration()
        copy.backgroundTimeoutInSeconds = backgroundTimeoutInSeconds
        copy.foregroundTimeoutInSeconds = foregroundTimeoutInSeconds
        copy.onSessionStateUpdate = onSessionStateUpdate
        return copy
    }

    // MARK: - NSSecureCoding
    
    public override class var supportsSecureCoding: Bool { return true }
    
    public override func encode(with coder: NSCoder) {
        coder.encode(backgroundTimeoutInSeconds, forKey: "backgroundTimeoutInSeconds")
        coder.encode(foregroundTimeoutInSeconds, forKey: "foregroundTimeoutInSeconds")
    }

    required init?(coder: NSCoder) {
        backgroundTimeoutInSeconds = coder.decodeInteger(forKey: "backgroundTimeoutInSeconds")
        foregroundTimeoutInSeconds = coder.decodeInteger(forKey: "foregroundTimeoutInSeconds")
        super.init()
    }
}
