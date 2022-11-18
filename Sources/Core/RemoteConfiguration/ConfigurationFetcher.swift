//
//  SPConfigurationFetcher.swift
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

@objc(SPConfigurationFetcher)
public class ConfigurationFetcher: NSObject {
    private var remoteConfiguration: RemoteConfiguration
    private var onFetchCallback: OnFetchCallback

    @objc public init(remoteSource remoteConfiguration: RemoteConfiguration, onFetchCallback: @escaping OnFetchCallback) {
        self.remoteConfiguration = remoteConfiguration
        self.onFetchCallback = onFetchCallback
        super.init()
        performRequest()
    }

    @objc public func performRequest() {
        guard let url = URL(string: remoteConfiguration.endpoint) else { return }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"

        var httpResponse: HTTPURLResponse? = nil

        URLSession.shared.dataTask(with: urlRequest) { data, urlResponse, error in
            httpResponse = urlResponse as? HTTPURLResponse
            let isSuccessful = (httpResponse?.statusCode ?? 0) >= 200 && (httpResponse?.statusCode ?? 0) < 300
            if isSuccessful {
                if let data { self.resolveRequest(with: data) }
            }
        }.resume()
    }

    @objc public func resolveRequest(with data: Data) {
        if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String : NSObject],
           let jsonObject,
           let fetchedConfigurationBundle = FetchedConfigurationBundle(dictionary: jsonObject) {
            onFetchCallback(fetchedConfigurationBundle, ConfigurationState.fetched)
        }
    }
}
