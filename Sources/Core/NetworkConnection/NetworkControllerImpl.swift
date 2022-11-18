//
//  SPNetworkControllerImpl.swift
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

@objc(SPNetworkControllerImpl)
public class NetworkControllerImpl: Controller, NetworkController {
    private var requestCallback: RequestCallback?

    public var isCustomNetworkConnection: Bool {
        return emitter.networkConnection != nil && !(emitter.networkConnection is DefaultNetworkConnection)
    }

    // MARK: - Properties

    public var endpoint: String? {
        get {
            return emitter.urlEndpoint
        }
        set {
            emitter.urlEndpoint = newValue
        }
    }

    public var method: HttpMethodOptions {
        get {
            return emitter.method
        }
        set {
            emitter.method = newValue
        }
    }

    public var customPostPath: String? {
        get {
            return emitter.customPostPath
        }
        set {
            dirtyConfig.customPostPath = newValue
            dirtyConfig.customPostPathUpdated = true
            emitter.customPostPath = newValue
        }
    }

    public var requestHeaders: [String : String]? {
        get {
            return emitter.requestHeaders
        }
        set {
            dirtyConfig.requestHeaders = requestHeaders
            dirtyConfig.requestHeadersUpdated = true
            emitter.requestHeaders = newValue
        }
    }

    // MARK: - Private methods

    private var emitter: Emitter {
        return serviceProvider.tracker().emitter
    }

    private var dirtyConfig: NetworkConfigurationUpdate {
        return serviceProvider.networkConfigurationUpdate()
    }
}
