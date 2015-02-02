//
//  DataManager.m
//  Tracklet
//
//  Copyright (c) 2014 io.nakamura. All rights reserved.
//

#import "DataManager.h"

static NSPredicate *uploadedPredicate;
static NSPredicate *notUploadedPredicate;

@implementation DataManager

+ (id)sharedManager {
    static DataManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

#pragma mark -

- (NSPredicate *)uploadedPredicate {
    if (uploadedPredicate == nil) {
        uploadedPredicate = [NSPredicate predicateWithFormat:@"upload != nil"];
    }
    return uploadedPredicate;
}

- (NSPredicate *)notUploadedPredicate {
    if (notUploadedPredicate == nil) {
        notUploadedPredicate = [NSPredicate predicateWithFormat:@"upload == nil"];
    }
    return notUploadedPredicate;
}

- (NSArray *)fetch:(NSString *)entityName predicate:(NSPredicate *)predicate sort:(NSArray *)descriptors error:(NSError **)error {
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName
                                              inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    if (predicate != nil) {
        [fetchRequest setPredicate:predicate];
    }
    
    if (descriptors != nil && [descriptors count] > 0) {
        [fetchRequest setSortDescriptors:descriptors];
    }
    
    return [self.managedObjectContext executeFetchRequest:fetchRequest error:error];
};

- (void)deleteManagedObjects:(NSArray *)objects each:(BOOL (^)(NSManagedObject *mo))each {
    for (NSManagedObject *mo in objects) {
        if (each == nil || each(mo)) {
            [self.managedObjectContext deleteObject:mo];
            [self saveContext];
        }
    }
}

- (void)deleteEntitiesByName:(NSString *)entityName predicate:(NSPredicate *)predicate {
    NSError *error;
    NSArray *entities = [self fetch:entityName
                          predicate:predicate
                               sort:nil
                              error:&error];
    if (error != nil || entities == nil) {
        NSLog(@"error! %@", error);
    } else {
        [self deleteManagedObjects:entities each:nil];
    }
}

- (void)deleteEntitiesByName:(NSString *)entityName predicate:(NSPredicate *)predicate each:(BOOL (^)(NSManagedObject *mo))each {
    NSError *error;
    NSArray *entities = [self fetch:entityName
                          predicate:predicate
                               sort:nil
                              error:&error];
    if (error != nil || entities == nil) {
        NSLog(@"error! %@", error);
    } else {
        [self deleteManagedObjects:entities each:each];
    }
}

#pragma mark - Location Management

- (void)insertLocation:(CLLocation *)location {
    Location *l = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Location class])
                                                inManagedObjectContext:self.managedObjectContext];
    
    l.longitude = @(location.coordinate.longitude);
    l.latitude = @(location.coordinate.latitude);
    l.horizontalAccuracy = @(location.horizontalAccuracy);
    l.verticalAccuracy = @(location.verticalAccuracy);
    l.speed = @(location.speed);
    l.course = @(location.course);
    l.altitude = @(location.altitude);
    l.timestamp = location.timestamp;
    
    NSLog(@"saving: %@\n", l);
    [self saveContext];
}

- (NSArray *)locationsToUpload {
    NSError *error;
    NSArray *ls = [self fetch:NSStringFromClass([Location class])
                    predicate:notUploadedPredicate
                         sort:nil
                        error:&error];
    if (error != nil) {
        NSLog(@"error! %@", error);
    }
    return ls;
}

- (NSUInteger)locationsCount:(NSPredicate *)predicate {
    NSError *error;
    NSArray *ls = [self fetch:NSStringFromClass([Location class])
                    predicate:predicate
                         sort:nil
                        error:&error];
    if (error == nil) {
        return [ls count];
    } else {
        NSLog(@"error! %@", error);
        return 0;
    }
}

- (NSUInteger)locationsToUploadCount {
    return [self locationsCount:self.notUploadedPredicate];
}

- (NSUInteger)locationsUploadedCount {
    return [self locationsCount:self.uploadedPredicate];
}

- (void)deleteLocations {
    [self deleteEntitiesByName:NSStringFromClass([Location class]) predicate:nil];
}

- (void)deleteUploadedLocations:(void (^)())completion {
    NSMutableArray *uploads = [NSMutableArray new];
    [self deleteEntitiesByName:NSStringFromClass([Location class])
                     predicate:self.uploadedPredicate
                          each:^BOOL(NSManagedObject *mo) {
                              NSManagedObject *u = [mo valueForKey:@"upload"];
                              if (u) {
                                  [uploads addObject:u];
                              }
                              return YES;
                          }];
    [self deleteManagedObjects:uploads each:nil];
    completion();
}

#pragma mark - Visit Management

- (void)insertVisit:(CLVisit *)visit {
    Visit *v = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Visit class])
                                             inManagedObjectContext:self.managedObjectContext];
    
    v.longitude = @(visit.coordinate.longitude);
    v.latitude = @(visit.coordinate.latitude);
    v.horizontalAccuracy = @(visit.horizontalAccuracy);
    v.arrivalDate = visit.arrivalDate;
    v.departureDate = visit.departureDate;
    
    NSLog(@"saving: %@\n", v);
    [self saveContext];
}

- (NSArray *)visitsToUpload {
    NSError *error;
    NSArray *vs = [self fetch:NSStringFromClass([Visit class])
                    predicate:notUploadedPredicate
                         sort:nil
                        error:&error];
    if (error != nil) {
        NSLog(@"error! %@", error);
    }
    return vs;
}

- (NSUInteger)visitsCount:(NSPredicate *)predicate {
    NSError *error;
    NSArray *vs = [self fetch:NSStringFromClass([Visit class])
                    predicate:predicate
                         sort:nil
                        error:&error];
    if (error == nil) {
        return [vs count];
    } else {
        NSLog(@"error! %@", error);
        return 0;
    }
}

- (NSUInteger)visitsToUploadCount {
    return [self visitsCount:self.notUploadedPredicate];
}

- (NSUInteger)visitsUploadedCount {
    return [self visitsCount:self.uploadedPredicate];
}

- (void)deleteVisits {
    [self deleteEntitiesByName:NSStringFromClass([Visit class]) predicate:nil];
}

- (void)deleteUploadedVisits:(void (^)())completion {
    [self deleteEntitiesByName:NSStringFromClass([Visit class]) predicate:self.uploadedPredicate];
    completion();
}

#pragma mark - Upload Management

- (void)insertUploadForLocation:(Location *)location error:(NSError **)error {
    Upload *u = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Upload class])
                                              inManagedObjectContext:self.managedObjectContext];
    
    u.date = [NSDate date];
    u.location = location;
    
    NSLog(@"saving: %@\n", u);
    [self saveContext];
}

- (void)insertUploadForVisit:(Visit *)visit error:(NSError **)error {
    Upload *u = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Upload class])
                                              inManagedObjectContext:self.managedObjectContext];
    
    u.date = [NSDate date];
    u.visit = visit;
    
    NSLog(@"saving: %@\n", u);
    [self saveContext];
}

#pragma mark -

- (NSUInteger)uploadsCount {
    NSError *error;
    NSArray *us = [self fetch:NSStringFromClass([Upload class])
                    predicate:nil
                         sort:nil
                        error:&error];
    if (error == nil) {
        return [us count];
    } else {
        NSLog(@"error! %@", error);
        return 0;
    }
}


#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "io.nakamura.Tracklet" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Tracklet" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Tracklet.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end