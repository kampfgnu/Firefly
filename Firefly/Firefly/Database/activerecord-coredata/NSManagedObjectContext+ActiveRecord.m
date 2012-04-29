//
//  NSManagedObjectContext+ActiveRecord.m
//
//  Created by Saul Mora on 11/23/09.
//  Copyright 2010 Magical Panda Software, LLC All rights reserved.
//

#import "NSManagedObject+ActiveRecord.h"
#import "NSManagedObjectContext+ActiveRecord.h"
#import "NSPersistentStoreCoordinator+ActiveRecord.h"
#import <objc/runtime.h>

static NSManagedObjectContext *defaultManageObjectContext = nil;

@implementation NSManagedObjectContext (ActiveRecord)

+ (NSManagedObjectContext *)defaultContext
{
  //NSAssert([NSThread isMainThread], @"The defaultContext must only be accessed on the **Main Thread**");
  @synchronized (self)
  {
    if (defaultManageObjectContext)
    {
      return defaultManageObjectContext;
    }
  }
  return nil;
}

+ (void) setDefaultContext:(NSManagedObjectContext *)moc
{
  defaultManageObjectContext = moc;
}

+ (void) resetDefaultContext
{
  dispatch_sync(dispatch_get_main_queue(), ^{
    [[NSManagedObjectContext defaultContext] reset];
  });
}

+ (NSManagedObjectContext *) contextForCurrentThread
{
  if ( [NSThread isMainThread] )
  {
    return [self defaultContext];
  }
  else
  {
    NSMutableDictionary *threadDict = [[NSThread currentThread] threadDictionary];
    NSManagedObjectContext *threadContext = [threadDict objectForKey:@"MO_Context"];
    if ( threadContext == nil )
    {
      threadContext = [self context];
      [threadDict setObject:threadContext forKey:@"MO_Context"];
    }
    return threadContext;
  }
}

+ (void) resetContextForCurrentThread
{
    [[NSManagedObjectContext contextForCurrentThread] reset];
}

- (void) observeContext:(NSManagedObjectContext *)otherContext
{
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(mergeChangesFromNotification:)
                                               name:NSManagedObjectContextDidSaveNotification
                                             object:otherContext];
}

- (void) observeContextOnMainThread:(NSManagedObjectContext *)otherContext
{
  NSLog(@"Start Observing on Main Thread");
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(mergeChangesOnMainThread:)
                                               name:NSManagedObjectContextDidSaveNotification
                                             object:otherContext];
}

- (void) stopObservingContext:(NSManagedObjectContext *)otherContext
{
  NSLog(@"Stop Observing Context");
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:NSManagedObjectContextDidSaveNotification
                                                object:otherContext];
}

- (void) mergeChangesFromNotification:(NSNotification *)notification
{
  NSLog(@"Merging changes to context%@", [NSThread isMainThread] ? @" *** on Main Thread ***" : @"");
  [self mergeChangesFromContextDidSaveNotification:notification];
}

- (void) mergeChangesOnMainThread:(NSNotification *)notification
{
  if ([NSThread isMainThread])
  {
    [self mergeChangesFromNotification:notification];
  }
  else
  {
    [self performSelectorOnMainThread:@selector(mergeChangesFromNotification:) withObject:notification waitUntilDone:YES];
  }
}

- (BOOL) save
{
  NSError *error = nil;
  BOOL saved = NO;
  @try
  {
    NSLog(@"Saving Context%@", [NSThread isMainThread] ? @" *** on Main Thread ***" : @"");
    saved = [self save:&error];
  }
  @catch (NSException *exception)
  {
    NSLog(@"Problem saving: %@", (id)[exception userInfo] ?: (id)[exception reason]);
  }

  [ActiveRecordHelpers handleErrors:error];

  return saved && error == nil;
}

- (void) saveWrapper
{

  [self save];

}

- (BOOL) saveOnBackgroundThread
{

  [self performSelectorInBackground:@selector(saveWrapper) withObject:nil];

  return YES;
}

- (BOOL) saveOnMainThread
{
  @synchronized(self)
  {
    [self performSelectorOnMainThread:@selector(saveWrapper) withObject:nil waitUntilDone:YES];
  }

  return YES;
}

