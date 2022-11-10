//  Converted to Swift 5.7 by Swiftify v5.7.28606 - https://swiftify.com/
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

@objc(SPSessionConfigurationUpdate)
public class SessionConfigurationUpdate: SessionConfiguration {
    var sourceConfig: SessionConfiguration?
    var isPaused = false
    var foregroundTimeoutInSecondsUpdated = false
    var backgroundTimeoutInSecondsUpdated = false
    var onSessionStateUpdateUpdated = false

    func foregroundTimeoutInSeconds() -> Int {
        return ((sourceConfig == nil || foregroundTimeoutInSecondsUpdated) ? super.foregroundTimeoutInSeconds : sourceConfig?.foregroundTimeoutInSeconds) ?? 0
    }

    func backgroundTimeoutInSeconds() -> Int {
        return ((sourceConfig == nil || backgroundTimeoutInSecondsUpdated) ? super.backgroundTimeoutInSeconds : sourceConfig?.backgroundTimeoutInSeconds) ?? 0
    }

    func onSessionStateUpdate() -> OnSessionStateUpdate {
        return ((sourceConfig == nil || onSessionStateUpdateUpdated) ? super.onSessionStateUpdate : sourceConfig?.onSessionStateUpdate)!
    }
}
