//
//  SPScreenView.m
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

#import "SPScreenView.h"

#import "SPTrackerConstants.h"
#import "SPUtilities.h"
#import "SPScreenState.h"


@interface SPScreenView ()

@property (nonatomic, readwrite) NSString *name;
@property (nonatomic, readwrite) NSString *screenId;

@end

@implementation SPScreenView

- (instancetype)initWithName:(NSString *)name screenId:(nullable NSUUID *)screenId {
    if (self = [super init]) {
        _screenId = (screenId ?: [NSUUID UUID]).UUIDString;
        _name = name;
        [SPUtilities checkArgument:(_name.length != 0) withMessage:@"Name cannot be empty."];
        [SPUtilities checkArgument:([SPUtilities isUUIDString:_screenId]) withMessage:@"ScreenID has to be a valid UUID string."];
    }
    return self;
}

// --- Builder Methods

- (instancetype)type:(NSString *)value { self.type = value; return self; }
- (instancetype)previousName:(NSString *)value { self.previousName = value; return self; }
- (instancetype)previousId:(NSString *)value { self.previousId = value; return self; }
- (instancetype)previousType:(NSString *)value { self.previousType = value; return self; }
- (instancetype)transitionType:(NSString *)value { self.transitionType = value; return self; }
- (instancetype)viewControllerClassName:(NSString *)value { self.viewControllerClassName = value; return self; }
- (instancetype)topViewControllerClassName:(NSString *)value { self.topViewControllerClassName = value; return self; }

// --- Public Methods

- (NSString *)schema {
    return kSPScreenViewSchema;
}

- (NSDictionary<NSString *, NSObject *> *)payload {
    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
    [payload setValue:_name forKey:kSPSvName];
    [payload setValue:_screenId forKey:kSPSvScreenId];
    [payload setValue:_type forKey:kSPSvType];
    [payload setValue:_previousName forKey:kSPSvPreviousName];
    [payload setValue:_previousType forKey:kSPSvPreviousType];
    [payload setValue:_previousId forKey:kSPSvPreviousScreenId];
    [payload setValue:_transitionType forKey:kSPSvTransitionType];
    return payload;
}

@end
