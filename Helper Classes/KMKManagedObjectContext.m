//
//  KMKManagedObjectContext.m
//  CalAdd
//
//  Created by Keith Kennedy on 22/03/2014.
//  Copyright (c) 2014 Keith Kennedy. All rights reserved.
//

#import "KMKManagedObjectContext.h"

@implementation KMKManagedObjectContext

- (NSString *)description {
    return [NSString stringWithFormat:@"Name: %@ - %@", self.contextName, [super description]];
}

#pragma mark - Memory Convience Methods
+ (instancetype)memoryContextAtDefaultStoreURLWithOptions:(NSDictionary *)options
                                          concurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType
{
    return [self memoryContextAtStoreURL:[self defaultStoreURL] options:options concurrencyType:concurrencyType];
}

+ (instancetype)memoryContextAtStoreURL:(NSURL *)storeURL
                                options:(NSDictionary *)options
                        concurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType
{
    return [self createAt:storeURL storeType:NSInMemoryStoreType options:options concurrencyType:concurrencyType];
}

+ (instancetype)createAtDefaultStoreURLWithOptions:(NSDictionary *)options
                                   concurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType
{
    return [self createAt:[self defaultStoreURL] options:options concurrencyType:concurrencyType];
}

+ (instancetype)createAt:(NSURL *)storeURL
                 options:(NSDictionary *)options
         concurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType
{
    return [self createAt:storeURL storeType:NSSQLiteStoreType options:options concurrencyType:concurrencyType];
}

+ (instancetype)createAtDefaultStoreURLWithStoreType:(NSString *)storeType
                                             options:(NSDictionary *)options
                                     concurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType
{
    return [self createAt:[self defaultStoreURL] storeType:storeType options:options concurrencyType:concurrencyType];
}

+ (instancetype)createAt:(NSURL *)storeURL
               storeType:(NSString *)storeType
                 options:(NSDictionary *)options
         concurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType
{
    NSError *error = nil;
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self loadManagedObjectModel]];
    
    storeType = (storeType) ? NSSQLiteStoreType : NSInMemoryStoreType;
    if (![persistentStoreCoordinator addPersistentStoreWithType:storeType
                                                  configuration:nil
                                                            URL:storeURL
                                                        options:options
                                                          error:&error])
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    if (!concurrencyType) {
        concurrencyType = NSMainQueueConcurrencyType;
    }
    
    KMKManagedObjectContext *context = [[self alloc] initWithConcurrencyType:concurrencyType];
    [context setPersistentStoreCoordinator:persistentStoreCoordinator];
    return context;
}

+ (instancetype)createChildContextForParentContext:(NSManagedObjectContext *)parentContext
                                   concurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType {
    if (!concurrencyType) {
        concurrencyType = NSMainQueueConcurrencyType;
    }
    KMKManagedObjectContext *context = [[self alloc] initWithConcurrencyType:concurrencyType];
    context.parentContext = parentContext;
    return context;
}

+ (BOOL)storeNeedsMigrationAtURL:(NSURL *)sourceStoreURL {
    BOOL compatible = NO;
    
    NSError *error = nil;
    
    NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:nil URL:sourceStoreURL error:&error];
    if (sourceMetadata != nil) {
        NSManagedObjectModel *destinationModel = [self loadManagedObjectModel];
        compatible = [destinationModel isConfiguration:nil compatibleWithStoreMetadata:sourceMetadata];
    } else {
        NSLog(@"Error: %@", error.userInfo.description);
    }
    
    return ! compatible;
}

+ (NSManagedObjectModel *)loadManagedObjectModel {
    return [[NSManagedObjectModel alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:[KMKManagedObjectContext modelName] withExtension:@"momd"]];
}

+ (NSString *)modelName {
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    NSString *bundleName = [NSString stringWithFormat:@"%@", [info objectForKey:@"CFBundleName"]];
    return bundleName;
}

+ (NSURL *)defaultStoreURL {
    NSString *modelName = [self modelName];
    NSString *modelFileName = [NSString stringWithFormat:@"%@.sqlite", modelName];
    return [[self applicationDocumentsDirectory] URLByAppendingPathComponent:modelFileName];
}

+ (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)saveContext {
    [self saveContextWithCompletion:nil];
}

- (void)saveContextWithCompletion:(dispatch_block_t)completion {
    NSError *error;
    NSManagedObjectContext *managedObjectContext = self;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges]) {
            if (![managedObjectContext save:&error]) {
                NSLog(@"Failed to save to data store: %@", [error localizedDescription]);
                NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
                if(detailedErrors != nil && [detailedErrors count] > 0) {
                    for(NSError* detailedError in detailedErrors) {
                        NSLog(@"  DetailedError: %@", [detailedError userInfo]);
                    }
                }
                else {
                    NSLog(@"Err: %@", [error userInfo]);
                }
                
                NSAssert(false, @"Save Error");
            }
        }
    }
    
    if (completion) {
        completion();
    }
}

- (void)saveContextAndAncestorContexts {
    [self saveContextAndAncestorContextsWithCompletion:nil];
}

- (void)saveContextAndAncestorContextsWithCompletion:(dispatch_block_t)completion {
    [self performBlockAndWait:^{
        [self saveContext];
        KMKManagedObjectContext *parentContext = (KMKManagedObjectContext *)self.parentContext;
        if (parentContext) {
            [parentContext saveContextAndAncestorContextsWithCompletion:completion];
        } else {
            if (completion) {
                completion();
            }
        }
    }];
}

#pragma mark - Notification Callback
- (void)setContextObjectsDidChangeNotificationCallback:(KMKManagedObjectContextCallback)contextObjectsDidChangeNotificationCallback {
    _contextObjectsDidChangeNotificationCallback = contextObjectsDidChangeNotificationCallback;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(managedObjectContextObjectsDidChangeNotification:)
                                                 name:NSManagedObjectContextObjectsDidChangeNotification
                                               object:self];
}

- (void)managedObjectContextObjectsDidChangeNotification:(NSNotification *)notification {
    if (self.contextObjectsDidChangeNotificationCallback) {
        self.contextObjectsDidChangeNotificationCallback(notification);
    }
}

- (void)setContextWillSaveNotificationCallback:(KMKManagedObjectContextCallback)contextWillSaveNotificationCallback {
    _contextWillSaveNotificationCallback = contextWillSaveNotificationCallback;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(managedObjectContextWillSaveNotification:)
                                                 name:NSManagedObjectContextWillSaveNotification
                                               object:self];
}

- (void)managedObjectContextWillSaveNotification:(NSNotification *)notification {
    if (self.contextWillSaveNotificationCallback) {
        self.contextWillSaveNotificationCallback(notification);
    }
}

@end
