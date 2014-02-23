//
//  KNNoteViewController.m
//  KeepNote
//
//  Created by Jon Como on 2/19/14.
//  Copyright (c) 2014 Jon Como. All rights reserved.
//

#import "KNNoteViewController.h"

#import "KNGraphics.h"

#import "KNInterpreter.h"

#import "MBProgressHUD.h"

#import "KNTextView.h"

#import "KNRemindersManager.h"

#import <EventKit/EventKit.h>
#import "KNReminderCell.h"

#define EXAMPLES @[@"Meeting in 20 min", @"Perform ritual in 20 moons", @"Dinner in 5 min", @"Kick son out in 16 years", @"Hot date on 1/12/13", @"Start diet in 15 days", @"Make money, then give it to charity, in 6 months", @"Run marathon in 2 weeks", @"Quit job in 2 hours", @"Swim in 6 months", @"Summer again in 1 solar orbit", @"Lunch in 10", @"Enjoy life in 12 hours", @"Pulse my laser twice in 2 femtoseconds", @"Murder the king in 12.5 moments", @"Be there in 1 moment", @"Learn about plank time units, in 0.5 PTUs", @"Start a new fashion trend in 1.2 generations", @"Enjoy the olympics in 2 olympiads", @"Wish my parents goodluck in 2 lustrums", @"Buy new shoes in 1 decade", @"Plan for the future, in 2 gigaseconds", @"Plot my position, in 2 fortnights", @"Doctors on Jan 1, 2014 8 am", @"Meeting on feb 2, 9am"]

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
    UIView *viewDim;
    UIView *viewDepth;
    UICollectionView *collectionViewReminders;
    
    CGSize cellSize;
    
    UISegmentedControl *segmentFilter;
    UISegmentedControl *segmentCompleted;
    
    UIRefreshControl *refresh;
    
    BOOL isEditMode;
}

@end

@implementation KNNoteViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    manager = [KNRemindersManager sharedManager];
    [manager requestAccessToStoreCompletion:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!granted)
                [self showMessage:@"Error getting reminder access" inView:self.view];
        });
    }];
    
    labelTime.alpha = 0;
    labelMonthYear.alpha = 0;
    
    textViewNote.delegate = self;
    
    interpreter = [[KNInterpreter alloc] initWithDelegate:self];
    
    formatterTime = [NSDateFormatter new];
    formatterDay = [NSDateFormatter new];
    formatterMonthYear = [NSDateFormatter new];
    
    [imageViewLogo setUserInteractionEnabled:YES];
    [imageViewLogo addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewAllReminders)]];
    
    //@"h:mm a, EEE, MMM d, yyyy";
    
    [formatterTime setDateFormat:@"EEE, h:mm a"];
    [formatterDay setDateFormat:@"EEEE"];
    [formatterMonthYear setDateFormat:@"MMM, d, yyyy"];
    
    isEditMode = NO;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:KNReminderDeletedNotification object:nil queue:[NSOperationQueue new] usingBlock:^(NSNotification *note) {
        dispatch_async(dispatch_get_main_queue(), ^{
            for (UICollectionViewCell *cell in collectionViewReminders.visibleCells)
            {
                if ([cell isKindOfClass:[KNReminderCell class]])
                {
                    KNReminderCell *reminderCell = (KNReminderCell *)cell;
                    if (reminderCell.reminder == note.object){
                        //remove this cell
                        
                        NSIndexPath *indexToDelete = [collectionViewReminders indexPathForCell:reminderCell];
                        if (manager.filtered.count > 0){
                            [collectionViewReminders deleteItemsAtIndexPaths:@[indexToDelete]];
                        }else{
                            [collectionViewReminders reloadData];
                        }
                    }
                }
            }
        });
    }];
    
    [self startExamples];
}

