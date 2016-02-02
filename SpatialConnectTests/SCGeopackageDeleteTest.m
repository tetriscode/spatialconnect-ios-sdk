/*****************************************************************************
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 ******************************************************************************/

#import "GeopackageStore.h"
#import "SCGeopackageHelper.h"
#import "SpatialConnect.h"
#import "SpatialConnectHelper.h"
#import <XCTest/XCTest.h>

@interface SCGeopackageDeleteTest : XCTestCase
@property(nonatomic) SpatialConnect *sc;
@end

@implementation SCGeopackageDeleteTest

@synthesize sc;

- (void)setUp {
  [super setUp];
  self.sc = [SpatialConnectHelper loadConfigAndStartServices];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testGpkgFeatureDelete {
  XCTestExpectation *expect = [self expectationWithDescription:@"Delete"];
  SCQueryFilter *filter = [[SCQueryFilter alloc] init];
  filter.limit = 1;
  [[SCGeopackageHelper loadGPKGDataStore:self.sc]
      subscribeNext:^(id<SCSpatialStore> ds) {
        [[[ds query:filter] flattenMap:^RACStream *(SCSpatialFeature *f) {
          return [ds delete:f.key];
        }] subscribeError:^(NSError *error) {
          XCTFail(@"Error Deleting Feature");
          [expect fulfill];
        }
            completed:^{
              [expect fulfill];
            }];

      }
      error:^(NSError *error) {
        XCTFail(@"Error getting store");
        [expect fulfill];
      }];

  [self.sc startAllServices];
  [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

@end
