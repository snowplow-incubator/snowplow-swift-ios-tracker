//
//  SPEmitter.swift
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
//  Authors: Jonathan Almeida, Joshua Beemster
//  License: Apache License Version 2.0
//

import Foundation

/// The builder for Emitter.
@objc
public protocol EmitterBuilder: NSObjectProtocol {
    var namespace: String? { get set }
    /// Emitter builder method to set the collector endpoint.
    /// - Parameter urlEndpoint: The collector endpoint.
    var urlEndpoint: String? { get set }
    /// Emitter builder method to set HTTP method.
    /// - Parameter method: Should be HttpMethodGet or HttpMethodPost.
    var method: HttpMethodOptions { get set }
    /// Emitter builder method to set HTTP security.
    /// - Parameter protocol: Should be ProtocolHttp or ProtocolHttps.
    var `protocol`: ProtocolOptions { get set }
    /// Emitter builder method to set the buffer option.
    /// - Parameter bufferOption: the buffer option for the emitter.
    var bufferOption: BufferOption { get set }
    /// Emitter builder method to set callbacks.
    /// - Parameter callback: Called on when events have sent.
    var callback: RequestCallback? { get set }
    /// Emitter builder method to set emit range.
    /// - Parameter emitRange: Number of events to pull from database.
    var emitRange: Int { get set }
    /// Emitter builder method to set thread pool size.
    /// - Parameter emitThreadPoolSize: The number of threads used by the emitter.
    var emitThreadPoolSize: Int { get set }
    /// Emitter builder method to set byte limit for GET requests.
    /// - Parameter byteLimitGet: Maximum event size for a GET request.
    var byteLimitGet: Int { get set }
    /// Emitter builder method to set byte limit for POST requests.
    /// - Parameter byteLimitPost: Maximum event size for a POST request.
    var byteLimitPost: Int { get set }
    /// Emitter builder method to set a custom POST path.
    /// - Parameter customPath: A custom path that is used on the endpoint to send requests.
    var customPostPath: String? { get set }
    /// Emitter builder method to set the server anonymisation flag.
    /// - Parameter serverAnonymisation:  Whether to anonymise server-side user identifiers including the `network_userid` and `user_ipaddress`
    var serverAnonymisation: Bool { get set }
    /// Builder method to set request headers.
    /// - Parameter requestHeadersKeyValue: custom headers (key, value) for http requests.
    var requestHeaders: [String : String]? { get set }
    /// Emitter builder method to set NetworkConnection component.
    /// - Parameter networkConnection: The component in charge for sending events to the collector.
    var networkConnection: NetworkConnection? { get set }
    /// Emitter builder method to set EventStore component.
    /// - Parameter eventStore: The component in charge for persisting events before sending.
    var eventStore: EventStore? { get set }
    /// Set a custom retry rules for HTTP status codes received in emit responses from the Collector.
    /// - Parameter customRetryForStatusCodes: Mapping of integers (status codes) to booleans (true for retry and false for not retry)
    var customRetryForStatusCodes: [NSNumber : NSNumber]? { get set }
}
