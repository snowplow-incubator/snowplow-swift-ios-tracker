//
//  SPRequestResult.swift
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
//  Authors: Joshua Beemster
//  License: Apache License Version 2.0
//

import Foundation

public class RequestResult: NSObject {
    /// Returns the HTTP status code from Collector.
    private(set) var statusCode: Int?
    /// Was the request oversize
    private(set) var isOversize: Bool
    /// Returns the stored index array, needed to remove the events after sending.
    private(set) var storeIds: [NSNumber]?

    public convenience override init() {
        self.init(statusCode: nil, oversize: false, storeIds: [])
    }

    /// Creates a request result object
    /// - Parameters:
    ///   - statusCode: HTTP status code from collector response
    ///   - storeIds: the event indexes in the database
    public init(statusCode: Int?, oversize isOversize: Bool, storeIds: [NSNumber]?) {
        self.statusCode = statusCode
        self.isOversize = isOversize
        self.storeIds = storeIds
    }

    /// - Returns: Whether the events were successfuly sent to the Collector.
    public var isSuccessful: Bool {
        if let statusCode {
            return statusCode >= 200 && statusCode < 300
        }
        return false
    }

    /// - Parameter customRetryForStatusCodes: mapping of custom retry rules for HTTP status codes in Collector response.
    /// - Returns: Whether sending the events to the Collector should be retried.
    func shouldRetry(_ customRetryForStatusCodes: [Int : Bool]?) -> Bool {
        // don't retry if successful
        if isSuccessful {
            return false
        }

        // don't retry if request is larger than max byte limit
        if isOversize {
            return false
        }

        // status code has a custom retry rule
        if let statusCode {
            if let retryRule = customRetryForStatusCodes?[statusCode] {
                return retryRule
            }
            
            // retry if status code is not in the list of no-retry status codes
            let dontRetryStatusCodes = [400, 401, 403, 410, 422]
            return !dontRetryStatusCodes.contains(statusCode)
        }
        return true
    }
}
