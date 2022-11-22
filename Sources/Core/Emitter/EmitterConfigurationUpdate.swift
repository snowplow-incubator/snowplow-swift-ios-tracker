//  SPEmitterConfigurationUpdate.swift
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

@objc(SPEmitterConfigurationUpdate)
public class EmitterConfigurationUpdate: EmitterConfiguration {
    @objc public var sourceConfig: EmitterConfiguration?
    @objc public var isPaused = false
    var bufferOptionUpdated = false
    var byteLimitGetUpdated = false
    var byteLimitPostUpdated = false
    var emitRangeUpdated = false
    var threadPoolSizeUpdated = false
    var customRetryForStatusCodesUpdated = false
    var serverAnonymisationUpdated = false
    var eventStoreUpdated = false
    var requestCallbackUpdated = false

    @objc public override var eventStore: EventStore? {
        get {
            return ((sourceConfig == nil || eventStoreUpdated) ? super.eventStore : sourceConfig?.eventStore)
        }
        set {
            super.eventStore = newValue
            eventStoreUpdated = true
        }
    }

    @objc public override var requestCallback: RequestCallback? {
        get {
            return ((sourceConfig == nil || requestCallbackUpdated) ? super.requestCallback : sourceConfig?.requestCallback)
        }
        set {
            super.requestCallback = newValue
            requestCallbackUpdated = true
        }
    }

    @objc public override var bufferOption: BufferOption {
        get {
            return ((sourceConfig == nil || bufferOptionUpdated) ? super.bufferOption : sourceConfig?.bufferOption) ?? BufferOption.defaultGroup
        }
        set {
            super.bufferOption = newValue
            bufferOptionUpdated = true
        }
    }

    @objc public override var emitRange: Int {
        get {
            return ((sourceConfig == nil || emitRangeUpdated) ? super.emitRange : sourceConfig?.emitRange) ?? 0
        }
        set {
            super.emitRange = newValue
            emitRangeUpdated = true
        }
    }

    @objc public override var threadPoolSize: Int {
        get {
            return ((sourceConfig == nil || threadPoolSizeUpdated) ? super.threadPoolSize : sourceConfig?.threadPoolSize) ?? 0
        }
        set {
            super.threadPoolSize = newValue
            threadPoolSizeUpdated = true
        }
    }

    @objc public override var byteLimitGet: Int {
        get {
            return ((sourceConfig == nil || byteLimitGetUpdated) ? super.byteLimitGet : sourceConfig?.byteLimitGet) ?? 0
        }
        set {
            super.byteLimitGet = newValue
            byteLimitGetUpdated = true
        }
    }

    @objc public override var byteLimitPost: Int {
        get {
            return ((sourceConfig == nil || byteLimitPostUpdated) ? super.byteLimitPost : sourceConfig?.byteLimitPost) ?? 0
        }
        set {
            super.byteLimitPost = newValue
            byteLimitPostUpdated = true
        }
    }

    @objc public override var customRetryForStatusCodes: [NSNumber : NSNumber]? {
        get {
            return ((sourceConfig == nil || customRetryForStatusCodesUpdated) ? super.customRetryForStatusCodes : sourceConfig?.customRetryForStatusCodes)
        }
        set {
            super.customRetryForStatusCodes = newValue
            customRetryForStatusCodesUpdated = true
        }
    }

    @objc public override var serverAnonymisation: Bool {
        get {
            return ((sourceConfig == nil || serverAnonymisationUpdated) ? super.serverAnonymisation : sourceConfig?.serverAnonymisation) ?? false
        }
        set {
            super.serverAnonymisation = newValue
            serverAnonymisationUpdated = true
        }
    }
}
