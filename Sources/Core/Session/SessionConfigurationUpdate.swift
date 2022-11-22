//
//  SPSessionConfigurationUpdate.swift
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

@objc(SPSessionConfigurationUpdate)
public class SessionConfigurationUpdate: SessionConfiguration {
    @objc public var sourceConfig: SessionConfiguration?
    @objc public var isPaused = false
    var foregroundTimeoutInSecondsUpdated = false
    var backgroundTimeoutInSecondsUpdated = false
    var onSessionStateUpdateUpdated = false

    @objc public override var foregroundTimeoutInSeconds: Int {
        get {
            return ((sourceConfig == nil || foregroundTimeoutInSecondsUpdated) ? super.foregroundTimeoutInSeconds : sourceConfig?.foregroundTimeoutInSeconds) ?? 1800
        }
        set {
            super.foregroundTimeoutInSeconds = newValue
            foregroundTimeoutInSecondsUpdated = true
        }
    }

    @objc public override var backgroundTimeoutInSeconds: Int {
        get {
            return ((sourceConfig == nil || backgroundTimeoutInSecondsUpdated) ? super.backgroundTimeoutInSeconds : sourceConfig?.backgroundTimeoutInSeconds) ?? 1800
        }
        set {
            super.backgroundTimeoutInSeconds = newValue
            backgroundTimeoutInSecondsUpdated = true
        }
    }

    @objc public override var onSessionStateUpdate: ((_ sessionState: SessionState) -> Void)? {
        get {
            return ((sourceConfig == nil || onSessionStateUpdateUpdated) ? super.onSessionStateUpdate : sourceConfig?.onSessionStateUpdate)
        }
        set {
            super.onSessionStateUpdate = newValue
            onSessionStateUpdateUpdated = true
        }
    }
}
