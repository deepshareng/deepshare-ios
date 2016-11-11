//
//  MockTests.m
//  DeepShareSample
//
//  Created by Hibbert on 15/10/8.
//  Copyright © 2015年 johney.song. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "DeepShare.h"
#import "DeepShareImpl.h"

typedef void (^UrlConnectionCallback)(NSURLResponse *, NSData *, NSError *);

@interface NewvaluewithoutInitTests : XCTestCase
@property (nonatomic) BOOL is_Running;
@property (nonatomic) int result;
@property (nonatomic) id urlConnectionMock;
@end

@implementation NewvaluewithoutInitTests

- (void)onInappDataReturned: (NSDictionary *) params withError: (NSError *) error {
    if (!error) {
        NSLog(@"finished init with params = %@", [params description]);
    } else {
        NSString *errorString = [[error userInfo] objectForKey:NSLocalizedDescriptionKey];
        NSLog(@"init error id: %ld %@",error.code, errorString);
    }
}

- (void)tearDown {
    [super tearDown];
}

- (void)testChangeValue {
    [DeepShareImpl getcurrInstance].isInit = false;
    self.urlConnectionMock = OCMClassMock([NSURLConnection class]);
    [self expectChangeValueErrorRequest:self.urlConnectionMock times:2];
    self.is_Running = true;
    NSDictionary *tagTovalue = [[NSDictionary alloc] initWithObjects:@[@1] forKeys:@[@"abc"]];
    [DeepShare attribute:tagTovalue completion:^(NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertEqual(error.code, 4004);
        self.is_Running = false;
    }];
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:10];
    while (self.is_Running == true && [loopUntil timeIntervalSinceNow] > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }
    XCTAssertEqual(self.is_Running, false);
}

- (void)expectChangeValueErrorRequest:(id)connectionMock times:(NSInteger) times {
    __block UrlConnectionCallback urlConnectionCallback;
    
    id urlConnectionBlock = [OCMArg checkWithBlock:^BOOL(UrlConnectionCallback callback) {
        urlConnectionCallback = callback;
        return YES;
    }];
    
    void (^urlConnectionInvocation)(NSInvocation *) = ^(NSInvocation *invocation) {
        NSDictionary *userInfo = [[NSDictionary alloc] initWithObjects:@[@"http://deepshare.chinacloudapp.cn:8080/v1/open", @"http://deepshare.chinacloudapp.cn:8080/v1/open", @"The Internet connection appears to be offline.", @"Error Domain=kCFErrorDomainCFNetwork Code=-1009 \"(null)\" UserInfo={_kCFStreamErrorCodeKey=8, _kCFStreamErrorDomainKey=12}", @8, @12] forKeys:@[@"NSErrorFailingURLKey", @"NSErrorFailingURLStringKey", @"NSLocalizedDescription", @"NSUnderlyingError", @"\"_kCFStreamErrorCodeKey\"", @"\"_kCFStreamErrorDomainKey\""]];
        NSError *error = [NSError errorWithDomain:@"NSURLErrorDomain" code:-1001 userInfo:userInfo];
        urlConnectionCallback(nil, nil, error);
    };
    
    for (NSInteger i = 0; i < times; i++) {
        [[[connectionMock expect] andDo:urlConnectionInvocation] sendAsynchronousRequest:[OCMArg checkWithBlock:^BOOL(NSURLRequest *request) {
            return [[request.URL absoluteString] rangeOfString:@"counters"].location != NSNotFound;
        }] queue:[OCMArg any] completionHandler:urlConnectionBlock];
    }
}

@end
