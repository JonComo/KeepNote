//
//  KNReminderCell.m
//  KeepNote
//
//  Created by Jon Como on 2/21/14.
//  Copyright (c) 2014 Jon Como. All rights reserved.
//

#import "KNReminderCell.h"

#import "KNRemindersManager.h"
#import <EventKit/EventKit.h>

#import "KNGraphics.h"

@implementation KNReminderCell
{
    __weak IBOutlet UILabel *reminderTitle;
    __weak IBOutlet UIButton *buttonCheckMark;
    __weak IBOutlet UIButton *buttonDelete;
    __weak IBOutlet UILabel *labelDate;
    
    __weak IBOutlet NSLayoutConstraint *constraintHorizontal;
}

static NSDateFormatter *formatter;

-(void)setReminder:(EKReminder *)reminder
{
    _reminder = reminder;
    
    [buttonCheckMark setImage:[UIImage imageNamed:reminder.completed ? @"buttonCheckEnabled" : @"buttonCheck"] forState:UIControlStateNormal];
    
    if (buttonCheckMark.allTargets.count == 0)
        [buttonCheckMark addTarget:self action:@selector(checkHit) forControlEvents:UIControlEventTouchUpInside];
    
    reminderTitle.text = reminder.title;
    
    if (reminder.dueDateComponents)
    {
        if (!formatter)
        {
            //@"h:mm a, EEE, MMM d, yyyy";
            formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"h:mm a, EEE, MMM d, yyyy"];
        }
        
        labelDate.text = [formatter stringFromDate:reminder.dueDateComponents.date];
        labelDate.backgroundColor = [KNGraphics tintColor];
        labelDate.alpha = 1;
    }else{
        labelDate.backgroundColor = [UIColor whiteColor];
        labelDate.alpha = 0.4;
        if (reminder.creationDate)
            labelDate.text = [formatter stringFromDate:reminder.creationDate];
    }
}

- (IBAction)deleteReminder:(id)sender
{
    //remove from datasource
    NSError *error = [[KNRemindersManager sharedManager] deleteReminder:self.reminder];
    
    //remove this cell
    if (!error)
        [[NSNotificationCenter defaultCenter] postNotificationName:KNReminderDeletedNotification object:self.reminder userInfo:nil];
}

-(void)setIsEditMode:(BOOL)isEditMode
{
    _isEditMode = isEditMode;
    
    //animate constraints
    constraintHorizontal.constant = isEditMode ? 0 : -60;
    [self layoutSubviews];
}

-(void)checkHit
{
    self.reminder.completed = !self.reminder.completed;
    
    NSError *error;
    [[KNRemindersManager sharedManager].store saveReminder:self.reminder commit:YES error:&error];
    
    if (error) return;
    
    [buttonCheckMark setImage:[UIImage imageNamed:self.reminder.completed ? @"buttonCheckEnabled" : @"buttonCheck"] forState:UIControlStateNormal];
}

@end