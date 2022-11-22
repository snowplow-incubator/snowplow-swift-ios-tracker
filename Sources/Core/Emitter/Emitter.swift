//
//  Emitter.swift
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

/// This class sends events to the collector.
let POST_WRAPPER_BYTES = 88

@objc(SPEmitter)
public class Emitter: NSObject, EmitterEventProcessing {
    
    private var timer: Timer?
    /// Whether the emitter is currently sending.
    private(set) public var isSending = false
    private var dataOperationQueue: OperationQueue = OperationQueue()
    private var builderFinished = false

    private var pausedEmit = false

    private var _urlEndpoint: String?
    /// Collector endpoint.
    public var urlEndpoint: String? {
        get {
            return _urlEndpoint
        }
        set {
            _urlEndpoint = newValue
            if builderFinished {
                setupNetworkConnection()
            }
        }
    }

    var _namespace: String?
    public var namespace: String? {
        get {
            return _namespace
        }
        set(namespace) {
            _namespace = namespace
            if builderFinished && eventStore == nil {
                #if TARGET_OS_TV || TARGET_OS_WATCH
                eventStore = MemoryEventStore()
                #else
                eventStore = SQLiteEventStore(namespace: _namespace)
                #endif
            }
        }
    }

    private var _method: HttpMethodOptions = .post
    /// Chosen HTTP method - HttpMethodGet or HttpMethodPost.
    public var method: HttpMethodOptions {
        get {
            return _method
        }
        set(method) {
            _method = method
            if builderFinished && networkConnection != nil {
                setupNetworkConnection()
            }
        }
    }
    
    private var _protocol: ProtocolOptions = .https
    /// Security of requests - ProtocolHttp or ProtocolHttps.
    public var `protocol`: ProtocolOptions {
        get {
            return _protocol
        }
        set(`protocol`) {
            _protocol = `protocol`
            if builderFinished && networkConnection != nil {
                setupNetworkConnection()
            }
        }
    }
    private var _bufferOption: BufferOption = .defaultGroup
    /// Buffer option
    public var bufferOption: BufferOption {
        get {
            return _bufferOption
        }
        set(bufferOption) {
            if !isSending {
                _bufferOption = bufferOption
            }
        }
    }
    
    private weak var _callback: RequestCallback?
    /// Callbacks supplied with number of failures and successes of sent events.
    public var callback: RequestCallback? {
        get {
            return _callback
        }
        set(callback) {
            _callback = callback
        }
    }
    
    private var _emitRange = 150
    /// Number of events retrieved from the database when needed.
    public var emitRange: Int {
        get {
            return _emitRange
        }
        set(emitRange) {
            if emitRange > 0 {
                _emitRange = emitRange
            }
        }
    }
    
    private var _emitThreadPoolSize = 15
    /// Number of threads used for emitting events.
    public var emitThreadPoolSize: Int {
        get {
            return _emitThreadPoolSize
        }
        set(emitThreadPoolSize) {
            if emitThreadPoolSize > 0 {
                _emitThreadPoolSize = emitThreadPoolSize
                if dataOperationQueue.maxConcurrentOperationCount != emitThreadPoolSize {
                    dataOperationQueue.maxConcurrentOperationCount = _emitThreadPoolSize
                }
                if builderFinished && networkConnection != nil {
                    setupNetworkConnection()
                }
            }
        }
    }
    
    private var _byteLimitGet = 40000
    /// Byte limit for GET requests.
    public var byteLimitGet: Int {
        get {
            return _byteLimitGet
        }
        set(byteLimitGet) {
            _byteLimitGet = byteLimitGet
            if builderFinished && networkConnection != nil {
                setupNetworkConnection()
            }
        }
    }
    
    private var _byteLimitPost = 40000
    /// Byte limit for POST requests.
    public var byteLimitPost: Int {
        get {
            return _byteLimitPost
        }
        set(byteLimitPost) {
            _byteLimitPost = byteLimitPost
            if builderFinished && networkConnection != nil {
                setupNetworkConnection()
            }
        }
    }

    private var _serverAnonymisation = false
    /// Whether to anonymise server-side user identifiers including the `network_userid` and `user_ipaddress`.
    public var serverAnonymisation: Bool {
        get {
            return _serverAnonymisation
        }
        set(serverAnonymisation) {
            _serverAnonymisation = serverAnonymisation
            if builderFinished && networkConnection != nil {
                setupNetworkConnection()
            }
        }
    }

    private var _customPostPath: String?
    /// Custom endpoint path for POST requests.
    public var customPostPath: String? {
        get {
            return _customPostPath
        }
        set(customPath) {
            _customPostPath = customPath
            if builderFinished && networkConnection != nil {
                setupNetworkConnection()
            }
        }
    }

    /// Custom header requests.
    private var _requestHeaders: [String : String]?
    public var requestHeaders: [String : String]? {
        get {
            return _requestHeaders
        }
        set(requestHeaders) {
            _requestHeaders = requestHeaders
            if builderFinished && networkConnection != nil {
                setupNetworkConnection()
            }
        }
    }

