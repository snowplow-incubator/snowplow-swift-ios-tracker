//
// SPDeepLinkEntity.swift
// Snowplow
//
// Copyright (c) 2013-2022 Snowplow Analytics Ltd. All rights reserved.
//
// This program is licensed to you under the Apache License Version 2.0,
// and you may not use this file except in compliance with the Apache License
// Version 2.0. You may obtain a copy of the Apache License Version 2.0 at
// http://www.apache.org/licenses/LICENSE-2.0.
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the Apache License Version 2.0 is distributed on
// an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the Apache License Version 2.0 for the specific
// language governing permissions and limitations there under.
//
// License: Apache License Version 2.0
//

/// Entity that indicates a deep-link has been received and processed.

@objc(SPDeepLinkEntity)
public class DeepLinkEntity: SelfDescribingJson {
    @objc public static let schema = "iglu:com.snowplowanalytics.mobile/deep_link/jsonschema/1-0-0"
    @objc public static let paramReferrer = "referrer"
    @objc public static let paramUrl = "url"

    @objc public init(url: String) {
        var parameters: [String : NSObject] = [:]
        parameters[DeepLinkEntity.paramUrl] = url as NSObject
        super.init(schema: DeepLinkEntity.schema, andData: parameters as NSObject)
        
        // Set here further checks about the arguments.
        // e.g.: [SPUtilities checkArgument:([_name length] != 0) withMessage:@"Name cannot be empty."];
    }

    // --- Builder Methods

    @objc public func referrer(_ referrer: String?) -> Self {
        if let data,
           var parameters = data as? [String : NSObject] {
            parameters[DeepLinkEntity.paramReferrer] = referrer as? NSObject
        }
        return self
    }
}
