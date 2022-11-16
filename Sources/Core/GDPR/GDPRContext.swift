//
//  SPGdprContext.swift
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

@objc(SPGdprContext)
public class GDPRContext: NSObject {
    @objc private(set) public var basis: GDPRProcessingBasis
    @objc private(set) public var basisString: String
    @objc private(set) public var documentId: String?
    @objc private(set) public var documentVersion: String?
    @objc private(set) public var documentDescription: String?

    /// Set a GDPR context for the tracker
    /// - Parameters:
    ///   - basisForProcessing: Enum one of valid legal bases for processing.
    ///   - documentId: Document ID.
    ///   - documentVersion: Version of the document.
    ///   - documentDescription: Description of the document.
    @objc public init(
        basis basisForProcessing: GDPRProcessingBasis,
        documentId: String?,
        documentVersion: String?,
        documentDescription: String?
    ) {
        basisString = GDPRContext.string(from: basisForProcessing)
        basis = basisForProcessing
        self.documentId = documentId
        self.documentVersion = documentVersion
        self.documentDescription = documentDescription
        super.init()
    }

    /// Return context with value stored about GDPR processing.
    @objc public var context: SelfDescribingJson {
        get {
            var data: [String : String] = [:]
            data[kSPBasisForProcessing] = basisString
            data[kSPDocumentId] = documentId
            data[kSPDocumentVersion] = documentVersion
            data[kSPDocumentDescription] = documentDescription
            return SelfDescribingJson(schema: kSPGdprContextSchema, andDictionary: data)
        }
    }

    // MARK: Private methods

    static func string(from basis: GDPRProcessingBasis) -> String {
        switch basis {
        case .consent:
            return "consent"
        case .contract:
            return "contract"
        case .legalObligation:
            return "legal_obligation"
        case .vitalInterest:
            return "vital_interests"
        case .publicTask:
            return "public_task"
        case .legitimateInterests:
            return "legitimate_interests"
        default:
            return ""
        }
    }
}
