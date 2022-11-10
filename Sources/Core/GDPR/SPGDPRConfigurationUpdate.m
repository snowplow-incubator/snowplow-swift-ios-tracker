//
//  SPGDPRConfigurationUpdate.m
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

#import "SPGDPRConfigurationUpdate.h"

@implementation SPGDPRConfigurationUpdate

- (SPGdprProcessingBasis)basisForProcessing { return (!self.sourceConfig || self.basisForProcessingUpdated) ? super.basisForProcessing : self.sourceConfig.basisForProcessing; }
- (NSString *)documentId { return (!self.sourceConfig || self.documentIdUpdated) ? super.documentId : self.sourceConfig.documentId; }
- (NSString *)documentVersion { return (!self.sourceConfig || self.documentVersionUpdated) ? super.documentVersion : self.sourceConfig.documentVersion; }
- (NSString *)documentDescription { return (!self.sourceConfig || self.documentDescriptionUpdated) ? super.documentDescription : self.sourceConfig.documentDescription; }

// Private methods

- (BOOL)basisForProcessingUpdated { return self.gdprUpdated; }
- (BOOL)documentIdUpdated { return self.gdprUpdated; }
- (BOOL)documentVersionUpdated { return self.gdprUpdated; }
- (BOOL)documentDescriptionUpdated { return self.gdprUpdated; }

@end
