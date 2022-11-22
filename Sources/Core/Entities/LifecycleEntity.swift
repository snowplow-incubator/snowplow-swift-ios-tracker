//
// SPLifecycleEntity.swift
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

import Foundation

/// Entity that indicates the state of the app is visible (foreground) when the event is tracked.
let kSPLifecycleEntitySchema = "iglu:com.snowplowanalytics.mobile/application_lifecycle/jsonschema/1-0-0"
let kSPLifecycleEntityParamIndex = "index"
let kSPLifecycleEntityParamIsVisible = "isVisible"

@objc(SPLifecycleEntity)
public class LifecycleEntity: SelfDescribingJson {

    @objc public init(isVisible: Bool) {
        var parameters: [String : NSObject] = [:]
        parameters[kSPLifecycleEntityParamIsVisible] = NSNumber(value: isVisible)
        super.init(schema: kSPLifecycleEntitySchema, andData: parameters as NSObject)
        
        // Set here further checks about the arguments.
        // e.g.: [SPUtilities checkArgument:([_name length] != 0) withMessage:@"Name cannot be empty."];
    }

    // --- Builder Methods

    @objc public func index(_ index: NSNumber?) -> Self {
        if var data,
           var parameters = data as? [String : NSObject] {
            parameters[kSPLifecycleEntityParamIndex] = index
        }
        return self
    }
}
