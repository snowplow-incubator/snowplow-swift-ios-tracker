//
//  SPConsentWithdrawn.h
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

@class SPSelfDescribingJson;

NS_ASSUME_NONNULL_BEGIN

/// A consent withdrawn event.
NS_SWIFT_NAME(ConsentWithdrawn)
@interface SPConsentWithdrawn : SPSelfDescribingAbstract

/// Consent to all.
@property (nonatomic) BOOL all;
/// Identifier of the first document.
@property (nonatomic, nullable) NSString *documentId;
/// Version of the first document.
@property (nonatomic, nullable) NSString *version;
/// Name of the first document.
@property (nonatomic, nullable) NSString *name;
/// Description of the first document.
@property (nonatomic, nullable) NSString *documentDescription;
/// Other documents.
@property (nonatomic, nullable) NSArray<SPSelfDescribingJson *> *documents;

/// Retuns the full list of attached documents.
- (NSArray<SPSelfDescribingJson *> *)getDocuments;

/// Consent to all.
- (instancetype)all:(BOOL)value NS_SWIFT_NAME(all(_:));
/// Identifier of the first document.
- (instancetype)documentId:(nullable NSString *)value NS_SWIFT_NAME(documentId(_:));
/// Version of the first document.
- (instancetype)version:(nullable NSString *)value NS_SWIFT_NAME(version(_:));
/// Name of the first document.
- (instancetype)name:(nullable NSString *)value NS_SWIFT_NAME(name(_:));
/// Description of the first document.
- (instancetype)documentDescription:(nullable NSString *)value NS_SWIFT_NAME(documentDescription(_:));
/// Other documents.
- (instancetype)documents:(nullable NSArray<SPSelfDescribingJson *> *)value NS_SWIFT_NAME(documents(_:));

@end

NS_ASSUME_NONNULL_END
