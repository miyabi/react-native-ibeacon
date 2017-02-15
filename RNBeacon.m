//
//  RNBeacon.m
//  RNBeacon
//
//  Created by Johannes Stein on 20.04.15.
//  Copyright (c) 2015 Geniux Consulting. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

#import "RCTBridge.h"
#import "RCTConvert.h"
#import "RCTEventDispatcher.h"

#import "RNBeacon.h"

@interface RNBeacon() <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (assign, nonatomic) BOOL dropEmptyRanges;

@end

@implementation RNBeacon

RCT_EXPORT_MODULE()

@synthesize bridge = _bridge;

#pragma mark Initialization

- (instancetype)init
{
    if (self = [super init]) {
        self.locationManager = [[CLLocationManager alloc] init];
        
        self.locationManager.delegate = self;
        self.locationManager.pausesLocationUpdatesAutomatically = NO;
        self.dropEmptyRanges = NO;
    }
    
    return self;
}

#pragma mark

- (CLBeaconRegion *) createBeaconRegion: (NSString *) identifier uuid: (NSString *) uuid major: (NSInteger) major minor:(NSInteger) minor
{
    NSUUID *beaconUUID = [[NSUUID alloc] initWithUUIDString:uuid];
    
    unsigned short mj = (unsigned short) major;
    unsigned short mi = (unsigned short) minor;
    
    CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:beaconUUID major:mj minor:mi identifier:identifier];
    
    beaconRegion.notifyEntryStateOnDisplay = YES;
    
    return beaconRegion;
}

- (CLBeaconRegion *) createBeaconRegion: (NSString *) identifier uuid: (NSString *) uuid major: (NSInteger) major
{
    NSUUID *beaconUUID = [[NSUUID alloc] initWithUUIDString:uuid];
    
    unsigned short mj = (unsigned short) major;
    
    CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:beaconUUID major:mj identifier:identifier];
    
    beaconRegion.notifyEntryStateOnDisplay = YES;
    
    return beaconRegion;
}

- (CLBeaconRegion *) createBeaconRegion: (NSString *) identifier uuid: (NSString *) uuid
{
    NSUUID *beaconUUID = [[NSUUID alloc] initWithUUIDString:uuid];
    
    CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:beaconUUID identifier:identifier];
    
    beaconRegion.notifyEntryStateOnDisplay = YES;
    
    return beaconRegion;
}

- (CLBeaconRegion *) convertDictToBeaconRegion: (NSDictionary *) dict
{
    if (dict[@"minor"] == nil) {
        if (dict[@"major"] == nil) {
            return [self createBeaconRegion:[RCTConvert NSString:dict[@"identifier"]] uuid:[RCTConvert NSString:dict[@"uuid"]]];
        } else {
            return [self createBeaconRegion:[RCTConvert NSString:dict[@"identifier"]] uuid:[RCTConvert NSString:dict[@"uuid"]] major:[RCTConvert NSInteger:dict[@"major"]]];
        }
    } else {
        return [self createBeaconRegion:[RCTConvert NSString:dict[@"identifier"]] uuid:[RCTConvert NSString:dict[@"uuid"]] major:[RCTConvert NSInteger:dict[@"major"]] minor:[RCTConvert NSInteger:dict[@"minor"]]];
    }
}

- (NSString *)stringForProximity:(CLProximity)proximity {
    switch (proximity) {
        case CLProximityUnknown:    return @"unknown";
        case CLProximityFar:        return @"far";
        case CLProximityNear:       return @"near";
        case CLProximityImmediate:  return @"immediate";
        default:
            return @"";
    }
}

RCT_EXPORT_METHOD(requestAlwaysAuthorization)
{
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [self.locationManager requestAlwaysAuthorization];
    }
}

RCT_EXPORT_METHOD(requestWhenInUseAuthorization)
{
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
}

RCT_EXPORT_METHOD(requestStateForRegion:(NSDictionary *)dict) {
    if ([self.locationManager respondsToSelector:@selector(requestStateForRegion:)]) {
        [self.locationManager requestStateForRegion:[self convertDictToBeaconRegion:dict]];
    }
}

RCT_EXPORT_METHOD(getAuthorizationStatus:(RCTResponseSenderBlock)callback)
{
    callback(@[[self nameForAuthorizationStatus:[CLLocationManager authorizationStatus]]]);
}

RCT_EXPORT_METHOD(startMonitoringForRegion:(NSDictionary *) dict)
{
    [self.locationManager startMonitoringForRegion:[self convertDictToBeaconRegion:dict]];
}