- (BOOL) notifiesMainContextOnSave
{
    NSNumber *notifies = objc_getAssociatedObject(self, @"notifiesMainContext");
    return notifies ? [notifies boolValue] : NO;
}

- (void) setNotifiesMainContextOnSave:(BOOL)enabled
{
    NSManagedObjectContext *mainContext = [[self class] defaultContext];
    if (self != mainContext)
    {
        SEL selector = enabled ? @selector(observeContextOnMainThread:) : @selector(stopObservingContext:);
        objc_setAssociatedObject(self, @"notifiesMainContext", [NSNumber numberWithBool:enabled], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [mainContext performSelector:selector withObject:self];
    }
}

+ (NSManagedObjectContext *) contextWithStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator
{
	NSManagedObjectContext *context = nil;
    if (coordinator != nil)
	{
        NSLog(@"Creating MOContext %@", [NSThread isMainThread] ? @" *** On Main Thread ***" : @"");
        context = [[NSManagedObjectContext alloc] init];
        [context setPersistentStoreCoordinator:coordinator];
    }
    return context;
}

+ (NSManagedObjectContext *) contextThatNotifiesDefaultContextOnMainThreadWithCoordinator:(NSPersistentStoreCoordinator *)coordinator;
{
    NSManagedObjectContext *context = [self contextWithStoreCoordinator:coordinator];
    //    [[self defaultContext] observeContext:context];
    context.notifiesMainContextOnSave = YES;
    return context;
}

+ (NSManagedObjectContext *) context
{
	return [self contextWithStoreCoordinator:[NSPersistentStoreCoordinator defaultStoreCoordinator]];
}

+ (NSManagedObjectContext *) contextThatNotifiesDefaultContextOnMainThread
{
    NSManagedObjectContext *context = [self context];
    context.notifiesMainContextOnSave = YES;
    return context;
}


- (void)logDetailedError:(NSError *)error from:(id)caller selector:(SEL)selector
{
#if DEBUG
  NSLog(@"*** CORE DATA ERROR: a data store operation failed");
  NSLog(@"*** Caller was: %@ %p %@", [caller class], caller, NSStringFromSelector(selector));
  NSLog(@"*** Error: %@", [error localizedDescription]);
  NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
  if ([detailedErrors count] > 0)
  {
    for(NSError* detailedError in detailedErrors)
      NSLog(@">  DetailedError: %@", [detailedError userInfo]);
  }
  else
  {
    NSLog(@"  %@", [error userInfo]);
  }
#endif
}

- (void)logContextChanges
{
#if DEBUG
  // Log the current changes for the context
  if (![self hasChanges])
    return;

  NSLog(@"***************************************************");
  NSLog(@"* CHANGES TO %@ %p", [self class], self);
  NSLog(@"***************************************************");
  NSSet *updated = [self updatedObjects];
  NSSet *inserted = [self insertedObjects];
  NSSet *deleted = [self deletedObjects];
  if ([updated count])
  {
    NSLog(@"* UPDATED OBJECTS:");
    for (NSManagedObject *anObject in [self updatedObjects])
    {
      NSLog(@"* %@ %p has the following changes:", [anObject class], anObject);
      NSDictionary *changedValues = [anObject changedValues];
      NSArray *keys = [changedValues allKeys];
      NSDictionary *oldValues = [anObject committedValuesForKeys:keys];
      for (NSString *key in keys)
        NSLog(@"  Attribute '%@' was {%@} is now {%@}", key, [oldValues objectForKey:key], [changedValues objectForKey:key]);
      NSLog(@"*");
    }
  }
  if ([inserted count])
  {
    if ([updated count])
      NSLog(@"***************************************************");
    NSLog(@"* INSERTED OBJECTS:");
    for (NSManagedObject *anObject in [self insertedObjects])
    {
      NSLog(@"* %@", anObject);
      NSLog(@"*");
    }
  }
  if ([deleted count])
  {
    if ([updated count] || [inserted count])
      NSLog(@"***************************************************");
    NSLog(@"* DELETED OBJECTS:");
    for (NSManagedObject *anObject in [self deletedObjects])
    {
      NSLog(@"* %@", anObject);
      NSLog(@"*");
    }
  }
  NSLog(@"***************************************************");
#endif
}


@end
