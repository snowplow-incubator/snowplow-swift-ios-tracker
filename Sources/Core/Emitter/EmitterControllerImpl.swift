//
//  SPEmitterControllerImpl.swift
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

@objc(SPEmitterControllerImpl)
public class EmitterControllerImpl: Controller, EmitterController {

    // MARK: - Properties

    public var bufferOption: BufferOption {
        get {
            return BufferOption(rawValue:  emitter.getBufferOptionRawValue())!
        }
        set {
            dirtyConfig.bufferOption = newValue
            dirtyConfig.bufferOptionUpdated = true
            emitter.setBufferOptionRawValue(newValue.rawValue)
        }
    }

    public var byteLimitGet: Int {
        get {
            return emitter.byteLimitGet
        }
        set {
            dirtyConfig.byteLimitGet = newValue
            dirtyConfig.byteLimitGetUpdated = true
            emitter.setByteLimitGet(newValue)
        }
    }

    public var byteLimitPost: Int {
        get {
            return emitter.byteLimitPost
        }
        set {
            dirtyConfig.byteLimitPost = newValue
            dirtyConfig.byteLimitPostUpdated = true
            emitter.setByteLimitPost(newValue)
        }
    }

    public var serverAnonymisation: Bool {
        get {
            return emitter.serverAnonymisation
        }
        set {
            dirtyConfig.serverAnonymisation = newValue
            dirtyConfig.serverAnonymisationUpdated = true
            emitter.setServerAnonymisation(newValue)
        }
    }

    public var emitRange: Int {
        get {
            return emitter.emitRange
        }
        set {
            dirtyConfig.emitRange = newValue
            dirtyConfig.emitRangeUpdated = true
            emitter.setEmitRange(newValue)
        }
    }

    public var threadPoolSize: Int {
        get {
            return emitter.emitThreadPoolSize
        }
        set {
            dirtyConfig.threadPoolSize = newValue
            dirtyConfig.threadPoolSizeUpdated = true
            emitter.setEmitThreadPoolSize(newValue)
        }
    }

    private var _requestCallback: RequestCallback?
    public var requestCallback: RequestCallback? {
        get {
            return _requestCallback
        }
        set {
            _requestCallback = newValue
            emitter.setCallback(newValue)
        }
    }

    public var dbCount: Int {
        return Int(emitter.getDbCount())
    }

    public var isSending: Bool {
        return emitter.getSendingStatus()
    }
    
    public var customRetryForStatusCodes: [NSNumber : NSNumber]? {
        get {
            return emitter.customRetryForStatusCodes
        }
        set {
            dirtyConfig.customRetryForStatusCodes = newValue
            dirtyConfig.customRetryForStatusCodesUpdated = true
            emitter.setCustomRetryForStatusCodes(newValue)
        }
    }

    // MARK: - Methods

    public func flush() {
        emitter.flush()
    }

    public func pause() {
        dirtyConfig.isPaused = true
        emitter.pauseEmit()
    }

    public func resume() {
        dirtyConfig.isPaused = false
        emitter.resumeEmit()
    }

    // MARK: - Private methods

    private var emitter: Emitter {
        return serviceProvider.tracker().emitter
    }

    private var dirtyConfig: EmitterConfigurationUpdate {
        return serviceProvider.emitterConfigurationUpdate()
    }
}
