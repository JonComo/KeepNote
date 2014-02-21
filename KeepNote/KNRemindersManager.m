//
//  KNRemindersManager.m
//  KeepNote
//
//  Created by Jon Como on 2/21/14.
//  Copyright (c) 2014 Jon Como. All rights reserved.
//

#import "KNRemindersManager.h"

#import <EventKit/EventKit.h>

@implementation KNRemindersManager

+(KNRemindersManager *)sharedManager
{
    static KNRemindersManager *sharedManager;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    
    return sharedManager;
}

-(id)init
{
    if (self = [super init]) {
        //init
        
    }
    
    return self;
}

-(void)requestAccessToStoreCompletion:(void (^)(BOOL))block
{
    self.store = [EKEventStore new];
    
    [self.store requestAccessToEntityType:EKEntityTypeReminder completion:^(BOOL granted, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (block) block(granted);
        });
    }];
}

-(void)fetchAllReminders:(void (^)(NSArray *))block
{
    NSPredicate *predicate = [self.store predicateForRemindersInCalendars:nil];
    
    [self.store fetchRemindersMatchingPredicate:predicate completion:^(NSArray *reminders) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.reminders = [reminders mutableCopy];
            if (block) block(reminders);
        });
    }];
}

@end
