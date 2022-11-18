//
//  SPSubjectControllerImpl.swift
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

@objc(SPSubjectControllerImpl)
public class SubjectControllerImpl: Controller, SubjectController {
    // MARK: - Properties

    public var userId: String? {
        get {
            return subject?.userId
        }
        set {
            dirtyConfig.userId = newValue
            dirtyConfig.userIdUpdated = true
            subject?.userId = newValue
        }
    }

    public var networkUserId: String? {
        get {
            return subject?.networkUserId
        }
        set {
            dirtyConfig.networkUserId = newValue
            dirtyConfig.networkUserIdUpdated = true
            subject?.networkUserId = newValue
        }
    }

    public var domainUserId: String? {
        get {
            return subject?.domainUserId
        }
        set {
            dirtyConfig.domainUserId = newValue
            dirtyConfig.domainUserIdUpdated = true
            subject?.domainUserId = newValue
        }
    }

    public var useragent: String? {
        get {
            return subject?.useragent
        }
        set {
            dirtyConfig.useragent = newValue
            dirtyConfig.useragentUpdated = true
            subject?.useragent = newValue
        }
    }

    public var ipAddress: String? {
        get {
            return subject?.ipAddress
        }
        set {
            dirtyConfig.ipAddress = newValue
            dirtyConfig.ipAddressUpdated = true
            subject?.ipAddress = newValue
        }
    }

    public var timezone: String? {
        get {
            return subject?.timezone
        }
        set {
            dirtyConfig.timezone = newValue
            dirtyConfig.timezoneUpdated = true
            subject?.timezone = newValue
        }
    }

    public var language: String? {
        get {
            return subject?.language
        }
        set {
            dirtyConfig.language = newValue
            dirtyConfig.languageUpdated = true
            subject?.language = newValue
        }
    }

    public var screenResolution: SPSize? {
        get {
            return subject?.screenResolution
        }
        set {
            dirtyConfig.screenResolution = newValue
            dirtyConfig.screenResolutionUpdated = true
            if let size = newValue {
                subject?.setResolutionWithWidth(size.width, andHeight: size.height)
            }
        }
    }

    public var screenViewPort: SPSize? {
        get {
            return subject?.screenViewPort
        }
        set {
            dirtyConfig.screenViewPort = newValue
            dirtyConfig.screenViewPortUpdated = true
            if let size = newValue {
                subject?.setViewPortWithWidth(size.width, andHeight: size.height)
            }
        }
    }

    public var colorDepth: NSNumber? {
        get {
            if let subject = subject {
                return subject.colorDepth
            }
            return nil
        }
        set {
            dirtyConfig.colorDepth = newValue
            dirtyConfig.colorDepthUpdated = true
            subject?.colorDepth = newValue
        }
    }

    // MARK: - GeoLocalization

    public var geoLatitude: NSNumber? {
        get {
            return subject?.geoLatitude()
        }
        set {
            subject?.setGeoLatitude(newValue)
        }
    }

    public var geoLongitude: NSNumber? {
        get {
            return subject?.geoLongitude()
        }
        set {
            subject?.setGeoLongitude(newValue)
        }
    }

    public var geoLatitudeLongitudeAccuracy: NSNumber? {
        get {
            return subject?.geoLatitudeLongitudeAccuracy()
        }
        set {
            subject?.setGeoLatitudeLongitudeAccuracy(newValue)
        }
    }

    public var geoAltitude: NSNumber? {
        get {
            return subject?.geoAltitude()
        }
        set {
            subject?.setGeoAltitude(newValue)
        }
    }

    public var geoAltitudeAccuracy: NSNumber? {
        get {
            return subject?.geoAltitudeAccuracy()
        }
        set {
            subject?.setGeoAltitudeAccuracy(newValue)
        }
    }

    public var geoSpeed: NSNumber? {
        get {
            return subject?.geoSpeed()
        }
        set {
            subject?.setGeoSpeed(newValue)
        }
    }

    public var geoBearing: NSNumber? {
        get {
            return subject?.geoBearing()
        }
        set {
            subject?.setGeoBearing(newValue)
        }
    }

    public var geoTimestamp: NSNumber? {
        get {
            return subject?.geoTimestamp()
        }
        set {
            subject?.setGeoTimestamp(newValue)
        }
    }

    // MARK: - Private methods

    private var subject: Subject? {
        get {
            return serviceProvider.tracker().subject
        }
    }

    private var dirtyConfig: SubjectConfigurationUpdate {
        return serviceProvider.subjectConfigurationUpdate()
    }
}
