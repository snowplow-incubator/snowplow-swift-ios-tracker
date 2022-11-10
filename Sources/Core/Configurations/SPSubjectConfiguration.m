//
//  SPSubjectConfiguration.m
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

#import "SPSubjectConfiguration.h"
#import "NSDictionary+SP_TypeMethods.h"


@interface SPSize ()

@property (readwrite) NSInteger width;
@property (readwrite) NSInteger height;

@end

@implementation SPSize

- (instancetype) initWithWidth:(NSInteger)width height:(NSInteger)height {
    if (self = [super init]) {
        self.width = width;
        self.height = height;
    }
    return self;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    [coder encodeInteger:self.width forKey:@"width"];
    [coder encodeInteger:self.height forKey:@"height"];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
    if (self = [super init]) {
        self.width = [coder decodeIntegerForKey:@"width"];
        self.height = [coder decodeIntegerForKey:@"height"];
    }
    return self;
}

@end


@implementation SPSubjectConfiguration

@synthesize userId;
@synthesize networkUserId;
@synthesize domainUserId;
@synthesize useragent;
@synthesize ipAddress;
@synthesize timezone;
@synthesize language;
@synthesize screenResolution;
@synthesize screenViewPort;
@synthesize colorDepth;

@synthesize geoLatitude;
@synthesize geoLongitude;
@synthesize geoLatitudeLongitudeAccuracy;
@synthesize geoAltitude;
@synthesize geoAltitudeAccuracy;
@synthesize geoSpeed;
@synthesize geoBearing;
@synthesize geoTimestamp;

- (instancetype)initWithDictionary:(NSDictionary<NSString *,NSObject *> *)dictionary {
    if (self = [self init]) {
        self.userId = [dictionary sp_stringForKey:@"userId" defaultValue:self.userId];
        self.networkUserId = [dictionary sp_stringForKey:@"networkUserId" defaultValue:self.networkUserId];
        self.domainUserId = [dictionary sp_stringForKey:@"domainUserId" defaultValue:self.domainUserId];
        self.useragent = [dictionary sp_stringForKey:@"useragent" defaultValue:self.useragent];
        self.ipAddress = [dictionary sp_stringForKey:@"ipAddress" defaultValue:self.ipAddress];
        self.timezone = [dictionary sp_stringForKey:@"timezone" defaultValue:self.timezone];
        self.language = [dictionary sp_stringForKey:@"language" defaultValue:self.language];
    }
    return self;
}

// MARK: - Builder

- (instancetype)userId:(NSString *)value { self.userId = value; return self; }
- (instancetype)networkUserId:(NSString *)value { self.networkUserId = value; return self; }
- (instancetype)domainUserId:(NSString *)value { self.domainUserId = value; return self; }
- (instancetype)useragent:(NSString *)value { self.useragent = value; return self; }
- (instancetype)ipAddress:(NSString *)value { self.ipAddress = value; return self; }
- (instancetype)timezone:(NSString *)value { self.timezone = value; return self; }
- (instancetype)language:(NSString *)value { self.language = value; return self; }
- (instancetype)screenResolution:(SPSize *)value { self.screenResolution = value; return self; }
- (instancetype)screenViewPort:(SPSize *)value { self.screenViewPort = value; return self; }
- (instancetype)colorDepth:(NSNumber *)value { self.colorDepth = value; return self; }

// geolocation
- (instancetype)geoLatitude:(NSNumber *)value { self.geoLatitude = value; return self; }
- (instancetype)geoLongitude:(NSNumber *)value { self.geoLongitude = value; return self; }
- (instancetype)geoLatitudeLongitudeAccuracy:(NSNumber *)value { self.geoLatitudeLongitudeAccuracy = value; return self; }
- (instancetype)geoAltitude:(NSNumber *)value { self.geoAltitude = value; return self; }
- (instancetype)geoAltitudeAccuracy:(NSNumber *)value { self.geoAltitudeAccuracy = value; return self; }
- (instancetype)geoBearing:(NSNumber *)value { self.geoBearing = value; return self; }
- (instancetype)geoSpeed:(NSNumber *)value { self.geoSpeed = value; return self; }
- (instancetype)geoTimestamp:(NSNumber *)value { self.geoTimestamp = value; return self; }


// MARK: - NSCopying

