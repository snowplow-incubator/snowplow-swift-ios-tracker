//
//  SPGDPRConfigurationUpdate.swift
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

@objc(SPGDPRConfigurationUpdate)
public class GDPRConfigurationUpdate: GDPRConfiguration {
    @objc public var sourceConfig: GDPRConfiguration?
    var gdpr: GDPRContext?
    var isEnabled = false
    var gdprUpdated = false

    public override var basisForProcessing: GDPRProcessingBasis {
        get {
            return ((sourceConfig == nil || basisForProcessingUpdated) ? super.basisForProcessing : sourceConfig?.basisForProcessing)!
        }
        set {
            super.basisForProcessing = newValue
            basisForProcessingUpdated = true
        }
    }

    public override var documentId: String? {
        get {
            return ((sourceConfig == nil || documentIdUpdated) ? super.documentId : sourceConfig?.documentId)
        }
        set {
            super.documentId = newValue
            documentIdUpdated = true
        }
    }

    public override var documentVersion: String? {
        get {
            return ((sourceConfig == nil || documentVersionUpdated) ? super.documentVersion : sourceConfig?.documentVersion)
        }
        set {
            super.documentVersion = newValue
            documentVersionUpdated = true
        }
    }

    public override var documentDescription: String? {
        get {
            return ((sourceConfig == nil || documentDescriptionUpdated) ? super.documentDescription : sourceConfig?.documentDescription)
        }
        set {
            super.documentDescription = newValue
            documentDescriptionUpdated = true
        }
    }

    // Private methods

    var basisForProcessingUpdated: Bool {
        get {
            return gdprUpdated
        }
        set {
            gdprUpdated = newValue
        }
    }

    var documentIdUpdated: Bool {
        get {
            return gdprUpdated
        }
        set {
            gdprUpdated = newValue
        }
    }

    public var documentVersionUpdated: Bool {
        get {
            return gdprUpdated
        }
        set {
            gdprUpdated = newValue
        }
    }

    public var documentDescriptionUpdated: Bool {
        get {
            return gdprUpdated
        }
        set {
            gdprUpdated = newValue
        }
    }
    
    @objc public init() {
        super.init(basis: .consent, documentId: nil, documentVersion: nil, documentDescription: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
