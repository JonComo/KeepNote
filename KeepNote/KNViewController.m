//
//  KNViewController.m
//  KeepNote
//
//  Created by Jon Como on 11/19/12.
//  Copyright (c) 2012 Jon Como. All rights reserved.
//

#import "KNViewController.h"
#import "KNInterpreter.h"
#import <QuartzCore/QuartzCore.h>
#import <EventKit/EventKit.h>

#define EXAMPLES @[@"Meeting in 20 min", @"Perform ritual in 20 moons", @"Dinner in 5 min", @"Kick son out in 16 years", @"Hot date on 1/12/13, hopefully", @"Start diet in 15 s", @"Make a lot of money, then give it to charity, in 6 months", @"Run marathon in 2 weeks", @"Quit job in 2 h", @"Swim in 6 months", @"Summer again in 1 solar orbit", @"Lunch in 10", @"Enjoy life in 12 hours", @"Pulse my laser twice in 2 femtoseconds", @"Murder the king in 12.5 moments", @"Be there in 1 moment", @"Overcome inability to understand time smaller than one plank time unit, in 0.5 PTUs", @"Start a new fashion trend in 1.2 generations", @"Wonder why I use leap year as a time unit in 3 leap years", @"Watch 8 molecules sequentially fluoresce in 8 nanoseconds", @"Enjoy the olympics in 2 olympiads", @"Wish my parents goodluck in 2 lustrums", @"Buy new shoes in 1 decade", @"Plan for the future, in 2 gigaseconds", @"Plot my position, in 2 fortnights"]

@interface KNViewController () <KNInterpreterDelegate, UITextViewDelegate, UIAlertViewDelegate>
{
    KNInterpreter *interpreter;
    EKEventStore *store;
}

@end

@implementation KNViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    interpreter = [[KNInterpreter alloc] initWithDelegate:self];
    store = [[EKEventStore alloc] init];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"backgroundTexture"]];
    
    NSTimer *examplesTimer;
    examplesTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(showExample) userInfo:nil repeats:YES];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //Setup some constants for new note appearing
    
    noteConstraint.constant = 400; //Push note down
    padConstraint.constant = 80; //Push pad down
    [self.view layoutSubviews];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self createNewNote];
}

-(void)showExample
{
    NSString *task = (NSString *)[EXAMPLES objectAtIndex:arc4random()%(EXAMPLES.count-1)];
    
    while ([exampleNotesView.text isEqualToString:task]) {
        task = (NSString *)[EXAMPLES objectAtIndex:arc4random()%(EXAMPLES.count-1)];
    }
    
    exampleNotesView.text = task;
}

-(void)notAllowed
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops!" message:@"To use KeepNote you need to grant it access. You can do so in the phone's Settings, Privacy menu." delegate:self cancelButtonTitle:@"No" otherButtonTitles:nil];
    [alert show];
}

-(void)saveReminder
{
    if (noteText.text.length == 0) return;
    
    [interpreter interpretString:noteText.text]; //Interpret once again to get the latest date
    
    EKReminder *reminder = [EKReminder reminderWithEventStore:store];
    
    //If date found add one, otherwise add no due date
    if (interpreter.date) {
        NSDate *oneSecondLater = [NSDate dateWithTimeInterval:1 sinceDate:interpreter.date]; //Add one second on to each to deal with nanoseconds etc.!
        EKAlarm *alarm = [EKAlarm alarmWithAbsoluteDate:oneSecondLater];
        [reminder addAlarm:alarm];
    }
    
    [reminder setTitle:noteText.text];
    [reminder setCalendar:[store defaultCalendarForNewReminders]];
    
    NSError *reminderError;
    [store saveReminder:reminder commit:YES error:&reminderError];
    
    if (reminderError){
        NSLog(@"Error: %@", reminderError);
        [self showConfirmationWithImage:[UIImage imageNamed:@"deleted"]];
    }else{
        //Note saved successfully, show it!
        [self showConfirmationWithImage:[UIImage imageNamed:@"saved"]];
        [self promptReview];
    }
}

-(void)promptReview
{
    NSUserDefaults *center = [NSUserDefaults standardUserDefaults];
    
    if ([center boolForKey:@"shownPrompt"]) {
        return; //already shown prompt
    }
    
    if (![center integerForKey:@"timesSaved"]) {
        [center setInteger:0 forKey:@"timesSaved"];
    }
    
    int timesSaved = [center integerForKey:@"timesSaved"];
    timesSaved ++;
    [center setInteger:timesSaved forKey:@"timesSaved"];
    
    if ([center integerForKey:@"timesSaved"] == 3) {
        
        [center setBool:YES forKey:@"shownPrompt"];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"KeepNote treating you right?" message:@"Why not give it a review on the app store? I really appreciate any feedback. Thank you!" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Review", nil];
        [alert show];
    }
    
    [center synchronize];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        //They wanted to review, sweet
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.iTunes.com/apps/keepnote"]];
    }
}

