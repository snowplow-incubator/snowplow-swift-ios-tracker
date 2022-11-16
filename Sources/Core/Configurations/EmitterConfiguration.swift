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

/// An enum for buffer options.
@objc(SPBufferOption)
public enum BufferOption : Int {
    /// Sends both GET and POST requests with only a single event.  Can cause a spike in
    /// network traffic if used in correlation with a large amount of events.
    case single = 1
    /// Sends POST requests in groups of 10 events.  This is the default amount of events too
    /// package into a POST.  All GET requests will still emit one at a time.
    case defaultGroup = 10
    /// Sends POST requests in groups of 25 events.  Useful for situations where many events
    /// need to be sent.  All GET requests will still emit one at a time.
    case largeGroup = 25
}

@objc(SPEmitterConfigurationProtocol)
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
    var customRetryForStatusCodes: [NSNumber : NSNumber]? { get set }
    /// Whether to anonymise server-side user identifiers including the `network_userid` and `user_ipaddress`
    var serverAnonymisation: Bool { get set }
}

/// It allows the tracker configuration from the emission perspective.
/// The EmitterConfiguration can be used to setup details about how the tracker should treat the events
/// to emit to the collector.
@objc(SPEmitterConfiguration)
public class EmitterConfiguration: Configuration, EmitterConfigurationProtocol {
    /// Sets whether the buffer should send events instantly or after the buffer
    /// has reached it's limit. By default, this is set to BufferOption Default.
    @objc public var bufferOption: BufferOption = .single

    /// Maximum number of events collected from the EventStore to be sent in a request.
    @objc public var emitRange: Int = 150

    /// Maximum number of threads working in parallel in the tracker to send requests.
    @objc public var threadPoolSize: Int = 15

    /// Maximum amount of bytes allowed to be sent in a payload in a GET request.
    @objc public var byteLimitGet: Int = 40000

    /// Maximum amount of bytes allowed to be sent in a payload in a POST request.
    @objc public var byteLimitPost: Int = 40000

    /// Callback called for each request performed by the tracker to the collector.
    @objc public var requestCallback: RequestCallback?

    /// Custom retry rules for HTTP status codes returned from the Collector.
    /// The dictionary is a mapping of integers (status codes) to booleans (true for retry and false for not retry).
    @objc public var customRetryForStatusCodes: [NSNumber : NSNumber]?

    /// Whether to anonymise server-side user identifiers including the `network_userid` and `user_ipaddress`
    @objc public var serverAnonymisation: Bool = false

    /// Custom component with full ownership for persisting events before to be sent to the collector.
    /// If it's not set the tracker will use a SQLite database as default EventStore.
    @objc public var eventStore: EventStore?

    /// It sets a default EmitterConfiguration.
    /// Default values:
    ///         bufferOption = BufferOption.Single;
    ///         emitRange = 150;
    ///         threadPoolSize = 15;
    ///         byteLimitGet = 40000;
    ///         byteLimitPost = 40000;
    ///         serverAnonymisation = false;
    @objc public override init() {
        super.init()
    }

    // MARK: - NSCopying

    @objc public override func copy(with zone: NSZone? = nil) -> Any {
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

    @objc public override func encode(with coder: NSCoder) {
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
        customRetryForStatusCodes = coder.decodeObject(forKey: "customRetryForStatusCodes") as? [NSNumber : NSNumber]
        serverAnonymisation = coder.decodeBool(forKey: "serverAnonymisation")
    }
}
