//
//  DataManager.h
//  Tracklet
//
//  Copyright (c) 2014 io.nakamura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>
#import "Location.h"
#import "Visit.h"
#import "Upload.h"

@interface DataManager : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (id)sharedManager;

- (void)insertLocation:(CLLocation *)location;
- (NSArray *)locationsToUpload;
- (NSUInteger)locationsToUploadCount;
- (NSUInteger)locationsUploadedCount;
- (void)deleteLocations;
- (void)deleteUploadedLocations:(void (^)())completion;

- (void)insertVisit:(CLVisit *)visit;
- (NSArray *)visitsToUpload;
- (NSUInteger)visitsToUploadCount;
- (NSUInteger)visitsUploadedCount;
- (void)deleteVisits;
- (void)deleteUploadedVisits:(void (^)())completion;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

- (void)insertUploadForLocation:(Location *)location error:(NSError **)error;
- (void)insertUploadForVisit:(Visit *)visit error:(NSError **)error;

- (NSUInteger)uploadsCount;
- (void)deleteEntitiesByName:(NSString *)entityName predicate:(NSPredicate *)predicate;

@end