//
//  SPEmitterConfiguration.m
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

#import "SPEmitterConfiguration.h"

@implementation SPEmitterConfiguration

@synthesize bufferOption;
@synthesize byteLimitGet;
@synthesize byteLimitPost;
@synthesize emitRange;
@synthesize threadPoolSize;
@synthesize requestCallback;
@synthesize customRetryForStatusCodes;
@synthesize serverAnonymisation;

- (instancetype)init {
    if (self = [super init]) {
        self.bufferOption = SPBufferOptionSingle;
        self.emitRange = 150;
        self.threadPoolSize = 15;
        self.byteLimitGet = 40000;
        self.byteLimitPost = 40000;
        self.eventStore = nil;
        self.requestCallback = nil;
        self.serverAnonymisation = NO;
    }
    return self;
}

// MARK: - Builder

- (instancetype)bufferOption:(SPBufferOption)value { self.bufferOption = value; return self; }
- (instancetype)emitRange:(NSInteger)value { self.emitRange = value; return self; }
- (instancetype)threadPoolSize:(NSInteger)value { self.threadPoolSize = value; return self; }
- (instancetype)byteLimitGet:(NSInteger)value { self.byteLimitGet = value; return self; }
- (instancetype)byteLimitPost:(NSInteger)value { self.byteLimitPost = value; return self; }
- (instancetype)requestCallback:(id<SPRequestCallback>)value { self.requestCallback = value; return self; }
- (instancetype)customRetryForStatusCodes:(NSDictionary *)value { self.customRetryForStatusCodes = value; return self; }
- (instancetype)serverAnonymisation:(BOOL)value { self.serverAnonymisation = value; return self; }

- (instancetype)eventStore:(id<SPEventStore>)value { self.eventStore = value; return self; }

// MARK: - NSCopying

- (id)copyWithZone:(nullable NSZone *)zone {
    SPEmitterConfiguration *copy = [[SPEmitterConfiguration allocWithZone:zone] init];
    copy.bufferOption = self.bufferOption;
    copy.emitRange = self.emitRange;
    copy.threadPoolSize = self.threadPoolSize;
    copy.byteLimitGet = self.byteLimitGet;
    copy.byteLimitPost = self.byteLimitPost;
    copy.requestCallback = self.requestCallback;
    copy.eventStore = self.eventStore;
    copy.customRetryForStatusCodes = self.customRetryForStatusCodes;
    copy.serverAnonymisation = self.serverAnonymisation;
    return copy;
}

// MARK: - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    [coder encodeInteger:self.bufferOption forKey:@"bufferOption"];
    [coder encodeInteger:self.emitRange forKey:@"emitRange"];
    [coder encodeInteger:self.threadPoolSize forKey:@"threadPoolSize"];
    [coder encodeInteger:self.byteLimitGet forKey:@"byteLimitGet"];
    [coder encodeInteger:self.byteLimitPost forKey:@"byteLimitPost"];
    [coder encodeObject:self.customRetryForStatusCodes forKey:@"customRetryForStatusCodes"];
    [coder encodeBool:self.serverAnonymisation forKey:@"serverAnonymisation"];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
    if (self = [super init]) {
        self.bufferOption = [coder decodeIntegerForKey:@"bufferOption"];
        self.emitRange = [coder decodeIntegerForKey:@"emitRange"];
        self.threadPoolSize = [coder decodeIntegerForKey:@"threadPoolSize"];
        self.byteLimitGet = [coder decodeIntegerForKey:@"byteLimitGet"];
        self.byteLimitPost = [coder decodeIntegerForKey:@"byteLimitPost"];
        self.customRetryForStatusCodes = [coder decodeObjectForKey:@"customRetryForStatusCodes"];
        self.serverAnonymisation = [coder decodeBoolForKey:@"serverAnonymisation"];
    }
    return self;
}

@end
