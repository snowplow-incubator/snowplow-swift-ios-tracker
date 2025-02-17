//
//  SPDefaultNetworkConnection.m
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

#import "SPDefaultNetworkConnection.h"
#import "SPTrackerConstants.h"
#import "SPUtilities.h"
#import "SPLogger.h"

@implementation SPDefaultNetworkConnection {
    SPHttpMethod _httpMethod;
    SPProtocol _protocol;
    NSString *_urlString;
    NSUInteger _emitThreadPoolSize;
    NSUInteger _byteLimitGet;
    NSUInteger _byteLimitPost;
    NSString *_customPostPath;
    NSDictionary<NSString *, NSString *> *_requestHeaders;
    BOOL _serverAnonymisation;

    NSOperationQueue *_dataOperationQueue;
    NSURL *_urlEndpoint;
    BOOL _builderFinished;
}

+ (instancetype)build:(void(^)(id<SPDefaultNetworkConnectionBuilder>builder))buildBlock {
    SPDefaultNetworkConnection* connection = [[SPDefaultNetworkConnection alloc] initWithDefaultValues];
    if (buildBlock) {
        buildBlock(connection);
    }
    [connection setup];
    return connection;
}

- (instancetype)initWithDefaultValues {
    if (self = [super init]) {
        _httpMethod = SPHttpMethodPost;
        _protocol = SPProtocolHttps;
        _emitThreadPoolSize = 15;
        _byteLimitGet = 40000;
        _byteLimitPost = 40000;
        _customPostPath = nil;
        _requestHeaders = nil;
        _dataOperationQueue = [[NSOperationQueue alloc] init];
        _builderFinished = NO;
        _serverAnonymisation = NO;
    }
    return self;
}

- (void) setup {
    // Decode url to extract protocol
    NSURL *url = [[NSURL alloc] initWithString:_urlString];
    NSString *endpoint = _urlString;
    if ([url.scheme isEqualToString:@"https"]) {
        _protocol = SPProtocolHttps;
    } else if ([url.scheme isEqualToString:@"http"]) {
        _protocol = SPProtocolHttp;
    } else {
        _protocol = SPProtocolHttps;
        endpoint = [NSString stringWithFormat:@"https://%@", _urlString];
    }
    
    // Configure
    NSString *urlPrefix = _protocol == SPProtocolHttp ? @"http://" : @"https://";
    NSString *urlSuffix = _httpMethod == SPHttpMethodGet ? kSPEndpointGet : kSPEndpointPost;
    if (_customPostPath && _httpMethod == SPHttpMethodPost) {
        urlSuffix = _customPostPath;
    }

    // Remove trailing slashes from endpoint to avoid double slashes when appending path
    endpoint = [endpoint stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];

    _urlEndpoint = [[NSURL URLWithString:endpoint] URLByAppendingPathComponent:urlSuffix];
    
    // Log
    if ([_urlEndpoint scheme] && [_urlEndpoint host]) {
        SPLogDebug(@"Emitter URL created successfully '%@'", _urlEndpoint);
    } else {
        SPLogDebug(@"Invalid emitter URL: '%@'", _urlEndpoint);
    }
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:endpoint forKey:kSPErrorTrackerUrl];
    [userDefaults setObject:urlSuffix forKey:kSPErrorTrackerProtocol];
    [userDefaults setObject:urlPrefix forKey:kSPErrorTrackerMethod];
    
    _builderFinished = YES;
}

// Required

- (void)setUrlEndpoint:(NSString *)urlEndpoint {
    _urlString = urlEndpoint;
    if (_builderFinished) {
        [self setup];
    }
}

- (void)setHttpMethod:(SPHttpMethod)method {
    _httpMethod = method;
    if (_builderFinished && _urlEndpoint != nil) {
        [self setup];
    }
}

- (void)setEmitThreadPoolSize:(NSUInteger)emitThreadPoolSize {
    _emitThreadPoolSize = emitThreadPoolSize;
    if (_dataOperationQueue.maxConcurrentOperationCount != emitThreadPoolSize) {
        _dataOperationQueue.maxConcurrentOperationCount = _emitThreadPoolSize;
    }
}

- (void)setByteLimitGet:(NSUInteger)byteLimitGet {
    _byteLimitGet = byteLimitGet;
}

