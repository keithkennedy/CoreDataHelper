//
//  KMKManagedObject.m
//  Created by Keith Kennedy.
//
//

#import "KMKManagedObject.h"

#import "KMKManagedObjectContext.h"

@implementation KMKManagedObject

+ (NSString *)entityName {
    return NSStringFromClass(self);
}

+ (instancetype)newObjectInManagedObjectContext:(KMKManagedObjectContext *)context {
    return [NSEntityDescription insertNewObjectForEntityForName:[self entityName] inManagedObjectContext:context];
}

+ (NSFetchRequest *)fetchRequest {
    return [[NSFetchRequest alloc] initWithEntityName:[self entityName]];
}

+ (NSArray *)allInstancesWithPredicate:(NSPredicate *)predicate
                inManagedObjectContext:(KMKManagedObjectContext *)context {
    NSFetchRequest *fetchRequest = [self fetchRequest];
    fetchRequest.predicate = predicate;

    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
    if (results == nil) {
        NSLog(@"ERROR loading %@: %@", predicate, error.userInfo.description);
    }
    
    return results;
}

+ (NSArray *)allInstancesInManagedObjectContext:(KMKManagedObjectContext *)context {
    return [self allInstancesWithPredicate:nil inManagedObjectContext:context];
}

#pragma mark - Order
+ (NSArray *)allInstancesOrdered:(KMKManagedObjectContext *)context {
    NSError *error = nil;
    NSArray *allInstancesOrdered = [context executeFetchRequest:[self orderFetchRequest] error:&error];
    return allInstancesOrdered;
}

+ (NSFetchRequest *)orderFetchRequest {
    NSFetchRequest *fr = [self fetchRequest];
    fr.sortDescriptors = @[[self orderSortDescriptor]];
    return fr;
}
    
+ (NSSortDescriptor *)orderSortDescriptor {
    return [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
}

+ (void)deleteAllInstances:(NSPredicate *)predicate inContext:(KMKManagedObjectContext *)context {
    NSFetchRequest *r = [self fetchRequest];
    if (predicate) {
        [r setPredicate:predicate];
    }
    NSArray *results = [context executeFetchRequest:r error:nil];
    for (KMKManagedObject *s in results) {
        [context deleteObject:s];
    }
}

@end
