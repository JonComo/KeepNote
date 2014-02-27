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
    __weak IBOutlet UIImageView *imageViewCheck;
    __weak IBOutlet UIButton *buttonDelete;
    __weak IBOutlet UILabel *labelDate;
    
    __weak IBOutlet NSLayoutConstraint *constraintHorizontal;
}

static NSDateFormatter *formatter;

-(void)setReminder:(EKReminder *)reminder
{
    _reminder = reminder;
    
    labelDate.backgroundColor = [KNGraphics tintColor];
    
    [imageViewCheck setImage:[UIImage imageNamed:reminder.completed ? @"buttonCheckEnabled" : @"buttonCheck"]];
    
    self.title.text = reminder.title;
    
    labelDate.backgroundColor = [KNGraphics tintColor];
    labelDate.textColor = [UIColor blackColor];
    
    if (reminder.dueDateComponents)
    {
        if (!formatter)
        {
            //@"h:mm a, EEE, MMM d, yyyy";
            formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"h:mm a, EEE, MMM d, yyyy"];
        }
        
        if ([[NSDate date] compare:reminder.dueDateComponents.date] == NSOrderedDescending && !reminder.completed)
        {
            labelDate.backgroundColor = [UIColor redColor];
            labelDate.textColor = [UIColor whiteColor];
        }
        
        labelDate.alpha = 1;
        labelDate.text = [formatter stringFromDate:reminder.dueDateComponents.date];
    }else{
        labelDate.alpha = 0;
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

-(void)toggleComplete
{
    self.reminder.completed = !self.reminder.completed;
    
    NSError *error;
    [[KNRemindersManager sharedManager].store saveReminder:self.reminder commit:YES error:&error];
    
    if (error) return;
    
    [self setReminder:self.reminder];
}

@end