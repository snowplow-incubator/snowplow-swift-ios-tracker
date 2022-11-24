//  SPEmitterConfiguration.swift
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

public protocol EmitterConfigurationProtocol: AnyObject {
    /// Sets whether the buffer should send events instantly or after the buffer
    /// has reached it's limit. By default, this is set to BufferOption Default.
    var bufferOption: BufferOption { get set }
    /// Maximum number of events collected from the EventStore to be sent in a request.
    var emitRange: Int { get set }
    /// Maximum number of threads working in parallel in the tracker to send requests.
    var threadPoolSize: Int { get set }
    /// Maximum amount of bytes allowed to be sent in a payload in a GET request.
    var byteLimitGet: Int { get set }
    /// Maximum amount of bytes allowed to be sent in a payload in a POST request.
    var byteLimitPost: Int { get set }
    /// Callback called for each request performed by the tracker to the collector.
    var requestCallback: RequestCallback? { get set }
    ///  Custom retry rules for HTTP status codes returned from the Collector.
    ///  The dictionary is a mapping of integers (status codes) to booleans (true for retry and false for not retry).
    var customRetryForStatusCodes: [Int : Bool]? { get set }
    /// Whether to anonymise server-side user identifiers including the `network_userid` and `user_ipaddress`
    var serverAnonymisation: Bool { get set }
}

/// It allows the tracker configuration from the emission perspective.
/// The EmitterConfiguration can be used to setup details about how the tracker should treat the events
/// to emit to the collector.
public class EmitterConfiguration: Configuration, EmitterConfigurationProtocol {
    /// Sets whether the buffer should send events instantly or after the buffer
    /// has reached it's limit. By default, this is set to BufferOption Default.
    public var bufferOption: BufferOption = EmitterDefaults.bufferOption

    /// Maximum number of events collected from the EventStore to be sent in a request.
    public var emitRange: Int = EmitterDefaults.emitRange

    /// Maximum number of threads working in parallel in the tracker to send requests.
    public var threadPoolSize: Int = EmitterDefaults.emitThreadPoolSize

    /// Maximum amount of bytes allowed to be sent in a payload in a GET request.
    public var byteLimitGet: Int = EmitterDefaults.byteLimitGet

    /// Maximum amount of bytes allowed to be sent in a payload in a POST request.
    public var byteLimitPost: Int = EmitterDefaults.byteLimitPost

    /// Callback called for each request performed by the tracker to the collector.
    public var requestCallback: RequestCallback?

    /// Custom retry rules for HTTP status codes returned from the Collector.
    /// The dictionary is a mapping of integers (status codes) to booleans (true for retry and false for not retry).
    public var customRetryForStatusCodes: [Int : Bool]?

    /// Whether to anonymise server-side user identifiers including the `network_userid` and `user_ipaddress`
    public var serverAnonymisation: Bool = EmitterDefaults.serverAnonymisation

    /// Custom component with full ownership for persisting events before to be sent to the collector.
    /// If it's not set the tracker will use a SQLite database as default EventStore.
    public var eventStore: EventStore?

    /// It sets a default EmitterConfiguration.
    /// Default values:
    ///         bufferOption = BufferOption.Single;
    ///         emitRange = 150;
    ///         threadPoolSize = 15;
    ///         byteLimitGet = 40000;
    ///         byteLimitPost = 40000;
    ///         serverAnonymisation = false;
    public override init() {
        super.init()
    }

    // MARK: - NSCopying

    public override func copy(with zone: NSZone? = nil) -> Any {
        let copy = EmitterConfiguration()
        copy.bufferOption = bufferOption
        copy.emitRange = emitRange
        copy.threadPoolSize = threadPoolSize
        copy.byteLimitGet = byteLimitGet
        copy.byteLimitPost = byteLimitPost
        copy.requestCallback = requestCallback
        copy.eventStore = eventStore
        copy.customRetryForStatusCodes = customRetryForStatusCodes
        copy.serverAnonymisation = serverAnonymisation
        return copy
    }

    // MARK: - NSSecureCoding
    
    public override class var supportsSecureCoding: Bool { return true }

    public override func encode(with coder: NSCoder) {
        coder.encode(bufferOption, forKey: "bufferOption")
        coder.encode(emitRange, forKey: "emitRange")
        coder.encode(threadPoolSize, forKey: "threadPoolSize")
        coder.encode(byteLimitGet, forKey: "byteLimitGet")
        coder.encode(byteLimitPost, forKey: "byteLimitPost")
        coder.encode(customRetryForStatusCodes, forKey: "customRetryForStatusCodes")
        coder.encode(serverAnonymisation, forKey: "serverAnonymisation")
    }

    required init?(coder: NSCoder) {
        super.init()
        if let bufferOption = BufferOption(rawValue: coder.decodeInteger(forKey: "bufferOption")) {
            self.bufferOption = bufferOption
        }
        emitRange = coder.decodeInteger(forKey: "emitRange")
        threadPoolSize = coder.decodeInteger(forKey: "threadPoolSize")
        byteLimitGet = coder.decodeInteger(forKey: "byteLimitGet")
        byteLimitPost = coder.decodeInteger(forKey: "byteLimitPost")
        customRetryForStatusCodes = coder.decodeObject(forKey: "customRetryForStatusCodes") as? [Int : Bool]
        serverAnonymisation = coder.decodeBool(forKey: "serverAnonymisation")
    }
}
