//
//  KNViewController.h
//  KeepNote
//
//  Created by Jon Como on 11/19/12.
//  Copyright (c) 2012 Jon Como. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KNViewController : UIViewController
{
    __weak IBOutlet NSLayoutConstraint *padConstraint;
    __weak IBOutlet NSLayoutConstraint *noteConstraint;
    
    __weak IBOutlet UITextView *noteText;
    __weak IBOutlet UILabel *outputLabel;
    
    __weak IBOutlet UIButton *newNoteButton;
    
    __weak IBOutlet UITextView *exampleNotesView;
    
    __weak IBOutlet UIImageView *confirmationImage;
}

- (IBAction)newNote:(UIButton *)sender;
- (IBAction)closeNote:(id)sender;


@end