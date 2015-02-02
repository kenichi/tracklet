//
//  NetworkManager.m
//  Tracklet
//
//  Copyright (c) 2015 io.nakamura. All rights reserved.
//

#import "NetworkManager.h"
#import "AFNetworking.h"
#import "DataManager.h"

@interface NetworkManager ()

@property (strong, nonatomic) AFHTTPRequestOperationManager *rom;

@end

static NSString *const BaseUrl = @"http://example.com/";

@implementation NetworkManager


+ (id)sharedManager {
    static NetworkManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

- (id)init {
    if (self = [super init]) {
        
        self.baseUrl = [NSURL URLWithString:BaseUrl];
        self.rom = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:self.baseUrl];
        self.rom.requestSerializer = [AFJSONRequestSerializer serializer];
        
    }
    return self;
}

#pragma mark -

- (NSMutableDictionary *)dictForManagedObject:(NSManagedObject *)mo {
    NSArray *keys = [[[mo entity] attributesByName] allKeys];
    NSDictionary *d =[mo dictionaryWithValuesForKeys:keys];
    return [NSMutableDictionary dictionaryWithDictionary:d];
}

- (NSMutableDictionary *)prepareLocation:(Location *)location {
    NSMutableDictionary *params = [self dictForManagedObject:location];
    
    params[@"horizontal_accuracy"] = params[@"horizontalAccuracy"];
    [params removeObjectForKey:@"horizontalAccuracy"];
    
    params[@"vertical_accuracy"] = params[@"verticalAccuracy"];
    [params removeObjectForKey:@"verticalAccuracy"];
    
    params[@"timestamp"] = [params[@"timestamp"] description];
    
    return params;
}

- (NSMutableDictionary *)prepareVisit:(Visit *)visit {
    NSMutableDictionary *params = [self dictForManagedObject:visit];
    
    if (params[@"arrivalDate"] != [NSDate distantPast]) {
        params[@"arrival_date"] = [params[@"arrivalDate"] description];
    }
    [params removeObjectForKey:@"arrivalDate"];
    
    if (params[@"departureDate"] != [NSDate distantFuture]) {
        params[@"departure_date"] = [params[@"departureDate"] description];
    }
    [params removeObjectForKey:@"departureDate"];
    
    return params;
}

#pragma mark -

- (void)uploadLocation:(Location *)location {
    NSMutableDictionary *params = [self prepareLocation:location];
    [self.rom POST:@"/location" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DataManager *dm = [DataManager sharedManager];
        NSError *error;
        [dm insertUploadForLocation:location error:&error];
        if (error != nil) {
            NSLog(@"error: %@", error);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"post /location error: %@", error);
    }];
    
}

- (void)uploadLocations:(NSArray *)locations completion:(void (^)(NSError *))completion {
    NSMutableArray *ls = [NSMutableArray new];
    for (Location *l in locations) {
        [ls addObject:[self prepareLocation:l]];
    }
    [self.rom POST:@"/locations" parameters:@{@"locations": ls} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DataManager *dm = [DataManager sharedManager];
        NSError *error;
        for (Location *l in locations) {
            [dm insertUploadForLocation:l error:&error];
            if (error != nil) {
                NSLog(@"error: %@", error);
                error = nil;
            }
        }
        completion(error);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"post /locations error: %@", error);
        completion(error);
    }];
}

- (void)uploadVisit:(Visit *)visit {
    NSMutableDictionary *params = [self prepareVisit:visit];
    [self.rom POST:@"/visit" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DataManager *dm = [DataManager sharedManager];
        NSError *error;
        [dm insertUploadForVisit:visit error:&error];
        if (error != nil) {
            NSLog(@"error: %@", error);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"post /visit error: %@", error);
    }];
    
}

- (void)uploadVisits:(NSArray *)visits completion:(void (^)(NSError *))completion {
    NSMutableArray *vs = [NSMutableArray new];
    for (Visit *v in visits) {
        [vs addObject:[self prepareVisit:v]];
    }
    [self.rom POST:@"/visits" parameters:@{@"visits": vs} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DataManager *dm = [DataManager sharedManager];
        NSError *error;
        for (Visit *v in visits) {
            [dm insertUploadForVisit:v error:&error];
            if (error != nil) {
                NSLog(@"error: %@", error);
                error = nil;
            }
        }
        completion(error);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"post /visits error: %@", error);
        completion(error);
    }];
}

@end
