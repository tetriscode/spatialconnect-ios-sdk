/**
 * Copyright 2016 Boundless http://boundlessgeo.com
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License
 */

#import "SCFormFeature.h"
#import "SCGeopackageHelper.h"
#import "SCNetworkService.h"
#import "SCPoint.h"
#import "SpatialConnectHelper.h"
#import <XCTest/XCTest.h>

@interface SCNetworkServiceTest : XCTestCase
@property SCNetworkService *net;
@property SpatialConnect *sc;
@end

@implementation SCNetworkServiceTest

@synthesize net, sc;

- (void)setUp {
  [super setUp];
  self.sc = [SpatialConnectHelper loadRemoteConfig];
  self.net = self.sc.networkService;
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each
  // test method in the class.
  [super tearDown];
  [self.sc stopAllServices];
}

- (void)testGetRequest {
  XCTestExpectation *expect = [self expectationWithDescription:@"Download"];
  [[self.net
      getRequestURLAsDict:[NSURL
                              URLWithString:@"http://localhost:8085/config/1"]]
      subscribeNext:^(NSDictionary *d) {
        XCTAssertNotNil(d);
        [expect fulfill];
      }];
  [self.sc startAllServices];
  [self waitForExpectationsWithTimeout:120.0 handler:nil];
}

- (void)testRemoteConfig {
  [self.sc startAllServices];
  NSArray *arr = [self.sc.dataService defaultStoreLayers];
  XCTAssertNotNil(arr);
}

- (void)testFormSubmission {
  XCTestExpectation *expect = [self expectationWithDescription:@"FormSubmit"];
  [self.sc startAllServices];
  NSArray *arr = [self.sc.dataService defaultStoreLayers];
  XCTAssertNotNil(arr);
  SCPoint *p = [[SCPoint alloc] initWithCoordinateArray:@[ @(22.3), @(56.2) ]];
  SCFormFeature *f = [[SCFormFeature alloc] init];
  GeopackageStore *ds = self.sc.dataService.defaultStore;
  f.layerId = @"one";
  f.storeId = ds.storeId;
  f.geometry = p;
  [f.properties setObject:@"Joe Jackson" forKey:@"Father"];
  [[ds create:f] subscribeError:^(NSError *error) {
    [expect fulfill];
  }
      completed:^{
        XCTAssert(YES);
        [expect fulfill];
      }];
  [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

@end