- (void)setByteLimitPost:(NSUInteger)byteLimitPost {
    _byteLimitPost = byteLimitPost;
}

- (void)setCustomPostPath:(NSString *)customPath {
    _customPostPath = customPath;
}

- (void)setRequestHeaders:(NSDictionary<NSString *,NSString *> *)requestHeadersKeyValue {
    _requestHeaders = requestHeadersKeyValue;
}

- (void)setServerAnonymisation:(BOOL)serverAnonymisation {
    _serverAnonymisation = serverAnonymisation;
}

// MARK: - Implement SPNetworkConnection protocol

- (SPHttpMethod)httpMethod {
    return _httpMethod;
}

- (NSURL *)url {
    return _urlEndpoint.copy;
}

- (NSArray<SPRequestResult *> *)sendRequests:(NSArray<SPRequest *> *)requests {
    NSMutableArray<SPRequestResult *> *results = [NSMutableArray new];
    
    for (SPRequest *request in requests) {
        NSMutableURLRequest *urlRequest = _httpMethod == SPHttpMethodGet
        ? [self buildGetRequest:request]
        : [self buildPostRequest:request];

        [_dataOperationQueue addOperationWithBlock:^{
            //source: https://forums.developer.apple.com/thread/11519
            __block NSHTTPURLResponse *httpResponse = nil;
            __block NSError *connectionError = nil;
            dispatch_semaphore_t sem;
            
            sem = dispatch_semaphore_create(0);
            
            [[[NSURLSession sharedSession] dataTaskWithRequest:urlRequest
                                             completionHandler:^(NSData *data, NSURLResponse *urlResponse, NSError *error) {
                
                connectionError = error;
                httpResponse = (NSHTTPURLResponse*)urlResponse;
                dispatch_semaphore_signal(sem);
            }] resume];
            
            dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);

            SPRequestResult *result = [[SPRequestResult alloc] initWithStatusCode:[httpResponse statusCode] oversize:request.oversize storeIds:request.emitterEventIds];
            if (![result isSuccessful]) {
                SPLogError(@"Connection error: %@", connectionError);
            }

            @synchronized (results) {
                [results addObject:result];
            }
        }];
    }
    [_dataOperationQueue waitUntilAllOperationsAreFinished];
    return results;
}

// MARK: - Private methods

- (NSMutableURLRequest *)buildPostRequest:(SPRequest *)request {
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:[request.payload getAsDictionary] options:0 error:nil];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:_urlEndpoint.absoluteString]];
    [urlRequest setValue:[NSString stringWithFormat:@"%@", @(requestData.length).stringValue] forHTTPHeaderField:@"Content-Length"];
    [urlRequest setValue:kSPAcceptContentHeader forHTTPHeaderField:@"Accept"];
    [urlRequest setValue:kSPContentTypeHeader forHTTPHeaderField:@"Content-Type"];
    if (_serverAnonymisation) {
        [urlRequest setValue:@"*" forHTTPHeaderField:@"SP-Anonymous"];
    }
    [self applyValuesAndHeaderFields:_requestHeaders toRequest:urlRequest];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setHTTPBody:requestData];
    return urlRequest;
}

- (NSMutableURLRequest *)buildGetRequest:(SPRequest *)request {
    NSDictionary<NSString *, NSObject *> *payload = [request.payload getAsDictionary];
    NSString *url = [NSString stringWithFormat:@"%@?%@", _urlEndpoint.absoluteString, [SPUtilities urlEncodeDictionary:payload]];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [urlRequest setValue:kSPAcceptContentHeader forHTTPHeaderField:@"Accept"];
    if (_serverAnonymisation) {
        [urlRequest setValue:@"*" forHTTPHeaderField:@"SP-Anonymous"];
    }
    [self applyValuesAndHeaderFields:_requestHeaders toRequest:urlRequest];
    [urlRequest setHTTPMethod:@"GET"];
    return urlRequest;
}

- (void)applyValuesAndHeaderFields:(NSDictionary<NSString *, NSString *> *)requestHeaders toRequest:(NSMutableURLRequest *)request {
    [requestHeaders enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        [request setValue:obj forHTTPHeaderField:key];
    }];
}

@end
