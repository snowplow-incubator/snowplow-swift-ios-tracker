//
//  SPSessionControllerImpl.swift
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

@objc(SPSessionControllerImpl)
public class SessionControllerImpl: Controller, SessionController {
    var isEnabled: Bool {
        return session != nil
    }

    public func pause() {
        dirtyConfig.isPaused = true
        session?.stopChecker()
    }

    public func resume() {
        dirtyConfig.isPaused = false
        session?.startChecker()
    }

    public func startNewSession() {
        session?.startNewSession()
    }

    // MARK: - Properties

    public var foregroundTimeout: Measurement<UnitDuration> {
        get {
            return Measurement(value: Double(foregroundTimeoutInSeconds), unit: .seconds)
        }
        set {
            let foreground = newValue.converted(to: .seconds)
            foregroundTimeoutInSeconds = Int(foreground.value)
        }
    }

    public var foregroundTimeoutInSeconds: Int {
        get {
            if let session = session {
                if isEnabled {
                    return Int(session.getForegroundTimeout() / 1000)
                } else {
//                    SPLogTrack(nil, "Attempt to access SessionController fields when disabled")
                }
            }
            return -1
        }
        set {
            dirtyConfig.foregroundTimeoutInSeconds = newValue
            dirtyConfig.foregroundTimeoutInSecondsUpdated = true
            session?.setForegroundTimeout(newValue * 1000)
        }
    }

    public var backgroundTimeout: Measurement<UnitDuration> {
        get {
            return Measurement(value: Double(backgroundTimeoutInSeconds), unit: .seconds)
        }
        set {
            let background = newValue.converted(to: .seconds)
            backgroundTimeoutInSeconds = Int(background.value)
        }
    }

    public var backgroundTimeoutInSeconds: Int {
        get {
            if let session = session {
                if isEnabled {
                    return Int(session.getBackgroundTimeout() / 1000)
                } else {
//                    SPLogTrack(nil, "Attempt to access SessionController fields when disabled")
                }
            }
            return -1
        }
        set {
            dirtyConfig.backgroundTimeoutInSeconds = newValue
            dirtyConfig.backgroundTimeoutInSecondsUpdated = true
            session?.setBackgroundTimeout(newValue * 1000)
        }
    }

    public var onSessionStateUpdate: ((_ sessionState: SPSessionState) -> Void)? {
        get {
            if !isEnabled {
//                SPLogTrack(nil, "Attempt to access SessionController fields when disabled")
                return nil
            }
            return session?.onSessionStateUpdate
        }
        set {
            dirtyConfig.onSessionStateUpdate = newValue
            dirtyConfig.onSessionStateUpdateUpdated = true
            session?.onSessionStateUpdate = newValue
        }
    }

    public var sessionIndex: Int {
        if !isEnabled {
//            SPLogTrack(nil, "Attempt to access SessionController fields when disabled")
            return -1
        }
        return session?.state?.sessionIndex ?? -1
    }

    public var sessionId: String? {
        if !isEnabled {
//            SPLogTrack(nil, "Attempt to access SessionController fields when disabled")
            return nil
        }
        return session?.state?.sessionId
    }

    public var userId: String? {
        if !isEnabled {
//            SPLogTrack(nil, "Attempt to access SessionController fields when disabled")
            return nil
        }
        return session?.getUserId()
    }

    public var isInBackground: Bool {
        if !isEnabled {
//            SPLogTrack(nil, "Attempt to access SessionController fields when disabled")
            return false
        }
        return session?.getInBackground() ?? false
    }

    public var backgroundIndex: Int {
        if !isEnabled {
//            SPLogTrack(nil, "Attempt to access SessionController fields when disabled")
            return -1
        }
        return session?.getBackgroundIndex() ?? -1
    }

    public var foregroundIndex: Int {
        if !isEnabled {
//            PLogTrack(nil, "Attempt to access SessionController fields when disabled")
            return -1
        }
        return session?.getForegroundIndex() ?? -1
    }

    // MARK: - Private methods

    private var session: Session? {
        get {
            return serviceProvider.tracker().session
        }
    }

    private var dirtyConfig: SessionConfigurationUpdate {
        get {
            return serviceProvider.sessionConfigurationUpdate()
        }
    }
}
