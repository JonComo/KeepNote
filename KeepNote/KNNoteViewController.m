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

#import "KNRemindersManager.h"

#import <EventKit/EventKit.h>

#define EXAMPLES @[@"Meeting in 20 min", @"Perform ritual in 20 moons", @"Dinner in 5 min", @"Kick son out in 16 years", @"Hot date on 1/12/13, hopefully", @"Start diet in 15 s", @"Make a lot of money, then give it to charity, in 6 months", @"Run marathon in 2 weeks", @"Quit job in 2 hours", @"Swim in 6 months", @"Summer again in 1 solar orbit", @"Lunch in 10", @"Enjoy life in 12 hours", @"Pulse my laser twice in 2 femtoseconds", @"Murder the king in 12.5 moments", @"Be there in 1 moment", @"Learn about plank time units, in 0.5 PTUs", @"Start a new fashion trend in 1.2 generations", @"Enjoy the olympics in 2 olympiads", @"Wish my parents goodluck in 2 lustrums", @"Buy new shoes in 1 decade", @"Plan for the future, in 2 gigaseconds", @"Plot my position, in 2 fortnights", @"Doctors on Jan 1, 2014 8 am", @"Meeting on feb 2, 9am"]

@interface KNNoteViewController () <KNInterpreterDelegate, KNTextViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
{
    KNRemindersManager *manager;
    
    __weak IBOutlet KNTextView *textViewNote;
    KNInterpreter *interpreter;
    
    __weak IBOutlet UIImageView *imageViewLogo;
    
    NSDateFormatter *formatterTime;
    NSDateFormatter *formatterDay;
    NSDateFormatter *formatterMonthYear;
    
    __weak IBOutlet UILabel *labelTime;
    __weak IBOutlet UILabel *labelMonthYear;
    
    NSTimer *examplesTimer;
    BOOL wasShowingExamples;
    
    //All reminders
    UICollectionView *collectionViewReminders;
}

@end

@implementation KNNoteViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    manager = [KNRemindersManager sharedManager];
    [manager requestAccessToStoreCompletion:^(BOOL granted) {
        if (!granted)
            [self showMessage:@"Error getting reminder access"];
    }];
    
    labelTime.alpha = 0;
    labelMonthYear.alpha = 0;
    
    textViewNote.delegate = self;
    
    interpreter = [[KNInterpreter alloc] initWithDelegate:self];
    
    textViewNote.layer.cornerRadius = 6;
    
    formatterTime = [NSDateFormatter new];
    formatterDay = [NSDateFormatter new];
    formatterMonthYear = [NSDateFormatter new];
    
    [imageViewLogo setUserInteractionEnabled:YES];
    [imageViewLogo addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewAllReminders)]];
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideReminders)]];
    
    //@"h:mm a, EEE, MMM d, yyyy";
    
    [formatterTime setDateFormat:@"EEE, h:mm a"];
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
    
    labelTime.alpha = 0;
    labelMonthYear.alpha = 0;
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

-(void)viewAllReminders
{
    if (!collectionViewReminders)
    {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.itemSize = CGSizeMake(280, 44);
        float p = 40;
        collectionViewReminders = [[UICollectionView alloc] initWithFrame:CGRectMake(p, p, self.view.frame.size.width - p*2, self.view.frame.size.height - p*2) collectionViewLayout:layout];
        [collectionViewReminders registerNib:[UINib nibWithNibName:@"reminderCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:@"reminderCell"];
        collectionViewReminders.dataSource = self;
        collectionViewReminders.delegate = self;
    }
    
    [manager fetchAllReminders:^(NSArray *reminders)
    {
        [self.view addSubview:collectionViewReminders];
        [collectionViewReminders reloadData];
    }];
    
    [textViewNote resignFirstResponder];
}

-(void)hideReminders
{
    [collectionViewReminders removeFromSuperview];
    [textViewNote becomeFirstResponder];
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
    if (wasShowingExamples){
        [self stopExamples];
        textView.text = @"";
        
        return NO;
    }
    
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
    labelTime.alpha = 1;
    labelMonthYear.alpha = 1;
    
    labelTime.text = [formatterTime stringFromDate:date];
    //labelDay.text = [formatterDay stringFromDate:date];
    labelMonthYear.text = [formatterMonthYear stringFromDate:date];
}

-(void)interpreterFailedToFindDate:(KNInterpreter *)interpreter
{
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
    
    EKReminder *reminder = [EKReminder reminderWithEventStore:manager.store];
    
    NSString *successString = @"Saved";
    
    //If date found add one, otherwise add no due date
    if (interpreter.date) {
        successString = @"Scheduled";
        
        NSDate *oneSecondLater = [NSDate dateWithTimeInterval:1 sinceDate:interpreter.date]; //Add one second on to each to deal with nanoseconds etc.!
        EKAlarm *alarm = [EKAlarm alarmWithAbsoluteDate:oneSecondLater];
        [reminder addAlarm:alarm];
    }
    
    [reminder setTitle:textViewNote.text];
    [reminder setCalendar:[manager.store defaultCalendarForNewReminders]];
    
    NSError *reminderError;
    [manager.store saveReminder:reminder commit:YES error:&reminderError];
    
    if (reminderError){
        NSLog(@"Error: %@", reminderError);
        [self showMessage:@"Note failed to save"];
    }else{
        //Note saved successfully, show it!
        [self showMessage:[NSString stringWithFormat:@"Note %@ \u2713", successString]];
        textViewNote.text = @"";
        
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
    
    hud.color = [UIColor yellowColor];
    hud.labelColor = [UIColor blackColor];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = message;
    
    [hud hide:YES afterDelay:1];
}

//Collection view

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionViewReminders dequeueReusableCellWithReuseIdentifier:@"reminderCell" forIndexPath:indexPath];
    
    EKReminder *reminder = manager.reminders[indexPath.row];
    
    
    return cell;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return manager.reminders.count;
}

@end
