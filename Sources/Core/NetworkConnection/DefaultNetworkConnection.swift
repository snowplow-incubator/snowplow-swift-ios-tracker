//
//  SPDefaultNetworkConnection.swift
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

@objc public protocol DefaultNetworkConnectionBuilder: NSObjectProtocol {
    /// Builder method to set the collector endpoint.
    /// - Parameter urlEndpoint: The collector endpoint.
    var urlString: String { get set }
    /// Builder method to set HTTP method.
    /// - Parameter method: Should be SPHttpMethodGet or SPHttpMethodPost.
    var httpMethod: HttpMethodOptions { get set }
    /// Builder method to set thread pool size.
    /// - Parameter emitThreadPoolSize: The number of threads used by the emitter.
    var emitThreadPoolSize: Int { get set }
    /// Builder method to set byte limit for GET requests.
    /// - Parameter byteLimitGet: Maximum event size for a GET request.
    var byteLimitGet: Int { get set }
    /// Builder method to set byte limit for POST requests.
    /// - Parameter byteLimitPost: Maximum event size for a POST request.
    var byteLimitPost: Int { get set }
    /// Builder method to set a custom POST path.
    /// - Parameter customPath: A custom path that is used on the endpoint to send requests.
    var customPostPath: String? { get set }
    /// Builder method to set request headers.
    /// - Parameter requestHeadersKeyValue: custom headers (key, value) for http requests.
    var requestHeaders: [String : String]? { get set }
    /// Builder method to set the server anonymisation flag.
    /// - Parameter serverAnonymisation: Whether to anonymise server-side user identifiers including the `network_userid` and `user_ipaddress`
    var serverAnonymisation: Bool { get set }
}

public class DefaultNetworkConnection: NSObject, NetworkConnection, DefaultNetworkConnectionBuilder {
    private var `protocol`: ProtocolOptions = .https

    private var _urlString: String
    public var urlString: String {
        get {
            return urlEndpoint?.absoluteString ?? _urlString
        }
        set {
            _urlString = newValue
            if builderFinished {
                setup()
            }
        }
    }
    private(set) public var urlEndpoint: URL?

    private var _httpMethod: HttpMethodOptions = .post
    public var httpMethod: HttpMethodOptions {
        get {
            return _httpMethod
        }
        set(method) {
            _httpMethod = method
            if builderFinished && urlEndpoint != nil {
                setup()
            }
        }
    }

    private var _emitThreadPoolSize = 15
    public var emitThreadPoolSize: Int {
        get {
            return _emitThreadPoolSize
        }
        set(emitThreadPoolSize) {
            self.emitThreadPoolSize = emitThreadPoolSize
            if dataOperationQueue.maxConcurrentOperationCount != emitThreadPoolSize {
                dataOperationQueue.maxConcurrentOperationCount = self.emitThreadPoolSize
            }
        }
    }

    public var byteLimitGet: Int = 40000
    public var byteLimitPost = 40000
    public var customPostPath: String?
    public var requestHeaders: [String : String]?
    public var serverAnonymisation = false
    private var dataOperationQueue = OperationQueue()
    private var builderFinished = false
    
    public init(urlString: String) {
        self._urlString = urlString
    }

    // MARK: - Implement SPNetworkConnection protocol
    
