//  SPGDPRControllerImpl.swift
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

@objc(SPGDPRControllerImpl)
public class GDPRControllerImpl: Controller, GDPRController {
    var gdpr: GDPRContext?
    
    // MARK: - Methods

    public func reset(
        basis basisForProcessing: GDPRProcessingBasis,
        documentId: String?,
        documentVersion: String?,
        documentDescription: String?
    ) {
        gdpr = GDPRContext(
            basis: basisForProcessing,
            documentId: documentId,
            documentVersion: documentVersion,
            documentDescription: documentDescription)
        tracker.gdprContext = gdpr
        dirtyConfig.gdpr = gdpr
        dirtyConfig.gdprUpdated = true
    }

    public func disable() {
        dirtyConfig.isEnabled = false
        tracker.gdprContext = nil
    }

    public var isEnabled: Bool {
        get {
            return tracker.gdprContext != nil
        }
    }

    public func enable() -> Bool {
        if let gdpr { tracker.gdprContext = gdpr }
        else { return false }
        dirtyConfig.isEnabled = true
        return true
    }

    public var basisForProcessing: GDPRProcessingBasis {
        get {
            return ((gdpr)?.basis)!
        }
    }

    public var documentId: String? {
        get {
            return (gdpr)?.documentId
        }
    }

    public var documentVersion: String? {
        get {
            return (gdpr)?.documentVersion
        }
    }

    public var documentDescription: String? {
        get {
            return (gdpr)?.documentDescription
        }
    }

    // MARK: - Private methods

    public var tracker: Tracker {
        get {
            return serviceProvider.tracker
        }
    }

    public var dirtyConfig: GDPRConfigurationUpdate {
        get {
            return serviceProvider.gdprConfigurationUpdate
        }
    }
}
