//
//  SPConsentDocument.m
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

#import "SPConsentDocument.h"

#import "SPTrackerConstants.h"
#import "SPUtilities.h"
#import "SPPayload.h"
#import "SPSelfDescribingJson.h"

@interface SPConsentDocument ()

@property (nonatomic, readwrite) NSString *documentId;
@property (nonatomic, readwrite) NSString *version;

@end

@implementation SPConsentDocument

- (instancetype)initWithDocumentId:(NSString *)documentId version:(NSString *)version {
    if (self = [super init]) {
        _documentId = documentId;
        _version = version;
        [SPUtilities checkArgument:(_documentId != nil) withMessage:@"Document ID cannot be nil."];
        [SPUtilities checkArgument:(_version != nil) withMessage:@"Version cannot be nil."];
    }
    return self;
}

// --- Builder Methods

- (instancetype)name:(NSString *)value { self.name = value; return self; }
- (instancetype)documentDescription:(NSString *)value { self.documentDescription = value; return self; }

// --- Public Methods

- (SPSelfDescribingJson *)getPayload {
    NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
    event[kSPCdId] = _documentId;
    event[kSPCdVersion] = _version;
    if (_name.length != 0) {
        event[kSPCdName] = _name;
    }
    if (_documentDescription.length != 0) {
        event[KSPCdDescription] = _documentDescription;
    }
    return [[SPSelfDescribingJson alloc] initWithSchema:kSPConsentDocumentSchema
                                                andData:event];
}

@end

