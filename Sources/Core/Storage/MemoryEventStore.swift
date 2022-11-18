//
//  SPMemoryEventStore.swift
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

@objc(SPMemoryEventStore)
public class MemoryEventStore: NSObject, EventStore {

    var sendLimit: UInt
    var index: Int64
    var orderedSet: NSMutableOrderedSet


    convenience override init() {
        self.init(limit: 250)
    }

    init(limit: UInt) {
        orderedSet = NSMutableOrderedSet()
        sendLimit = limit
        index = 0
    }

    // Interface methods

    public func addEvent(_ payload: Payload) {
        objc_sync_enter(self)
        let item = EmitterEvent(payload: payload, storeId: index)
        orderedSet.add(item)
        objc_sync_exit(self)
        index += 1
    }

    public func count() -> UInt {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        return UInt(orderedSet.count)
    }

    public func emittableEvents(withQueryLimit queryLimit: UInt) -> [EmitterEvent] {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        let setCount = (orderedSet).count
        if setCount <= 0 {
            return []
        }
        let len = min(Int(queryLimit), setCount)
        let range = NSRange(location: 0, length: len)
        var count = 0
        let indexes = orderedSet.indexes { _, _, _ in
            count += 1
            return count <= queryLimit
        }
        let objects = orderedSet.objects(at: indexes)
        var result: [EmitterEvent] = []
        for object in objects {
            if let event = object as? EmitterEvent {
                result.append(event)
            }
        }
        return result
    }

    public func removeAllEvents() -> Bool {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        orderedSet.removeAllObjects()
        return true
    }

    public func removeEvent(withId storeId: Int64) -> Bool {
        return removeEvents(withIds: [NSNumber(value: storeId)])
    }

    public func removeEvents(withIds storeIds: [NSNumber]) -> Bool {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        var itemsToRemove: [EmitterEvent] = []
        for item in orderedSet {
            guard let item = item as? EmitterEvent else {
                continue
            }
            if storeIds.contains(NSNumber(value: item.storeId)) {
                itemsToRemove.append(item)
            }
        }
        orderedSet.removeObjects(in: itemsToRemove)
        return true
    }
}