-(void)startExamples
{
    [self showExample];
    
    examplesTimer = [NSTimer scheduledTimerWithTimeInterval:4 target:self selector:@selector(showExample) userInfo:nil repeats:YES];
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
    isEditMode = NO;
    
    if (!collectionViewReminders){
        float p = 20; //padding
        
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        cellSize = CGSizeMake(self.view.frame.size.width - p*2, 60);
        layout.itemSize = cellSize;
        layout.minimumInteritemSpacing = 0;
        layout.minimumLineSpacing = 0;
        
        CGRect collectionViewFrame = CGRectMake(p, p*2, self.view.frame.size.width - p*2, self.view.frame.size.width - p*2);
        
        segmentFilter = [[UISegmentedControl alloc] initWithItems:@[@"Notes", @"Reminders"]];
        segmentFilter.frame = CGRectMake(p, collectionViewFrame.size.height + collectionViewFrame.origin.y + p, self.view.frame.size.width - p*2, 44);
        segmentFilter.tintColor = [KNGraphics tintColor];
        segmentFilter.selectedSegmentIndex = 0;
        [segmentFilter addTarget:self action:@selector(segmentedFilterChanged:) forControlEvents:UIControlEventValueChanged];
        
        segmentCompleted = [[UISegmentedControl alloc] initWithItems:@[@"All", @"Uncompleted"]];
        segmentCompleted.frame = CGRectOffset(segmentFilter.frame, 0, segmentFilter.frame.size.height + p);
        segmentCompleted.selectedSegmentIndex = 1;
        [segmentCompleted addTarget:self action:@selector(segmentedCompletedChanged:) forControlEvents:UIControlEventValueChanged];
        
        collectionViewReminders = [[UICollectionView alloc] initWithFrame:collectionViewFrame collectionViewLayout:layout];
        [collectionViewReminders registerNib:[UINib nibWithNibName:@"reminderCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:@"reminderCell"];
        [collectionViewReminders registerNib:[UINib nibWithNibName:@"createCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:@"createCell"];
        
        collectionViewReminders.clipsToBounds = YES;
        collectionViewReminders.layer.cornerRadius = 3;
        collectionViewReminders.backgroundColor = [UIColor whiteColor];
        
        collectionViewReminders.alwaysBounceVertical = YES;
        
        collectionViewReminders.dataSource = self;
        collectionViewReminders.delegate = self;
        
        UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
        swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
        
        UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)];
        swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
        
        [collectionViewReminders addGestureRecognizer:swipeRight];
        [collectionViewReminders addGestureRecognizer:swipeLeft];
        
        refresh = [[UIRefreshControl alloc] init];
        [collectionViewReminders addSubview:refresh];
        [refresh addTarget:self action:@selector(refreshReminders) forControlEvents:UIControlEventValueChanged];
        
        viewDim = [[UIView alloc] initWithFrame:self.view.frame];
        viewDim.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        [viewDim addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideReminders)]];
        
        viewDepth = [[UIView alloc] initWithFrame:collectionViewReminders.frame];
        viewDepth.frame = CGRectOffset(viewDepth.frame, 0, 4);
        viewDepth.backgroundColor = [UIColor colorWithRed:0.835 green:0.620 blue:0.000 alpha:1.000];
        viewDepth.layer.cornerRadius = collectionViewReminders.layer.cornerRadius;
    }
    
    [self.view addSubview:viewDim];
    
    [manager fetchAllReminders:^(NSArray *reminders)
    {
        [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            imageViewLogo.layer.transform = CATransform3DMakeTranslation(-20, 0, 0);

        } completion:^(BOOL finished) {
            
            imageViewLogo.alpha = 0;
            imageViewLogo.layer.transform = CATransform3DIdentity;
            
            [self.view addSubview:viewDepth];
            [self.view addSubview:collectionViewReminders];
            [self.view addSubview:segmentFilter];
            [self.view addSubview:segmentCompleted];
            
            segmentFilter.layer.transform = CATransform3DMakeTranslation(0, -20, 0);
            segmentCompleted.layer.transform = segmentFilter.layer.transform;
            collectionViewReminders.layer.transform = CATransform3DMakeScale(0.9, 0.9, 1);
            viewDepth.layer.transform = collectionViewReminders.layer.transform;
            
            [UIView animateWithDuration:0.2 animations:^{
                viewDim.alpha = 1;
            }];
            
            [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.1 options:0 animations:^{
                collectionViewReminders.layer.transform = CATransform3DIdentity;
                viewDepth.layer.transform = CATransform3DIdentity;
                segmentFilter.layer.transform = CATransform3DIdentity;
                segmentCompleted.layer.transform = CATransform3DIdentity;
            } completion:nil];
            
            [manager filter:segmentFilter.selectedSegmentIndex];
            [collectionViewReminders reloadData];
        }];
    }];
    
    [self showDeleteTip];
    [textViewNote resignFirstResponder];
}

-(void)hideReminders
{
    [textViewNote becomeFirstResponder];
    
    [UIView animateWithDuration:0.2 animations:^{
        viewDim.alpha = 0;
    }];
    
    imageViewLogo.layer.transform = CATransform3DMakeTranslation(-20, 0, 0);
    
    [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        collectionViewReminders.layer.transform = CATransform3DMakeScale(0.9, 0.9, 1);
        segmentFilter.layer.transform = CATransform3DMakeTranslation(0, -20, 0);
        segmentCompleted.layer.transform = CATransform3DMakeTranslation(0, -20, 0);
        viewDepth.layer.transform = collectionViewReminders.layer.transform;
    } completion:^(BOOL finished) {
        
        [viewDepth removeFromSuperview];
        [collectionViewReminders removeFromSuperview];
        [viewDim removeFromSuperview];
        [segmentFilter removeFromSuperview];
        [segmentCompleted removeFromSuperview];
        
        imageViewLogo.alpha = 1;
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            imageViewLogo.layer.transform = CATransform3DIdentity;
        } completion:nil];
    }];
}

