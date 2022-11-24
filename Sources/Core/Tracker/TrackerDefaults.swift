//
//  TrackerDefaults.swift
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
//  Authors: Matus Tomlein
//  License: Apache License Version 2.0
//

import Foundation

public class TrackerDefaults {
    public private(set) static var base64Encoded = true
    public private(set) static var trackerVersionSuffix = ""
    public private(set) static var devicePlatform: DevicePlatform = Utilities.platform
    public private(set) static var foregroundTimeout = 1800
    public private(set) static var backgroundTimeout = 1800
    public private(set) static var sessionContext = true
    public private(set) static var deepLinkContext = true
    public private(set) static var screenContext = true
    public private(set) static var applicationContext = true
    public private(set) static var autotrackScreenViews = true
    public private(set) static var lifecycleEvents = false
    public private(set) static var exceptionEvents = true
    public private(set) static var installEvent = true
    public private(set) static var trackerDiagnostic = false
    public private(set) static var userAnonymisation = false
    public private(set) static var platformContext = true
    public private(set) static var geoLocationContext = false
}