    func setup() {
        // Decode url to extract protocol
        let url = URL(string: _urlString)
        var endpoint = _urlString
        if url?.scheme == "https" {
            `protocol` = .https
        } else if url?.scheme == "http" {
            `protocol` = .http
        } else {
            `protocol` = .https
            endpoint = "https://\(_urlString)"
        }

        // Configure
        let urlPrefix = `protocol` == .http ? "http://" : "https://"
        var urlSuffix = _httpMethod == .get ? kSPEndpointGet : kSPEndpointPost
        if _httpMethod == .post {
            if let customPostPath { urlSuffix = customPostPath }
        }

        // Remove trailing slashes from endpoint to avoid double slashes when appending path
        endpoint = endpoint.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        urlEndpoint = URL(string: endpoint)?.appendingPathComponent(urlSuffix)

        // Log
        if urlEndpoint?.scheme != nil && urlEndpoint?.host != nil {
//            SPLogDebug("Emitter URL created successfully '%@'", urlEndpoint)
        } else {
//            SPLogDebug("Invalid emitter URL: '%@'", urlEndpoint)
        }
        let userDefaults = UserDefaults.standard
        userDefaults.set(endpoint, forKey: kSPErrorTrackerUrl)
        userDefaults.set(urlSuffix, forKey: kSPErrorTrackerProtocol)
        userDefaults.set(urlPrefix, forKey: kSPErrorTrackerMethod)

        builderFinished = true
    }

    public func sendRequests(_ requests: [Request]) -> [RequestResult] {
        var results: [RequestResult] = []

        for request in requests {
            let urlRequest = _httpMethod == .get
                ? buildGet(request)
                : buildPost(request)

            dataOperationQueue.addOperation({
                //source: https://forums.developer.apple.com/thread/11519
                var httpResponse: HTTPURLResponse? = nil
                var connectionError: Error? = nil
                var sem: DispatchSemaphore

                sem = DispatchSemaphore(value: 0)

                URLSession.shared.dataTask(with: urlRequest) { data, urlResponse, error in
                    connectionError = error
                    httpResponse = urlResponse as? HTTPURLResponse
                    sem.signal()
                }.resume()

                let _ = sem.wait(timeout: .distantFuture)

                let result = RequestResult(statusCode: httpResponse?.statusCode, oversize: request.oversize, storeIds: request.emitterEventIds)
                if !result.isSuccessful {
//                    SPLogError("Connection error: %@", connectionError)
                }

                objc_sync_enter(results)
                results.append(result)
                objc_sync_exit(results)
            })
        }
        dataOperationQueue.waitUntilAllOperationsAreFinished()
        return results
    }

    // MARK: - Private methods

    func buildPost(_ request: Request) -> URLRequest {
        var requestData: Data? = nil
        do {
            requestData = try JSONSerialization.data(withJSONObject: request.payload?.getAsDictionary() ?? [:], options: [])
        } catch {
        }
        let url = URL(string: urlEndpoint!.absoluteString)!
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("\(NSNumber(value: requestData?.count ?? 0).stringValue)", forHTTPHeaderField: "Content-Length")
        urlRequest.setValue(kSPAcceptContentHeader, forHTTPHeaderField: "Accept")
        urlRequest.setValue(kSPContentTypeHeader, forHTTPHeaderField: "Content-Type")
        if serverAnonymisation {
            urlRequest.setValue("*", forHTTPHeaderField: "SP-Anonymous")
        }
        if let requestHeaders {
            applyValuesAndHeaderFields(requestHeaders, to: &urlRequest)
        }
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = requestData
        return urlRequest
    }

    func buildGet(_ request: Request) -> URLRequest {
        let payload = request.payload?.getAsDictionary() ?? [:]
        let url = "\(urlEndpoint!.absoluteString)?\(Utilities.urlEncode(payload))"
        let anUrl = URL(string: url)!
        var urlRequest = URLRequest(url: anUrl)
        urlRequest.setValue(kSPAcceptContentHeader, forHTTPHeaderField: "Accept")
        if serverAnonymisation {
            urlRequest.setValue("*", forHTTPHeaderField: "SP-Anonymous")
        }
        if let requestHeaders {
            applyValuesAndHeaderFields(requestHeaders, to: &urlRequest)
        }
        urlRequest.httpMethod = "GET"
        return urlRequest
    }

    func applyValuesAndHeaderFields(_ requestHeaders: [String : String], to request: inout URLRequest) {
        (requestHeaders as NSDictionary).enumerateKeysAndObjects({ key, obj, stop in
            if let key = key as? String, let obj = obj as? String {
                request.setValue(obj, forHTTPHeaderField: key)
            }
        })
    }
}
