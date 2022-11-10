//
//  SPConfigurationBundle.m
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

#import "SPConfigurationBundle.h"
#import "NSDictionary+SP_TypeMethods.h"
#import "SPLogger.h"
#import <SnowplowTracker/SnowplowTracker-Swift.h>

@interface SPConfigurationBundle ()
@property (nonatomic, nonnull) NSString *namespace;
@end

@implementation SPConfigurationBundle

- (instancetype)initWithNamespace:(NSString *)namespace {
    return [self initWithNamespace:namespace networkConfiguration:nil];
}

- (instancetype)initWithNamespace:(NSString *)namespace networkConfiguration:(nullable SPNetworkConfiguration *)networkConfiguration {
    if (self = [super init]) {
        self.namespace = namespace;
        self.networkConfiguration = networkConfiguration;
    }
    return self;
}

- (NSArray<SPConfiguration *> *)configurations {
    NSMutableArray *array = [NSMutableArray new];
    if (self.networkConfiguration) {
        [array addObject:self.networkConfiguration];
    }
    if (self.trackerConfiguration) {
        [array addObject:self.trackerConfiguration];
    }
    if (self.subjectConfiguration) {
        [array addObject:self.subjectConfiguration];
    }
    if (self.sessionConfiguration) {
        [array addObject:self.sessionConfiguration];
    }
    return array;
}

- (instancetype)initWithDictionary:(NSDictionary<NSString *,NSObject *> *)dictionary {
    if (self = [super init]) {
        self.namespace = [dictionary sp_stringForKey:@"namespace" defaultValue:nil];
        if (!self.namespace) {
            SPLogDebug(@"Error assigning: namespace");
            return nil;
        }
        self.networkConfiguration = (SPNetworkConfiguration *)[dictionary sp_configurationForKey:@"networkConfiguration" configurationClass:SPNetworkConfiguration.class defaultValue:nil];
        self.trackerConfiguration = (SPTrackerConfiguration *)[dictionary sp_configurationForKey:@"trackerConfiguration" configurationClass:SPTrackerConfiguration.class defaultValue:nil];
        self.subjectConfiguration = (SPSubjectConfiguration *)[dictionary sp_configurationForKey:@"subjectConfiguration" configurationClass:SPSubjectConfiguration.class defaultValue:nil];
        self.sessionConfiguration = (SPSessionConfiguration *)[dictionary sp_configurationForKey:@"sessionConfiguration" configurationClass:SPSessionConfiguration.class defaultValue:nil];
    }
    return self;
}


// MARK: - NSCopying

- (id)copyWithZone:(nullable NSZone *)zone {
    SPConfigurationBundle *copy;
    copy.namespace = self.namespace;
    copy.networkConfiguration = [self.networkConfiguration copyWithZone:zone];
    copy.trackerConfiguration = [self.trackerConfiguration copyWithZone:zone];
    copy.subjectConfiguration = [self.subjectConfiguration copyWithZone:zone];
    copy.sessionConfiguration = [self.sessionConfiguration copyWithZone:zone];
    return copy;
}

// MARK: - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    [coder encodeObject:self.namespace forKey:@"namespace"];
    [coder encodeObject:self.networkConfiguration forKey:@"networkConfiguration"];
    [coder encodeObject:self.trackerConfiguration forKey:@"trackerConfiguration"];
    [coder encodeObject:self.subjectConfiguration forKey:@"subjectConfiguration"];
    [coder encodeObject:self.sessionConfiguration forKey:@"sessionConfiguration"];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
    if (self = [super init]) {
        self.namespace = [coder decodeObjectForKey:@"namespace"];
        self.networkConfiguration = [coder decodeObjectForKey:@"networkConfiguration"];
        self.trackerConfiguration = [coder decodeObjectForKey:@"trackerConfiguration"];
        self.subjectConfiguration = [coder decodeObjectForKey:@"subjectConfiguration"];
        self.sessionConfiguration = [coder decodeObjectForKey:@"sessionConfiguration"];
    }
    return self;
}

@end