-(void)segmentedFilterChanged:(UISegmentedControl *)control
{
    //filter em out
    [manager filter:segmentFilter.selectedSegmentIndex];
    [collectionViewReminders reloadData];
}

-(void)segmentedCompletedChanged:(UISegmentedControl *)control
{
    manager.showUncompleteOnly = control.selectedSegmentIndex;
    [collectionViewReminders reloadData];
}

-(void)showDeleteTip
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"hasShownDeleteTip"]){
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasShownDeleteTip"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self showMessage:@"Swipe right to edit" inView:collectionViewReminders];
    }
}

-(void)swipeRight:(UISwipeGestureRecognizer *)swipe
{
    isEditMode = YES;
    
    for (KNReminderCell *cell in collectionViewReminders.visibleCells){
        cell.isEditMode = isEditMode;
    }
}

-(void)swipeLeft:(UISwipeGestureRecognizer *)swipe
{
    isEditMode = NO;
    
    for (KNReminderCell *cell in collectionViewReminders.visibleCells){
        cell.isEditMode = isEditMode;
    }
}

-(void)refreshReminders
{
    [manager fetchAllReminders:^(NSArray *reminders) {
        [refresh endRefreshing];
        [self updateReminders];
    }];
}

-(void)updateReminders
{
    manager.showUncompleteOnly = segmentCompleted.selectedSegmentIndex;
    [manager filter:segmentFilter.selectedSegmentIndex];
    [collectionViewReminders reloadData];
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
    
    if ([text isEqualToString:@"\n"]){
        [self saveReminder];
        return NO;
    }
    
    NSString *fullString = [textViewNote.text stringByReplacingCharactersInRange:range withString:text];
    [interpreter interpretString:fullString];
    
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
    
    //[interpreter interpretString:textViewNote.text]; //Interpret once again to get the latest date
    
    EKReminder *reminder = [EKReminder reminderWithEventStore:manager.store];
    
    NSString *successString = @"Saved";
    
    //If date found add one, otherwise add no due date
    if (interpreter.date) {
        segmentFilter.selectedSegmentIndex = 1;
        
        successString = @"Scheduled";
        
        NSDate *oneSecondLater = [NSDate dateWithTimeInterval:1 sinceDate:interpreter.date]; //Add one second on to each to deal with nanoseconds etc.!
        EKAlarm *alarm = [EKAlarm alarmWithAbsoluteDate:oneSecondLater];
        [reminder addAlarm:alarm];
        
        NSCalendar *calendar = [NSCalendar currentCalendar];
        
        reminder.dueDateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:interpreter.date];
    }else{
        segmentFilter.selectedSegmentIndex = 0;
    }
    
    [reminder setTitle:textViewNote.text];
    [reminder setCalendar:[manager.store defaultCalendarForNewReminders]];
    
    NSError *reminderError;
    [manager.store saveReminder:reminder commit:YES error:&reminderError];
    
    if (reminderError){
        NSLog(@"Error: %@", reminderError);
        [self showMessage:@"Note failed to save" inView:textViewNote];
    }else{
        //Note saved successfully, show it!
        [self showMessage:[NSString stringWithFormat:@"Note %@ \u2713", successString] inView:textViewNote];
        textViewNote.text = @"";
        
        labelTime.alpha = 0;
        labelMonthYear.alpha = 0;
        
        //Bounce notepad
        imageViewLogo.layer.transform = CATransform3DMakeRotation(-0.2, 0, 0, 1);
        [UIView animateWithDuration:0.6 delay:0 usingSpringWithDamping:0.3 initialSpringVelocity:1 options:0 animations:^{
            imageViewLogo.layer.transform = CATransform3DIdentity;
        } completion:^(BOOL finished) {
        }];
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

-(void)showMessage:(NSString *)message inView:(UIView *)view
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    
    hud.color = [KNGraphics tintColor];
    hud.labelColor = [UIColor blackColor];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = message;
    
    [hud hide:YES afterDelay:1.5];
}

//Collection view

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (manager.filtered.count == 0){
        //no notes or reminders, show create cell
        KNReminderCell *cell = [collectionViewReminders dequeueReusableCellWithReuseIdentifier:@"createCell" forIndexPath:indexPath];
        return cell;
    }
    
    KNReminderCell *cell = [collectionViewReminders dequeueReusableCellWithReuseIdentifier:@"reminderCell" forIndexPath:indexPath];
    
    EKReminder *reminder = manager.filtered[indexPath.row];
    
    cell.reminder = reminder;
    cell.isEditMode = isEditMode;
    
    return cell;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (manager.filtered.count == 0)
    {
        return 1; //create cell
    }else{
        return manager.filtered.count;
    }
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (manager.filtered.count == 0)
    {
        return collectionViewReminders.frame.size;
    }else{
        return cellSize;
    }
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (manager.filtered.count == 0)
    {
        //tapped create cell
        [self hideReminders];
    }
}

@end