-(void)createNewNote
{
    [store requestAccessToEntityType:EKEntityTypeReminder completion:^(BOOL granted, NSError *error) {
        if (error) {
            NSLog(@"Error with request: %@", error);
        }
        if (granted) {
            [self performSelectorOnMainThread:@selector(animateNoteOut) withObject:nil waitUntilDone:NO];
        }else{
            [self performSelectorOnMainThread:@selector(notAllowed) withObject:nil waitUntilDone:NO];
        }
    }];
}

#pragma Animations

-(void)animateNoteOut
{
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView animateWithDuration:0.15 animations:^{
        //Push pad down
        padConstraint.constant = 90;
        [self.view layoutSubviews];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    } completion:^(BOOL finished) {
        [noteText becomeFirstResponder];
        
        [UIView animateWithDuration:0.2 animations:^{
            //Push pad up
            padConstraint.constant = 60;
            //Push note up
            noteConstraint.constant = -20;
            [self.view layoutSubviews];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3 animations:^{
                //Push pad back in place
                padConstraint.constant = 80;
                
                //Push note into place
                noteConstraint.constant = 0;
                
                [self.view layoutSubviews];
            } completion:^(BOOL finished) {
                
            }];
        }];
    }];
}

-(void)animateNoteIn
{
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView animateWithDuration:0.15 animations:^{
        //Push note up
        noteConstraint.constant = -20;
        [self.view layoutSubviews];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 animations:^{
            //Push note down
            [noteText resignFirstResponder];
            noteConstraint.constant = 400;
            [self.view layoutSubviews];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.17 animations:^{
                //Push pad down
                padConstraint.constant = 100;
                [self.view layoutSubviews];
                [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            } completion:^(BOOL finished) {
                noteText.text = @"";
                outputLabel.text = @"";
                exampleNotesView.alpha = 1;
                [UIView animateWithDuration:0.25 animations:^{
                    //Push pad back in place
                    padConstraint.constant = 80;
                    [self.view layoutSubviews];
                }];
            }];
        }];
    }];
}

#pragma KNInterpreterDelegate

-(void)interpreterLookingForDate:(KNInterpreter *)interpreter
{
    outputLabel.text = @"Searching...";
}

-(void)interpreter:(KNInterpreter *)interpreter foundDate:(NSDate *)date formattedString:(NSString *)formattedString
{
    outputLabel.text = [NSString stringWithFormat:@"Date: %@", formattedString];
}

-(void)interpreterFailedToFindDate:(KNInterpreter *)interpreter
{
    outputLabel.text = @"No date found. Just note it!";
}

#pragma UITextViewDelegate

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"]) {
        [self saveReminder];
        [self animateNoteIn];
        return NO;
    }
    
    return YES;
}

-(void)textViewDidChange:(UITextView *)textView
{
    if (textView.text.length == 0) {
        [UIView animateWithDuration:0.2 animations:^{
            exampleNotesView.alpha = 1;
        }];
    }else{
        [UIView animateWithDuration:0.2 animations:^{
            exampleNotesView.alpha = 0;
        }];
    }
    
    [interpreter interpretString:noteText.text];
}

#pragma System functions

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma UIActions

- (IBAction)newNote:(UIButton *)sender
{
    [self createNewNote];
}

- (IBAction)closeNote:(id)sender
{
    [self animateNoteIn];
    [self showConfirmationWithImage:[UIImage imageNamed:@"deleted"]];
}

-(void)showConfirmationWithImage:(UIImage *)image
{
    confirmationImage.image = image;
    confirmationImage.layer.transform = CATransform3DMakeScale(0, 0, 0);
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView animateWithDuration:0.5 animations:^{
        confirmationImage.layer.transform = CATransform3DMakeScale(1.05, 1.05, 1.05);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 animations:^{
            confirmationImage.layer.transform = CATransform3DMakeScale(0.95, 0.95, 0.95);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2 animations:^{
                confirmationImage.layer.transform = CATransform3DMakeScale(1, 1, 1);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.2 delay:0.2 options:0 animations:^{
                    confirmationImage.layer.transform = CATransform3DMakeScale(1.1, 1.1, 1.1);
                } completion:^(BOOL finished) {
                    [UIView animateWithDuration:0.2 animations:^{
                        confirmationImage.layer.transform = CATransform3DMakeScale(0, 0, 0);
                    }];
                }];
            }];
        }];
    }];
}

@end
