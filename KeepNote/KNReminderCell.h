//
//  KNReminderCell.h
//  KeepNote
//
//  Created by Jon Como on 2/21/14.
//  Copyright (c) 2014 Jon Como. All rights reserved.
//

#import <UIKit/UIKit.h>

#define KNReminderDeletedNotification @"reminderDeleted"

@class EKReminder;

@interface KNReminderCell : UICollectionViewCell

@property (nonatomic, assign) BOOL isEditMode;
@property (nonatomic, weak) EKReminder *reminder;

@end