//
//  KNRemindersManager.h
//  KeepNote
//
//  Created by Jon Como on 2/21/14.
//  Copyright (c) 2014 Jon Como. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    KNFilterNotes,
    KNFilterUncomplete
} KNFilter;

@class EKEventStore;

@interface KNRemindersManager : NSObject

@property (nonatomic, strong) EKEventStore *store;

@property (nonatomic, strong) NSMutableArray *reminders;
@property (nonatomic, strong) NSMutableArray *filtered;

@property (nonatomic, assign) BOOL showUncompleteOnly;

-(void)requestAccessToStoreCompletion:(void(^)(BOOL granted))block;
+(KNRemindersManager *)sharedManager;
-(void)fetchAllReminders:(void(^)(NSArray *reminders))block;

-(void)filter:(KNFilter)filter;

@end