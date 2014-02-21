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
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)setReminder:(EKReminder *)reminder
{
    _reminder = reminder;
    
    reminderTitle.text = reminder.title;
    
    self.backgroundColor = [UIColor yellowColor];
    
}

@end
