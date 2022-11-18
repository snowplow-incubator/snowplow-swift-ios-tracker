//
//  SPNetworkConnection.swift
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

func NS_ENUM(_ NSInteger: Int, _ SPHttpMethod: Int) {
}

/// Interface for the component that
/// sends events to the collector.
@objc public protocol NetworkConnection: NSObjectProtocol {
    /// Send requests to the collector.
    /// - Parameter requests: to send,
    /// - Returns: results of the sending operation.
    func sendRequests(_ requests: [Request]) -> [RequestResult]
    /// - Returns: http method used to send requests to the collector.
    var httpMethod: HttpMethodOptions { get }
    /// - Returns: URL of the collector.
    var urlEndpoint: URL? { get }
}
