//
//  SPSessionController.swift
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

public protocol SessionController: SessionConfigurationProtocol {
    /// The session index.
    /// An increasing number which helps to order the sequence of sessions.
    var sessionIndex: Int { get }
    /// The session identifier.
    /// A unique identifier which is used to identify the session.
    var sessionId: String? { get }
    /// The session user identifier.
    /// It identifies this app installation and it doesn't change for the life of the app.
    /// It will change only when the app is uninstalled and installed again.
    /// An app update doesn't change the value.
    var userId: String? { get }
    /// Whether the app is currently in background state or in foreground state.
    var isInBackground: Bool { get }
    /// Count the number of background transitions in the current session.
    var backgroundIndex: Int { get }
    /// Count the number of foreground transitions in the current session.
    var foregroundIndex: Int { get }
    /// Pause the session tracking.
    /// Meanwhile the session is paused it can't expire and can't be updated.
    func pause()
    /// Resume the session tracking.
    func resume()
    /// Expire the current session also if the timeout is not triggered.
    func startNewSession()
}
