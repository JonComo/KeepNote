//
//  KNReminderCell.m
//  KeepNote
//
//  Created by Jon Como on 2/21/14.
//  Copyright (c) 2014 Jon Como. All rights reserved.
//

#import "KNReminderCell.h"

#import <EventKit/EventKit.h>

@implementation KNReminderCell
{
    __weak IBOutlet UILabel *reminderTitle;
    __weak IBOutlet UIButton *buttonCheckMark;
    __weak IBOutlet UILabel *labelDate;
}

static NSDateFormatter *formatter;

-(void)setReminder:(EKReminder *)reminder
{
    _reminder = reminder;
    
    buttonCheckMark.layer.borderColor = [UIColor blackColor].CGColor;
    buttonCheckMark.layer.borderWidth = 2;
    
    buttonCheckMark.backgroundColor = reminder.completed ? [UIColor blackColor] : [UIColor whiteColor];
    
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
        labelDate.alpha = 1;
    }else{
        labelDate.alpha = 0;
    }
}

-(void)checkHit
{
    self.reminder.completed = !self.reminder.completed;
    
    buttonCheckMark.backgroundColor = self.reminder.completed ? [UIColor blackColor] : [UIColor whiteColor];
}

@end
