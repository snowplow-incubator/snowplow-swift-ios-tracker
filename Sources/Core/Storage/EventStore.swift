//
//  SPEventStore.swift
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

@objc(SPEventStore)
public protocol EventStore: NSObjectProtocol {
    /// Adds an event to the store.
    /// - Parameter payload: the payload to be added
    func addEvent(_ payload: Payload)
    /// Removes an event from the store.
    /// - Parameter storeId: the identifier of the event in the store.
    /// - Returns: a boolean of success to remove.
    func removeEvent(withId storeId: Int64) -> Bool
    /// Removes a range of events from the store.
    /// - Parameter storeIds: the events' identifiers in the store.
    /// - Returns: a boolean of success to remove.
    func removeEvents(withIds storeIds: [NSNumber]) -> Bool
    /// Empties the store of all the events.
    /// - Returns: a boolean of success to remove.
    func removeAllEvents() -> Bool
    /// Returns amount of events currently in the store.
    /// - Returns: the count of events in the store.
    func count() -> UInt
    /// Returns a list of EmitterEvent objects which contains events and related ids.
    /// - Parameter queryLimit: is the maximum number of events returned.
    /// - Returns: EmitterEvent objects containing storeIds and event payloads.
    func emittableEvents(withQueryLimit queryLimit: UInt) -> [EmitterEvent]
}
