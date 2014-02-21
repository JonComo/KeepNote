//
//  KNRemindersManager.h
//  KeepNote
//
//  Created by Jon Como on 2/21/14.
//  Copyright (c) 2014 Jon Como. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EKEventStore;

@interface KNRemindersManager : NSObject

@property (nonatomic, strong) EKEventStore *store;
@property (nonatomic, strong) NSMutableArray *reminders;

-(void)requestAccessToStoreCompletion:(void(^)(BOOL granted))block;
+(KNRemindersManager *)sharedManager;
-(void)fetchAllReminders:(void(^)(NSArray *reminders))block;

@end
