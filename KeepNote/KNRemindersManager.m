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
{
    KNFilter currentFilter;
}

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
        _showUncompleteOnly = YES;
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
        
        self.reminders = [reminders mutableCopy];
        
        //sort
        [self.reminders sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            EKReminder *reminder1 = (EKReminder *)obj1;
            EKReminder *reminder2 = (EKReminder *)obj2;
            
            return [reminder2.creationDate compare:reminder1.creationDate];
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (block) block(self.reminders);
        });
    }];
}

-(void)setShowUncompleteOnly:(BOOL)showUncompleteOnly
{
    _showUncompleteOnly = showUncompleteOnly;
    
    [self filter:currentFilter];
}

-(void)filter:(KNFilter)filter
{
    currentFilter = filter;
    
    NSMutableArray *preFiltered = [NSMutableArray array];
    
    for (EKReminder *reminder in self.reminders)
    {
        if (self.showUncompleteOnly){
            if (!reminder.completed)
                [preFiltered addObject:reminder];
        }else{
            //show all
            [preFiltered addObject:reminder];
        }
    }
    
    if (!self.filtered) self.filtered = [NSMutableArray array];
    [self.filtered removeAllObjects];
    
    if(filter == KNFilterNotes)
    {
        for (EKReminder *reminder in preFiltered){
            if (!reminder.dueDateComponents){
                [self.filtered addObject:reminder];
            }
        }
    }else if(filter == KNFilterUncomplete)
    {
        for (EKReminder *reminder in preFiltered){
            if (reminder.dueDateComponents){
                [self.filtered addObject:reminder];
            }
        }
    }
}

@end
