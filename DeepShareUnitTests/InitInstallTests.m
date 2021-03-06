//
//  InitInstallTests.m
//  DeepShareSample
//
//  Created by Hibbert on 15/10/28.
//  Copyright © 2015年 johney.song. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "DeepShare.h"
#import "DLPreferenceHelper.h"
#import "DLSystemObserver.h"

typedef void (^UrlConnectionCallback)(NSURLResponse *, NSData *, NSError *);

@interface InitInstallTests : XCTestCase
@property (nonatomic) BOOL is_Running;
@end

@implementation InitInstallTests

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)onInappDataReturned: (NSDictionary *) params withError: (NSError *) error {
    XCTAssertNil(error);
    XCTAssertEqualObjects([params valueForKey:@"key1"], @"test_value1");
    XCTAssertEqualObjects([params valueForKey:@"key2"], @2);
//    XCTAssertNotEqual([DLSystemObserver getUniqueId], NO_STRING_VALUE);
    self.is_Running = false;
}

- (void)testInit {
    self.is_Running = true;
    [DLPreferenceHelper setInstall:@"not_install"];
    id urlConnectionMock = OCMClassMock([NSURLConnection class]);
    InitInstallTests *test = [InitInstallTests alloc];
    [test expectInitSuccessfulRequest:urlConnectionMock];
    [DeepShare initWithAppID:@"init" withLaunchOptions:nil withDelegate:self];
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:10];
    while (self.is_Running == true && [loopUntil timeIntervalSinceNow] > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }
    XCTAssertEqual(self.is_Running, false);
}

- (void)expectInitSuccessfulRequest:(id)connectionMock {
    __block UrlConnectionCallback urlConnectionCallback;
    
    id urlConnectionBlock = [OCMArg checkWithBlock:^BOOL(UrlConnectionCallback callback) {
        urlConnectionCallback = callback;
        return YES;
    }];
    
    void (^urlConnectionInvocation)(NSInvocation *) = ^(NSInvocation *invocation) {
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[[NSURL alloc] init] statusCode:200 HTTPVersion:nil headerFields:@{@"Content-Length" : @"209", @"Content-Type" : @"text/plain; charset=utf-8"}];
        NSString *str = @"{ \"inapp_data\":\"{\\\"key1\\\":\\\"test_value1\\\",\\\"key2\\\":2}\" }";
        NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
        urlConnectionCallback(response, data, nil);
    };
    [[[connectionMock expect] andDo:urlConnectionInvocation] sendAsynchronousRequest:[OCMArg checkWithBlock:^BOOL(NSURLRequest *request) {
        return [[request.URL absoluteString] rangeOfString:@"inappdata"].location != NSNotFound;
    }] queue:[OCMArg any] completionHandler:urlConnectionBlock];
}

@end
