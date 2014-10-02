//
//  KMKManagedObjectContext.h
//  CalAdd
//
//  Created by Keith Kennedy on 22/03/2014.
//  Copyright (c) 2014 Keith Kennedy. All rights reserved.
//

#import <CoreData/CoreData.h>

typedef void(^KMKManagedObjectContextCallback)(NSNotification *);

@interface KMKManagedObjectContext : NSManagedObjectContext

@property (nonatomic, copy) KMKManagedObjectContextCallback contextObjectsDidChangeNotificationCallback;
@property (nonatomic, copy) KMKManagedObjectContextCallback contextWillSaveNotificationCallback;

@property (nonatomic, strong) NSString *contextName;

+ (instancetype)memoryContextAtDefaultStoreURLWithOptions:(NSDictionary *)options
                                          concurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType;

+ (instancetype)memoryContextAtStoreURL:(NSURL *)storeURL
                                options:(NSDictionary *)options
                        concurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType;

+ (instancetype)createAtDefaultStoreURLWithOptions:(NSDictionary *)options
                                   concurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType;

+ (instancetype)createAt:(NSURL *)storeURL
                 options:(NSDictionary *)options
         concurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType;

+ (instancetype)createAtDefaultStoreURLWithStoreType:(NSString *)storeType
                                             options:(NSDictionary *)options
                                     concurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType;

+ (instancetype)createAt:(NSURL *)storeURL
               storeType:(NSString *)storeType
                 options:(NSDictionary *)options
         concurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType;

+ (instancetype)createChildContextForParentContext:(NSManagedObjectContext *)parentContext
                                   concurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType;

+ (BOOL)storeNeedsMigrationAtURL:(NSURL *)sourceStoreURL;

+ (NSURL *)defaultStoreURL;

- (void)saveContext;
- (void)saveContextWithCompletion:(dispatch_block_t)completion;
- (void)saveContextAndAncestorContexts;
- (void)saveContextAndAncestorContextsWithCompletion:(dispatch_block_t)completion;

@end
