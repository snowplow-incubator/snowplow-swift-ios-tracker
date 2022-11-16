//  SPSubjectConfigurationUpdate.swift
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

@objc(SPSubjectConfigurationUpdate)
public class SubjectConfigurationUpdate: SubjectConfiguration {
    @objc public var sourceConfig: SubjectConfiguration?
    var userIdUpdated = false
    var networkUserIdUpdated = false
    var domainUserIdUpdated = false
    var useragentUpdated = false
    var ipAddressUpdated = false
    var timezoneUpdated = false
    var languageUpdated = false
    var screenResolutionUpdated = false
    var screenViewPortUpdated = false
    var colorDepthUpdated = false

    @objc public override var userId: String? {
        get {
            return ((sourceConfig == nil || userIdUpdated) ? super.userId : sourceConfig?.userId)
        }
        set {
            super.userId = newValue
            userIdUpdated = true
        }
    }

    @objc public override var networkUserId: String? {
        get {
            return ((sourceConfig == nil || networkUserIdUpdated) ? super.networkUserId : sourceConfig?.networkUserId)
        }
        set {
            super.networkUserId = newValue
            networkUserIdUpdated = true
        }
    }

    @objc public override var domainUserId: String? {
        get {
            return ((sourceConfig == nil || domainUserIdUpdated) ? super.domainUserId : sourceConfig?.domainUserId)
        }
        set {
            super.domainUserId = newValue
            domainUserIdUpdated = true
        }
    }

    @objc public override var useragent: String? {
        get {
            return ((sourceConfig == nil || useragentUpdated) ? super.useragent : sourceConfig?.useragent)
        }
        set {
            super.useragent = newValue
            useragentUpdated = true
        }
    }

    @objc public override var ipAddress: String? {
        get {
            return ((sourceConfig == nil || ipAddressUpdated) ? super.ipAddress : sourceConfig?.ipAddress)
        }
        set {
            super.ipAddress = newValue
            ipAddressUpdated = true
        }
    }

    @objc public override var timezone: String? {
        get {
            return ((sourceConfig == nil || timezoneUpdated) ? super.timezone : sourceConfig?.timezone)
        }
        set {
            super.timezone = newValue
            timezoneUpdated = true
        }
    }

    @objc public override var language: String? {
        get {
            return ((sourceConfig == nil || languageUpdated) ? super.language : sourceConfig?.language)
        }
        set {
            super.language = newValue
            languageUpdated = true
        }
    }

    @objc public override var screenResolution: SPSize? {
        get {
            return ((sourceConfig == nil || screenResolutionUpdated) ? super.screenResolution : sourceConfig?.screenResolution)
        }
        set {
            super.screenResolution = newValue
            screenResolutionUpdated = true
        }
    }

    @objc public override var screenViewPort: SPSize? {
        get {
            return ((sourceConfig == nil || screenViewPortUpdated) ? super.screenViewPort : sourceConfig?.screenViewPort)
        }
        set {
            super.screenViewPort = newValue
            screenViewPortUpdated = true
        }
    }

    @objc public override var colorDepth: NSNumber? {
        get {
            return ((sourceConfig == nil || colorDepthUpdated) ? super.colorDepth : sourceConfig?.colorDepth)
        }
        set {
            super.colorDepth = newValue
            colorDepthUpdated = true
        }
    }
}