    private var _networkConnection: NetworkConnection?
    /// Custom NetworkConnection istance to handle connection outside the emitter.
    public var networkConnection: NetworkConnection? {
        get {
            return _networkConnection
        }
        set(networkConnection) {
            _networkConnection = networkConnection
            if builderFinished && _networkConnection != nil {
                setupNetworkConnection()
            }
        }
    }
    
    private var _eventStore: EventStore?
    public var eventStore: EventStore? {
        get {
            return _eventStore
        }
        set(eventStore) {
            if !builderFinished || self.eventStore == nil || self.eventStore?.count() == 0 {
                _eventStore = eventStore
            }
        }
    }
    
    /// Custom retry rules for HTTP status codes.
    private var _customRetryForStatusCodes: [NSNumber : NSNumber] = [:]
    public var customRetryForStatusCodes: [NSNumber : NSNumber]? {
        get {
            return _customRetryForStatusCodes
        }
        set(customRetryForStatusCodes) {
            _customRetryForStatusCodes = customRetryForStatusCodes ?? [:]
        }
    }

    /// Returns the number of events in the DB.
    var dbCount: Int {
        return Int(eventStore?.count() ?? 0)
    }
    
    // MARK: - Initialization
    
    init(urlEndpoint: String) {
        super.init()
        self._urlEndpoint = urlEndpoint
    }
    
    init(networkConnection: NetworkConnection) {
        super.init()
        self._networkConnection = networkConnection
    }

    func setup() {
        dataOperationQueue.maxConcurrentOperationCount = emitThreadPoolSize
        setupNetworkConnection()
        resumeTimer()
        builderFinished = true
    }

    func setupNetworkConnection() {
        if !builderFinished && networkConnection != nil {
            return
        }
        if let urlEndpoint {
            var endpoint = "\(urlEndpoint)"
            if !endpoint.hasPrefix("http") {
                let `protocol` = self.protocol == .https ? "https://" : "http://"
                endpoint = `protocol` + endpoint
            }
            let defaultNetworkConnection = DefaultNetworkConnection(urlString: endpoint)
            if let customPostPath {
                defaultNetworkConnection.customPostPath = customPostPath
            }
            defaultNetworkConnection.httpMethod = method
            defaultNetworkConnection.requestHeaders = requestHeaders
            defaultNetworkConnection.emitThreadPoolSize = emitThreadPoolSize
            defaultNetworkConnection.byteLimitGet = byteLimitGet
            defaultNetworkConnection.byteLimitPost = byteLimitPost
            defaultNetworkConnection.serverAnonymisation = serverAnonymisation
            defaultNetworkConnection.setup()
            networkConnection = defaultNetworkConnection
        }
    }

    // MARK: - Pause/Resume methods

