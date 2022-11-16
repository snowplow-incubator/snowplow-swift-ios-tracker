//
//  SPTrackerConfigurationUpdate.h
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

@objc(SPTrackerConfigurationUpdate)
public class TrackerConfigurationUpdate: TrackerConfiguration {
    @objc public var sourceConfig: TrackerConfiguration?
    @objc public var isPaused = false
    @objc var appIdUpdated = false
    @objc var devicePlatformUpdated = false
    @objc var base64EncodingUpdated = false
    @objc var logLevelUpdated = false
    @objc var loggerDelegateUpdated = false
    @objc var applicationContextUpdated = false
    @objc var platformContextUpdated = false
    @objc var geoLocationContextUpdated = false
    @objc var deepLinkContextUpdated = false
    @objc var sessionContextUpdated = false
    @objc var screenContextUpdated = false
    @objc var screenViewAutotrackingUpdated = false
    @objc var lifecycleAutotrackingUpdated = false
    @objc var installAutotrackingUpdated = false
    @objc var exceptionAutotrackingUpdated = false
    @objc var diagnosticAutotrackingUpdated = false
    @objc var userAnonymisationUpdated = false
    @objc var trackerVersionSuffixUpdated = false

    @objc override public var appId: String {
        get {
            return ((sourceConfig == nil) || appIdUpdated) ? super.appId : sourceConfig?.appId ?? ""
        }
        set { super.appId = newValue }
    }

    @objc override public var devicePlatform: DevicePlatform {
        get {
            return ((sourceConfig == nil) || devicePlatformUpdated) ? super.devicePlatform : sourceConfig?.devicePlatform ?? DevicePlatform.mobile
        }
        set {
            super.devicePlatform = newValue
            devicePlatformUpdated = true
        }
    }

    @objc override public var base64Encoding: Bool {
        get {
            return ((sourceConfig == nil) || base64EncodingUpdated) ? super.base64Encoding : sourceConfig?.base64Encoding ?? true
        }
        set {
            super.base64Encoding = newValue
            base64EncodingUpdated = true
        }
    }

    @objc override public var logLevel: LogLevel {
        get {
            return ((sourceConfig == nil) || logLevelUpdated) ? super.logLevel : sourceConfig?.logLevel ?? LogLevel.off
        }
        set {
            super.logLevel = newValue
            logLevelUpdated = true
        }
    }

    @objc override public var loggerDelegate: LoggerDelegate? {
        get {
            return ((sourceConfig == nil) || loggerDelegateUpdated) ? super.loggerDelegate : sourceConfig?.loggerDelegate
        }
        set {
            super.loggerDelegate = newValue
            loggerDelegateUpdated = true
        }
    }

    @objc override public var applicationContext: Bool {
        get {
            return ((sourceConfig == nil) || applicationContextUpdated) ? super.applicationContext : sourceConfig?.applicationContext ?? true
        }
        set {
            super.applicationContext = newValue
            applicationContextUpdated = true
        }
    }

    @objc override public var platformContext: Bool {
        get {
            return ((sourceConfig == nil) || platformContextUpdated) ? super.platformContext : sourceConfig?.platformContext ?? true
        }
        set {
            super.platformContext = newValue
            platformContextUpdated = true
        }
    }

    @objc override public var geoLocationContext: Bool {
        get {
            return ((sourceConfig == nil) || geoLocationContextUpdated) ? super.geoLocationContext : sourceConfig?.geoLocationContext ?? false
        }
        set {
            super.geoLocationContext = newValue
            geoLocationContextUpdated = true
        }
    }

    @objc override public var deepLinkContext: Bool {
        get {
            return ((sourceConfig == nil) || deepLinkContextUpdated) ? super.deepLinkContext : sourceConfig?.deepLinkContext ?? true
        }
        set {
            super.deepLinkContext = newValue
            deepLinkContextUpdated = true
        }
    }

    @objc override public var sessionContext: Bool {
        get {
            return ((sourceConfig == nil) || sessionContextUpdated) ? super.sessionContext : sourceConfig?.sessionContext ?? true
        }
        set {
            super.sessionContext = newValue
            sessionContextUpdated = true
        }
    }

    @objc override public var screenContext: Bool {
        get {
            return ((sourceConfig == nil) || screenContextUpdated) ? super.screenContext : sourceConfig?.screenContext ?? true
        }
        set {
            super.screenContext = newValue
            screenContextUpdated = true
        }
    }

    @objc override public var screenViewAutotracking: Bool {
        get {
            return ((sourceConfig == nil) || screenViewAutotrackingUpdated) ? super.screenViewAutotracking : sourceConfig?.screenViewAutotracking ?? true
        }
        set {
            super.screenViewAutotracking = newValue
            screenViewAutotrackingUpdated = true
        }
    }

    @objc override public var lifecycleAutotracking: Bool {
        get {
            return ((sourceConfig == nil) || lifecycleAutotrackingUpdated) ? super.lifecycleAutotracking : sourceConfig?.lifecycleAutotracking ?? false
        }
        set {
            super.lifecycleAutotracking = newValue
            lifecycleAutotrackingUpdated = true
        }
    }

    @objc override public var installAutotracking: Bool {
        get {
            return ((sourceConfig == nil) || installAutotrackingUpdated) ? super.installAutotracking : sourceConfig?.installAutotracking ?? true
        }
        set {
            super.installAutotracking = newValue
            installAutotrackingUpdated = true
        }
    }

    @objc override public var exceptionAutotracking: Bool {
        get {
            return ((sourceConfig == nil) || exceptionAutotrackingUpdated) ? super.exceptionAutotracking : sourceConfig?.exceptionAutotracking ?? true
        }
        set {
            super.exceptionAutotracking = newValue
            exceptionAutotrackingUpdated = true
        }
    }

    @objc override public var diagnosticAutotracking: Bool {
        get {
            return ((sourceConfig == nil) || diagnosticAutotrackingUpdated) ? super.diagnosticAutotracking : sourceConfig?.diagnosticAutotracking ?? false
        }
        set {
            super.diagnosticAutotracking = newValue
            diagnosticAutotrackingUpdated = true
        }
    }

    @objc override public var userAnonymisation: Bool {
        get {
            return ((sourceConfig == nil) || userAnonymisationUpdated) ? super.userAnonymisation : sourceConfig?.userAnonymisation ?? false
        }
        set {
            super.userAnonymisation = newValue
            userAnonymisationUpdated = true
        }
    }

    override public var trackerVersionSuffix: String? {
        get {
            return ((sourceConfig == nil) || trackerVersionSuffixUpdated) ? super.trackerVersionSuffix : sourceConfig?.trackerVersionSuffix
        }
        set {
            super.trackerVersionSuffix = newValue
            trackerVersionSuffixUpdated = true
        }
    }
}