RCT_EXPORT_METHOD(startRangingBeaconsInRegion:(NSDictionary *) dict)
{
    [self.locationManager startRangingBeaconsInRegion:[self convertDictToBeaconRegion:dict]];
}

RCT_EXPORT_METHOD(stopMonitoringForRegion:(NSDictionary *) dict)
{
    [self.locationManager stopMonitoringForRegion:[self convertDictToBeaconRegion:dict]];
}

RCT_EXPORT_METHOD(stopRangingBeaconsInRegion:(NSDictionary *) dict)
{
    [self.locationManager stopRangingBeaconsInRegion:[self convertDictToBeaconRegion:dict]];
}

RCT_EXPORT_METHOD(startUpdatingLocation)
{
    [self.locationManager startUpdatingLocation];
}

RCT_EXPORT_METHOD(stopUpdatingLocation)
{
    [self.locationManager stopUpdatingLocation];
}

RCT_EXPORT_METHOD(shouldDropEmptyRanges:(BOOL)drop)
{
    self.dropEmptyRanges = drop;
}

-(NSString *)nameForAuthorizationStatus:(CLAuthorizationStatus)authorizationStatus
{
    switch (authorizationStatus) {
        case kCLAuthorizationStatusAuthorizedAlways:
            return @"authorizedAlways";

        case kCLAuthorizationStatusAuthorizedWhenInUse:
            return @"authorizedWhenInUse";

        case kCLAuthorizationStatusDenied:
            return @"denied";

        case kCLAuthorizationStatusNotDetermined:
            return @"notDetermined";

        case kCLAuthorizationStatusRestricted:
            return @"restricted";
    }
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSString *statusName = [self nameForAuthorizationStatus:status];
    [self.bridge.eventDispatcher sendDeviceEventWithName:@"authorizationStatusDidChange" body:statusName];
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{    
    NSLog(@"Failed ranging region: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    NSLog(@"Failed monitoring region: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Location manager failed: %@", error);
}

-(void) locationManager:(CLLocationManager *)manager didRangeBeacons:
(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    if (self.dropEmptyRanges && beacons.count == 0) {
        return;
    }
    NSMutableArray *beaconArray = [[NSMutableArray alloc] init];
    
    for (CLBeacon *beacon in beacons) {
        [beaconArray addObject:@{
                                 @"uuid": [beacon.proximityUUID UUIDString],
                                 @"major": beacon.major,
                                 @"minor": beacon.minor,
                                 
                                 @"rssi": [NSNumber numberWithLong:beacon.rssi],
                                 @"proximity": [self stringForProximity: beacon.proximity],
                                 @"accuracy": [NSNumber numberWithDouble: beacon.accuracy]
                                 }];
    }
    
    NSDictionary *event = @{
                            @"region": @{
                                    @"identifier": region.identifier,
                                    @"uuid": [region.proximityUUID UUIDString],
                                    },
                            @"beacons": beaconArray
                            };
    
    [self.bridge.eventDispatcher sendDeviceEventWithName:@"beaconsDidRange" body:event];
}

-(void)locationManager:(CLLocationManager *)manager
        didEnterRegion:(CLBeaconRegion *)region {
    NSDictionary *event = @{
                            @"region": region.identifier,
                            @"uuid": [region.proximityUUID UUIDString],
                            };
    
    [self.bridge.eventDispatcher sendDeviceEventWithName:@"regionDidEnter" body:event];
}

-(void)locationManager:(CLLocationManager *)manager
         didExitRegion:(CLBeaconRegion *)region {
    NSDictionary *event = @{
                            @"region": region.identifier,
                            @"uuid": [region.proximityUUID UUIDString],
                            };
    
    [self.bridge.eventDispatcher sendDeviceEventWithName:@"regionDidExit" body:event];
}

-(void)locationManager:(CLLocationManager *)manager
     didDetermineState:(CLRegionState)state
             forRegion:(nonnull CLBeaconRegion *)region {
    NSString *stateString = nil;
    switch (state) {
        case CLRegionStateInside:
            stateString = @"inside";
            break;
            
        case CLRegionStateOutside:
            stateString = @"outside";
            break;
            
        default:
            stateString = @"unknown";
            break;
    }
    
    NSDictionary *event = @{
                            @"region": region.identifier,
                            @"uuid": [region.proximityUUID UUIDString],
                            @"state": stateString,
                            };
    
    [self.bridge.eventDispatcher sendDeviceEventWithName:@"didDetermineStateForRegion" body:event];
}

@end