    public func resumeTimer() {
        weak var weakSelf = self

        if timer != nil {
            pauseTimer()
        }

        DispatchQueue.main.async {
            weakSelf?.timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(kSPDefaultBufferTimeout), repeats: true) { [weak self] timer in
                self?.flush()
            }
        }
    }

    /// Suspends timer for periodically sending events to collector.
    public func pauseTimer() {
        timer?.invalidate()
        timer = nil
    }

    /// Allows sending events to collector.
    public func resumeEmit() {
        pausedEmit = false
        flush()
    }

    /// Suspends sending events to collector.
    public func pauseEmit() {
        pausedEmit = true
    }

    /// Insert a Payload object into the buffer to be sent to collector.
    /// This method will add the payload to the database and flush (send all events).
    /// - Parameter eventPayload: A Payload containing a completed event to be added into the buffer.
    public func addPayload(toBuffer eventPayload: Payload) {
        weak var weakSelf = self

        DispatchQueue.global(qos: .default).async(execute: {
            let strongSelf = weakSelf
            if strongSelf == nil {
                return
            }

            strongSelf?.eventStore?.addEvent(eventPayload)
            strongSelf?.flush()
        })
    }

    /// Empties the buffer of events using the respective HTTP request method.
    @objc public func flush() {
        if Thread.isMainThread {
            DispatchQueue.global(qos: .default).async(execute: { [self] in
                sendGuard()
            })
        } else {
            sendGuard()
        }
    }

    // MARK: - Control methods

    func sendGuard() {
        if isSending || pausedEmit {
            return
        }
        objc_sync_enter(self)
        if !isSending && !pausedEmit {
            isSending = true
//            do {
            // TODO: check if try catch is necessary
            attemptEmit()
//            } catch {
////                SPLogError("Received exception during emission process: %@", exception)
//                isSending = false
//            }
        }
        objc_sync_exit(self)
    }

    func attemptEmit() {
        guard let eventStore else { return }
        if eventStore.count() == 0 {
//            SPLogDebug("Database empty. Returning.", nil)
            isSending = false
            return
        }

        let events = eventStore.emittableEvents(withQueryLimit: UInt(emitRange))
        let requests = buildRequests(fromEvents: events)
        let sendResults = networkConnection?.sendRequests(requests)

//        SPLogVerbose("Processing emitter results.")

        var successCount = 0
        var failedWillRetryCount = 0
        var failedWontRetryCount = 0
        var removableEvents: [NSNumber] = []

        for result in sendResults ?? [] {
            let resultIndexArray = result.storeIds
            if result.isSuccessful {
                successCount += resultIndexArray?.count ?? 0
                if let resultIndexArray {
                    removableEvents.append(contentsOf: resultIndexArray)
                }
            } else if result.shouldRetry(customRetryForStatusCodes) {
                failedWillRetryCount += resultIndexArray?.count ?? 0
            } else {
                failedWontRetryCount += resultIndexArray?.count ?? 0
                if let resultIndexArray {
                    removableEvents.append(contentsOf: resultIndexArray)
                }
//                SPLogError("Sending events to Collector failed with status %ld. Events will be dropped.", result.statusCode)
            }
        }
        let allFailureCount = failedWillRetryCount + failedWontRetryCount

        let _ = eventStore.removeEvents(withIds: removableEvents)

//        SPLogDebug("Success Count: %@", NSNumber(value: successCount).stringValue)
//        SPLogDebug("Failure Count: %@", NSNumber(value: allFailureCount).stringValue)

        if callback != nil {
            if allFailureCount == 0 {
                callback?.onSuccess(withCount: successCount)
            } else {
                callback?.onFailure(withCount: allFailureCount, successCount: successCount)
            }
        }

        if failedWillRetryCount > 0 && successCount == 0 {
//            SPLogDebug("Ending emitter run as all requests failed.", nil)
            Thread.sleep(forTimeInterval: 5)
            isSending = false
            return
        } else {
            self.attemptEmit()
        }
    }

    func buildRequests(fromEvents events: [EmitterEvent]) -> [Request] {
        var requests: [Request] = []
        guard let networkConnection else { return requests }
        
        let sendingTime = Utilities.getTimestamp()
        let httpMethod = networkConnection.httpMethod

        if httpMethod == .get {
            for event in events {
                let payload = event.payload
                addSendingTime(to: payload, timestamp: sendingTime)
                let oversize = isOversize(payload)
                let request = Request(payload: payload, emitterEventId: event.storeId, oversize: oversize)
                requests.append(request)
            }
        } else {
            var i = 0
            while i < events.count {
                var eventArray: [Payload] = []
                var indexArray: [NSNumber] = []

                for j in i..<Int((i + bufferOption.rawValue)) {
                    let event = events[j]

                    let payload = event.payload
                    let emitterEventId = NSNumber(value: event.storeId)
                    addSendingTime(to: payload, timestamp: sendingTime)

                    if isOversize(payload) {
                        let request = Request(payload: payload, emitterEventId: emitterEventId.int64Value, oversize: true)
                        requests.append(request)
                    } else if isOversize(payload, previousPayloads: eventArray) {
                        let request = Request(payloads: eventArray, emitterEventIds: indexArray)
                        requests.append(request)

                        // Clear collection and build a new POST
                        eventArray = []
                        indexArray = []

                        // Build and store the request
                        eventArray.append(payload)
                        indexArray.append(emitterEventId)
                    } else {
                        // Add event to collections
                        eventArray.append(payload)
                        indexArray.append(emitterEventId)
                    }
                }

                // Check if all payloads have been processed
                if eventArray.count != 0 {
                    let request = Request(payloads: eventArray, emitterEventIds: indexArray)
                    requests.append(request)
                }
                i += bufferOption.rawValue
            }
        }
        return requests
    }

    func isOversize(_ payload: Payload) -> Bool {
        return isOversize(payload, previousPayloads: [])
    }

    func isOversize(_ payload: Payload, previousPayloads: [Payload]) -> Bool {
        let byteLimit = networkConnection?.httpMethod == .get ? byteLimitGet : byteLimitPost
        return isOversize(payload, byteLimit: byteLimit, previousPayloads: previousPayloads)
    }

    func isOversize(_ payload: Payload, byteLimit: Int, previousPayloads: [Payload]) -> Bool {
        var totalByteSize = payload.byteSize()
        for previousPayload in previousPayloads {
            totalByteSize += previousPayload.byteSize()
        }
        let wrapperBytes = previousPayloads.count > 0 ? (previousPayloads.count + POST_WRAPPER_BYTES) : 0
        return totalByteSize + wrapperBytes > byteLimit
    }

    func addSendingTime(to payload: Payload, timestamp: NSNumber) {
        payload.addValueToPayload(String(format: "%lld", timestamp.int64Value), forKey: kSPSentTimestamp)
    }

    deinit {
        pauseTimer()
    }
}
