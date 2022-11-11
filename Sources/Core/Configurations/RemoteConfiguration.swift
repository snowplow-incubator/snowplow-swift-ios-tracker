//  SPRemoteConfiguration.swift
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

/// Represents the configuration for fetching configurations from a remote source.
/// For details on the correct format of a remote configuration see the official documentation.
@objc(SPRemoteConfiguration)
public class RemoteConfiguration: Configuration {
    /// URL of the remote configuration.
    private(set) var endpoint: String
    /// The method used to send the request.
    private(set) var method: HttpMethodOptions?

    /// - Parameters:
    ///   - endpoint: URL of the remote configuration.
    ///                 The URL can include the schema/protocol (e.g.: `http://remote-config-url.xyz`).
    ///                 In case the URL doesn't include the schema/protocol, the HTTPS protocol is
    ///                 automatically selected.
    ///   - method: The method used to send the requests (GET or POST).
    init(endpoint: String, method: HttpMethodOptions?) {
        let url = URL(string: endpoint)
        if url?.scheme != nil && ["https", "http"].contains(url?.scheme ?? "") {
            self.endpoint = endpoint
        } else {
            self.endpoint = "https://\(endpoint)"
        }
        self.method = method
    }

    // MARK: - NSCopying

    override public func copy(with zone: NSZone? = nil) -> Any {
        return RemoteConfiguration(endpoint: endpoint, method: method)
    }

    // MARK: - NSSecureCoding

    override public func encode(with coder: NSCoder) {
        coder.encode(endpoint, forKey: "endpoint")
        coder.encode(method?.rawValue, forKey: "method")
    }

    required init?(coder: NSCoder) {
        if let endpoint = coder.decodeObject(forKey: "endpoint") as? String {
            self.endpoint = endpoint
            method = HttpMethodOptions(rawValue: coder.decodeInteger(forKey: "method"))
        } else {
            return nil
        }
    }
}
