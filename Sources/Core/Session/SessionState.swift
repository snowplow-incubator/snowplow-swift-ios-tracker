//
//  SPSessionState.swift
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

@objc(SPSessionState)
public class SessionState: NSObject, State {
    private(set) var firstEventId: String?
    private(set) var firstEventTimestamp: String?
    private(set) var previousSessionId: String?
    private(set) var sessionId: String
    private(set) var sessionIndex = 0
    private(set) var storage: String
    var userId: String

    var sessionContext: [String : NSObject] {
        return sessionDictionary
    }
    private var sessionDictionary: [String : NSObject] = [:]

    class func buildSessionDictionary(withFirstEventId firstEventId: String?, firstEventTimestamp: String?, currentSessionId: String, previousSessionId: String?, sessionIndex: Int, userId: String, storage: String) -> [String : NSObject] {
        var dictionary: [AnyHashable : Any] = [:]
        dictionary[kSPSessionPreviousId] = previousSessionId
        dictionary[kSPSessionId] = currentSessionId
        dictionary[kSPSessionFirstEventId] = firstEventId
        dictionary[kSPSessionFirstEventTimestamp] = firstEventTimestamp
        dictionary[kSPSessionIndex] = NSNumber(value: sessionIndex)
        dictionary[kSPSessionStorage] = storage
        dictionary[kSPSessionUserId] = userId
        return dictionary as? [String : NSObject] ?? [:]
    }

    init(firstEventId: String?, firstEventTimestamp: String?, currentSessionId: String, previousSessionId: String?, sessionIndex: Int, userId: String, storage: String) {
        self.firstEventId = firstEventId
        self.firstEventTimestamp = firstEventTimestamp
        sessionId = currentSessionId
        self.previousSessionId = previousSessionId
        self.sessionIndex = sessionIndex
        self.userId = userId
        self.storage = storage

        sessionDictionary = SessionState.buildSessionDictionary(
            withFirstEventId: firstEventId,
            firstEventTimestamp: firstEventTimestamp,
            currentSessionId: currentSessionId,
            previousSessionId: previousSessionId,
            sessionIndex: sessionIndex,
            userId: userId,
            storage: storage)
    }

    init?(storedState: [String : NSObject]) {
        guard let sessionId = storedState[kSPSessionId] as? String,
              let sessionIndex = storedState[kSPSessionIndex] as? Int,
              let userId = storedState[kSPSessionUserId] as? String else {
            return nil
        }
        
        self.sessionId = sessionId
        self.sessionIndex = sessionIndex
        self.userId = userId

        previousSessionId = storedState[kSPSessionPreviousId] as? String

        // The FirstEventId should be stored in legacy persisted sessions even
        // if it wasn't used. Anyway we provide a default value in order to be
        // defensive and exclude any possible issue with a missing value.
        firstEventId = storedState[kSPSessionFirstEventId] as? String ?? "00000000-0000-0000-0000-000000000000"
        firstEventTimestamp = storedState[kSPSessionFirstEventTimestamp] as? String

        storage = storedState[kSPSessionStorage] as? String ?? "LOCAL_STORAGE"

        sessionDictionary = SessionState.buildSessionDictionary(
            withFirstEventId: firstEventId,
            firstEventTimestamp: firstEventTimestamp ?? "",
            currentSessionId: sessionId,
            previousSessionId: previousSessionId ?? "",
            sessionIndex: sessionIndex,
            userId: userId,
            storage: storage)
    }
}
