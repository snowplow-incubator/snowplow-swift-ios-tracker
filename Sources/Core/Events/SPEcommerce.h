//
//  SPEcommerce.h
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

#import "SPEventBase.h"
#import "SPEcommerceItem.h"

NS_ASSUME_NONNULL_BEGIN

/// An ecommerce event.
NS_SWIFT_NAME(Ecommerce)
@interface SPEcommerce : SPPrimitiveAbstract

/// Identifier of the order.
@property (nonatomic, readonly) NSString *orderId;
/// Total amount of the order.
@property (nonatomic, readonly) NSNumber *totalValue;
/// Items purchased.
@property (nonatomic, readonly) NSArray<SPEcommerceItem *> *items;
/// Identifies an affiliation.
@property (nonatomic, nullable) NSString *affiliation;
/// Taxes applied to the purchase.
@property (nonatomic, nullable) NSNumber *taxValue;
/// Shipping number.
@property (nonatomic, nullable) NSNumber *shipping;
/// City for shipping.
@property (nonatomic, nullable) NSString *city;
/// State for shipping.
@property (nonatomic, nullable) NSString *state;
/// Country for shipping.
@property (nonatomic, nullable) NSString *country;
/// Currency used for totalValue and taxValue.
@property (nonatomic, nullable) NSString *currency;

- (instancetype)init NS_UNAVAILABLE;

/**
 Creates an ecommerce event.
 @param orderId Identifier of the order.
 @param totalValue Total amount of the order.
 @param items Items purchased.
 */
- (instancetype)initWithOrderId:(NSString *)orderId totalValue:(NSNumber *)totalValue items:(NSArray<SPEcommerceItem *> *)items NS_SWIFT_NAME(init(orderId:totalValue:items:));

/// List of the items purchased.
- (NSArray<SPEcommerceItem *> *)getItems;

/// Identifies an affiliation.
- (instancetype)affiliation:(nullable NSString *)value NS_SWIFT_NAME(affiliation(_:));
/// Taxes applied to the purchase.
- (instancetype)taxValue:(nullable NSNumber *)value NS_SWIFT_NAME(taxValue(_:));
/// Shipping number.
- (instancetype)shipping:(nullable NSNumber *)value NS_SWIFT_NAME(shipping(_:));
/// City for shipping.
- (instancetype)city:(nullable NSString *)value NS_SWIFT_NAME(city(_:));
/// State for shipping.
- (instancetype)state:(nullable NSString *)value NS_SWIFT_NAME(state(_:));
/// Country for shipping.
- (instancetype)country:(nullable NSString *)value NS_SWIFT_NAME(country(_:));
/// Currency used for totalValue and taxValue.
- (instancetype)currency:(nullable NSString *)value NS_SWIFT_NAME(currency(_:));

@end

NS_ASSUME_NONNULL_END
