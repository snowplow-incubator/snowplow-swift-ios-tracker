//
//  Ecommerce.swift
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

public class Ecommerce : PrimitiveAbstract {
    /// Identifier of the order.
    public var orderId: String
    /// Total amount of the order.
    public var totalValue: Double
    /// Items purchased.
    public var items: [EcommerceItem]
    /// Identifies an affiliation.
    public var affiliation: String?
    /// Taxes applied to the purchase.
    public var taxValue: Double?
    /// Shipping number.
    public var shipping: Double?
    /// City for shipping.
    public var city: String?
    /// State for shipping.
    public var state: String?
    /// Country for shipping.
    public var country: String?
    /// Currency used for totalValue and taxValue.
    public var currency: String?

    public init(orderId: String, totalValue: Double, items: [EcommerceItem]?) {
        self.orderId = orderId
        self.totalValue = totalValue
        self.items = items ?? []
    }

    override public var eventName: String {
        return kSPEventEcomm
    }

    override public var payload: [String : NSObject] {
        var payload: [String : NSObject] = [:]
        payload[kSPEcommTotal] = String(format: "%.02f", totalValue) as NSObject
        if let taxValue {
            payload[kSPEcommTax] = String(format: "%.02f", taxValue) as NSObject
        }
        if let shipping {
            payload[kSPEcommShipping] = String(format: "%.02f", shipping) as NSObject
        }
        payload[kSPEcommId] = orderId as NSObject
        payload[kSPEcommAffiliation] = affiliation as NSObject?
        payload[kSPEcommCity] = city as NSObject?
        payload[kSPEcommState] = state as NSObject?
        payload[kSPEcommCountry] = country as NSObject?
        payload[kSPEcommCurrency] = currency as NSObject?
        return payload
    }

    override func endProcessing(withTracker tracker: Tracker?) {
        for item in items {
            item.orderId = orderId
            _ = tracker?.track(item)
        }
    }
}
