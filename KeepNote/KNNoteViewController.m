//
//  KNNoteViewController.m
//  KeepNote
//
//  Created by Jon Como on 2/19/14.
//  Copyright (c) 2014 Jon Como. All rights reserved.
//

#import "KNNoteViewController.h"

#import "KNInterpreter.h"

#import "MBProgressHUD.h"

#import "KNTextView.h"

#import <EventKit/EventKit.h>

#define EXAMPLES @[@"Meeting in 20 min", @"Perform ritual in 20 moons", @"Dinner in 5 min", @"Kick son out in 16 years", @"Hot date on 1/12/13, hopefully", @"Start diet in 15 s", @"Make a lot of money, then give it to charity, in 6 months", @"Run marathon in 2 weeks", @"Quit job in 2 hours", @"Swim in 6 months", @"Summer again in 1 solar orbit", @"Lunch in 10", @"Enjoy life in 12 hours", @"Pulse my laser twice in 2 femtoseconds", @"Murder the king in 12.5 moments", @"Be there in 1 moment", @"Comprehend time smaller than one plank time unit, in 0.5 PTUs", @"Start a new fashion trend in 1.2 generations", @"Wonder why I use leap year as a time unit in 3 leap years", @"Watch 8 molecules sequentially fluoresce in 8 nanoseconds", @"Enjoy the olympics in 2 olympiads", @"Wish my parents goodluck in 2 lustrums", @"Buy new shoes in 1 decade", @"Plan for the future, in 2 gigaseconds", @"Plot my position, in 2 fortnights", @"Doctors on Jan 1, 2014 8 am", @"Meeting on feb 2, 9am"]

@interface KNNoteViewController () <KNInterpreterDelegate, KNTextViewDelegate>
{
    __weak IBOutlet KNTextView *textViewNote;
    KNInterpreter *interpreter;
    
    __weak IBOutlet UIImageView *imageViewLogo;
    
    NSDateFormatter *formatterTime;
    NSDateFormatter *formatterDay;
    NSDateFormatter *formatterMonthYear;
    
    __weak IBOutlet UILabel *labelTime;
    __weak IBOutlet UILabel *labelDay;
    __weak IBOutlet UILabel *labelMonthYear;
    
    EKEventStore *store;
    
    NSTimer *examplesTimer;
    BOOL wasShowingExamples;
}

@end

@implementation KNNoteViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self setupStore];
    
    labelDay.alpha = 0;
    labelTime.alpha = 0;
    labelMonthYear.alpha = 0;
    
    textViewNote.delegate = self;
    
    interpreter = [[KNInterpreter alloc] initWithDelegate:self];
    
    textViewNote.layer.cornerRadius = 6;
    
    formatterTime = [NSDateFormatter new];
    formatterDay = [NSDateFormatter new];
    formatterMonthYear = [NSDateFormatter new];
    
    //@"h:mm a, EEE, MMM d, yyyy";
    
    [formatterTime setDateFormat:@"h:mm a"];
    [formatterDay setDateFormat:@"EEEE"];
    [formatterMonthYear setDateFormat:@"MMM, d, yyyy"];
    
    [self startExamples];
}

-(void)startExamples
{
    [self showExample];
    
    examplesTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(showExample) userInfo:nil repeats:YES];
    wasShowingExamples = YES;
}

-(void)stopExamples
{
    [examplesTimer invalidate];
    examplesTimer = nil;
    
    wasShowingExamples = NO;
    
    textViewNote.text = @"";
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [textViewNote becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

-(void)setupStore
{
    store = [EKEventStore new];
    
    [store requestAccessToEntityType:EKEntityTypeReminder completion:^(BOOL granted, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"Error with request: %@", error);
                [self showMessage:@"Error getting reminder access"];
            }
        });
    }];
}

-(void)textViewDidDelete:(KNTextView *)textView
{
    if (wasShowingExamples){
        [self stopExamples];
        [interpreter interpretString:@""];
    }
}

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSString *fullString = [textViewNote.text stringByReplacingCharactersInRange:range withString:text];
    
    [interpreter interpretString:fullString];
    
    if ([text isEqualToString:@"\n"]){
        [self saveReminder];
        return NO;
    }
    
    return YES;
}

-(void)interpreter:(KNInterpreter *)interpreter foundDate:(NSDate *)date formattedString:(NSString *)formattedString
{
    labelDay.alpha = 1;
    labelTime.alpha = 1;
    labelMonthYear.alpha = 1;
    
    labelTime.text = [formatterTime stringFromDate:date];
    labelDay.text = [formatterDay stringFromDate:date];
    labelMonthYear.text = [formatterMonthYear stringFromDate:date];
}

-(void)interpreterFailedToFindDate:(KNInterpreter *)interpreter
{
    labelDay.alpha = 0;
    labelTime.alpha = 0;
    labelMonthYear.alpha = 0;
}

-(void)interpreterLookingForDate:(KNInterpreter *)interpreter
{
    
}

-(void)saveReminder
{
    if (textViewNote.text.length == 0) return;
    
    [interpreter interpretString:textViewNote.text]; //Interpret once again to get the latest date
    
    EKReminder *reminder = [EKReminder reminderWithEventStore:store];
    
    NSString *successString = @"Saved";
    
    //If date found add one, otherwise add no due date
    if (interpreter.date) {
        successString = @"Scheduled";
        
        NSDate *oneSecondLater = [NSDate dateWithTimeInterval:1 sinceDate:interpreter.date]; //Add one second on to each to deal with nanoseconds etc.!
        EKAlarm *alarm = [EKAlarm alarmWithAbsoluteDate:oneSecondLater];
        [reminder addAlarm:alarm];
    }
    
    [reminder setTitle:textViewNote.text];
    [reminder setCalendar:[store defaultCalendarForNewReminders]];
    
    NSError *reminderError;
    [store saveReminder:reminder commit:YES error:&reminderError];
    
    if (reminderError){
        NSLog(@"Error: %@", reminderError);
        [self showMessage:@"Note failed to save"];
    }else{
        //Note saved successfully, show it!
        [self showMessage:[NSString stringWithFormat:@"Note %@ \u2713", successString]];
        textViewNote.text = @"";
        
        labelDay.alpha = 0;
        labelTime.alpha = 0;
        labelMonthYear.alpha = 0;
    }
}

-(void)showExample
{
    NSString *task = (NSString *)[EXAMPLES objectAtIndex:arc4random()%(EXAMPLES.count-1)];
    
    while ([textViewNote.text isEqualToString:task]) {
        task = (NSString *)[EXAMPLES objectAtIndex:arc4random()%(EXAMPLES.count-1)];
    }
    
    textViewNote.text = task;
    [interpreter interpretString:textViewNote.text];
}

-(void)showMessage:(NSString *)message
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:textViewNote animated:YES];
    
    hud.mode = MBProgressHUDModeText;
    hud.labelText = message;
    
    [hud hide:YES afterDelay:1];
}

@end