- (id)copyWithZone:(nullable NSZone *)zone {
    SPSubjectConfiguration *copy = [[SPSubjectConfiguration allocWithZone:zone] init];
    copy.userId = self.userId;
    copy.networkUserId = self.networkUserId;
    copy.domainUserId = self.domainUserId;
    copy.useragent = self.useragent;
    copy.ipAddress = self.ipAddress;
    copy.timezone = self.timezone;
    copy.language = self.language;
    copy.screenResolution = self.screenResolution;
    copy.screenViewPort = self.screenViewPort;
    copy.colorDepth = self.colorDepth;

    // geolocation
    copy.geoLatitude = self.geoLatitude;
    copy.geoLongitude = self.geoLongitude;
    copy.geoLatitudeLongitudeAccuracy = self.geoLatitudeLongitudeAccuracy;
    copy.geoAltitude = self.geoAltitude;
    copy.geoAltitudeAccuracy = self.geoAltitudeAccuracy;
    copy.geoSpeed = self.geoSpeed;
    copy.geoBearing = self.geoBearing;
    copy.geoTimestamp = self.geoTimestamp;
    return copy;
}

// MARK: - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    [coder encodeObject:self.userId forKey:@"userId"];
    [coder encodeObject:self.networkUserId forKey:@"networkUserId"];
    [coder encodeObject:self.domainUserId forKey:@"domainUserId"];
    [coder encodeObject:self.useragent forKey:@"useragent"];
    [coder encodeObject:self.ipAddress forKey:@"ipAddress"];
    [coder encodeObject:self.timezone forKey:@"timezone"];
    [coder encodeObject:self.language forKey:@"language"];
    [coder encodeObject:self.screenResolution forKey:@"screenResolution"];
    [coder encodeObject:self.screenViewPort forKey:@"screenViewPort"];
    [coder encodeObject:self.colorDepth forKey:@"colorDepth"];
    // geolocation
    [coder encodeObject:self.geoLatitude forKey:@"geoLatitude"];
    [coder encodeObject:self.geoLongitude forKey:@"geoLongitude"];
    [coder encodeObject:self.geoLatitudeLongitudeAccuracy forKey:@"geoLatitudeLongitudeAccuracy"];
    [coder encodeObject:self.geoAltitude forKey:@"geoAltitude"];
    [coder encodeObject:self.geoAltitudeAccuracy forKey:@"geoAltitudeAccuracy"];
    [coder encodeObject:self.geoSpeed forKey:@"geoSpeed"];
    [coder encodeObject:self.geoBearing forKey:@"geoBearing"];
    [coder encodeObject:self.geoTimestamp forKey:@"geoTimestamp"];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
    if (self = [super init]) {
        self.userId = [coder decodeObjectForKey:@"userId"];
        self.networkUserId = [coder decodeObjectForKey:@"networkUserId"];
        self.domainUserId = [coder decodeObjectForKey:@"domainUserId"];
        self.useragent = [coder decodeObjectForKey:@"useragent"];
        self.ipAddress = [coder decodeObjectForKey:@"ipAddress"];
        self.timezone = [coder decodeObjectForKey:@"timezone"];
        self.language = [coder decodeObjectForKey:@"language"];
        self.screenResolution = [coder decodeObjectForKey:@"screenResolution"];
        self.screenViewPort = [coder decodeObjectForKey:@"screenViewPort"];
        self.colorDepth = [coder decodeObjectForKey:@"colorDepth"];
        // geolocation
        self.geoLatitude = [coder decodeObjectForKey:@"geoLatitude"];
        self.geoLongitude = [coder decodeObjectForKey:@"geoLongitude"];
        self.geoLatitudeLongitudeAccuracy = [coder decodeObjectForKey:@"geoLatitudeLongitudeAccuracy"];
        self.geoAltitude = [coder decodeObjectForKey:@"geoAltitude"];
        self.geoAltitudeAccuracy = [coder decodeObjectForKey:@"geoAltitudeAccuracy"];
        self.geoSpeed = [coder decodeObjectForKey:@"geoSpeed"];
        self.geoBearing = [coder decodeObjectForKey:@"geoBearing"];
        self.geoTimestamp = [coder decodeObjectForKey:@"geoTimestamp"];
    }
    return self;
}

@end

