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

#import "SCBoundingBox.h"
#import "SCPoint.h"
#import "SCPolygon.h"

@interface SCBoundingBox ()
- (void)setBBOX:(NSArray *)points;
@end

@implementation SCBoundingBox

@synthesize lowerLeft;
@synthesize upperRight;

+ (instancetype)worldBounds {
  SCPoint *ll = [[SCPoint alloc] initWithCoordinateArray:@[ @(-180), @(-90) ]];
  SCPoint *ur = [[SCPoint alloc] initWithCoordinateArray:@[ @(180), @(90) ]];
  return [[SCBoundingBox alloc] initWithPoints:@[ ll, ur ] crs:4326];
}

- (id)initWithCoords:(NSArray *)coords {
  return [self initWithCoords:coords crs:4326];
}

/*!
 *  @brief (ll_x,ll_y,ur_x,ur_y)
 *
 *  @param coords NSArray
 *
 *  @return SCBoundingBox
 */
- (id)initWithCoords:(NSArray *)coords crs:(NSInteger)c {
  self = [super init];
  if (self) {
    self.lowerLeft = [[SCPoint alloc]
        initWithCoordinateArray:
            [coords objectsAtIndexes:[NSIndexSet
                                         indexSetWithIndexesInRange:NSMakeRange(
                                                                        0, 2)]]
                            crs:c];
    self.upperRight = [[SCPoint alloc]
        initWithCoordinateArray:
            [coords objectsAtIndexes:[NSIndexSet
                                         indexSetWithIndexesInRange:NSMakeRange(
                                                                        2, 2)]]
                            crs:c];
  }
  self.crs = c;
  return self;
}

/*!
 *  @brief Takes two SCPoints
 *
 *  @param points NSArray of two SCPoints
 *
 *  @return SCBoundingBox
 */
- (id)initWithPoints:(NSArray *)points crs:(NSInteger)c {
  self = [super init];
  if (!self) {
    return nil;
  }
  self.crs = c;
  [self setBBOX:points];
  return self;
}

- (void)setLowerLeft:(SCPoint *)ll {
  if (!lowerLeft) {
    lowerLeft = [[SCPoint alloc] initWithCoordinateArray:@[
      [NSNumber numberWithDouble:ll.x],
      [NSNumber numberWithDouble:ll.y]
    ]
                                                     crs:self.crs];
  } else {
    lowerLeft.x = ll.x;
    lowerLeft.y = ll.y;
  }
}

- (void)setUpperRight:(SCPoint *)ur {
  if (!upperRight) {
    upperRight = [[SCPoint alloc] initWithCoordinateArray:@[
      [NSNumber numberWithDouble:ur.x],
      [NSNumber numberWithDouble:ur.y]
    ]
                                                      crs:self.crs];
  } else {
    upperRight.x = ur.x;
    upperRight.y = ur.y;
  }
}

- (void)setBBOX:(NSArray *)points {
  SCPoint *firstPoint = (SCPoint *)[points firstObject];
  self.lowerLeft = [[SCPoint alloc] initWithCoordinateArray:@[
    [NSNumber numberWithDouble:firstPoint.x],
    [NSNumber numberWithDouble:firstPoint.y]
  ]
                                                        crs:self.crs];
  self.upperRight = [[SCPoint alloc] initWithCoordinateArray:@[
    [NSNumber numberWithDouble:firstPoint.x],
    [NSNumber numberWithDouble:firstPoint.y]
  ]
                                                         crs:self.crs];

  if (points.count > 1) {
    [points
        enumerateObjectsUsingBlock:^(SCPoint *p, NSUInteger idx, BOOL *stop) {

          if (p.x < self.lowerLeft.x) {
            self.lowerLeft.x = p.x;
          } else if (p.x > self.upperRight.x) {
            self.upperRight.x = p.x;
          }

          if (p.y > self.upperRight.y) {
            self.upperRight.y = p.y;
          } else if (p.y < self.lowerLeft.y) {
            self.lowerLeft.y = p.y;
          }

        }];
  }
}

- (void)addPoint:(SCPoint *)pt {
  if (self.lowerLeft == nil && self.upperRight == nil) {
    self.lowerLeft = pt;
    self.upperRight = pt;
    return;
  }

  if (pt.x < self.lowerLeft.x) {
    self.lowerLeft.x = pt.x;
  } else if (pt.x > self.upperRight.x) {
    self.upperRight.x = pt.x;
  }

  if (pt.y > self.upperRight.y) {
    self.upperRight.y = pt.y;
  } else if (pt.y < self.lowerLeft.y) {
    self.lowerLeft.y = pt.y;
  }
}

- (void)addPoints:(NSArray *)pts {
  [pts enumerateObjectsUsingBlock:^(SCPoint *p, NSUInteger idx, BOOL *stop) {
    [self addPoint:p];
  }];
}

- (BOOL)pointWithin:(SCPoint *)pt {
  if (pt.y <= self.upperRight.y && pt.y >= self.lowerLeft.y &&
      pt.x <= self.upperRight.x && pt.x >= self.lowerLeft.x) {
    return YES;
  }
  return NO;
}

- (BOOL)geometryWithin:(SCGeometry *)g {
  return [g isContained:self];
}

- (BOOL)bboxOverlaps:(SCBoundingBox *)obbox {
  return ([self pointWithin:obbox.lowerLeft] &&
          [self pointWithin:obbox.upperRight]);
}

#pragma mark - NSObject

- (NSString *)description {
  return [NSString stringWithFormat:@"UpperRight:%f,%f LowerLeft:%f,%f",
                                    self.upperRight.x, self.upperRight.y,
                                    self.lowerLeft.x, self.lowerLeft.y];
}

- (SCPoint *)centroid {
  double x = upperRight.x + lowerLeft.x;
  double y = upperRight.y + lowerLeft.y;
  return [[SCPoint alloc] initWithCoordinateArray:@[ @(x / 2.0f), @(y / 2.0f) ]
                                              crs:self.crs];
}

- (SCPolygon *)polygon {
  SCPolygon *p = [[SCPolygon alloc] initWithCoordinateArray:@[
    @[
      @[ @(upperRight.x), @(lowerLeft.y) ],
      @[ @(upperRight.x), @(upperRight.y) ],
      @[ @(lowerLeft.x), @(upperRight.y) ],
      @[ @(lowerLeft.x), @(lowerLeft.y) ],
      @[ @(upperRight.x), @(lowerLeft.y) ]
    ]
  ]
                                                        crs:self.crs];
  return p;
}
- (NSDictionary *)JSONDict {
  return [[self polygon] JSONDict];
}

@end
