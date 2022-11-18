//
//  SPNetworkConfigurationUpdate.swift
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

@objc(SPNetworkConfigurationUpdate)
public class NetworkConfigurationUpdate: NSObject {
    @objc public var sourceConfig: NetworkConfiguration?

    var customPostPathUpdated = false
    private var _customPostPath: String?
    @objc public var customPostPath: String? {
        get {
            return customPostPathUpdated ? _customPostPath : sourceConfig?.customPostPath
        }
        set {
            _customPostPath = newValue
            customPostPathUpdated = true
        }
    }

    var requestHeadersUpdated = false
    private var _requestHeaders: [String : String]?
    @objc public var requestHeaders: [String : String]? {
        get {
            return requestHeadersUpdated ? _requestHeaders : sourceConfig?.requestHeaders
        }
        set {
            _requestHeaders = newValue
            requestHeadersUpdated = true
        }
    }

    @objc public var endpoint: String? {
        return (sourceConfig)?.endpoint
    }

    @objc public var method: HttpMethodOptions {
        // TODO: return nil
        return ((sourceConfig)?.method) ?? .post
    }

    @objc public var `protocol`: ProtocolOptions {
        // TODO: return nil
        return ((sourceConfig)?.protocol) ?? .https
    }

    @objc public var networkConnection: NetworkConnection? {
        return (sourceConfig)?.networkConnection
    }
}
