//
//  KNTextView.h
//  KeepNote
//
//  Created by Jon Como on 2/19/14.
//  Copyright (c) 2014 Jon Como. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KNTextView;

@protocol KNTextViewDelegate <UITextViewDelegate>

-(void)textViewDidDelete:(KNTextView *)textView;

@end

@interface KNTextView : UITextView

@property (nonatomic, weak) id<KNTextViewDelegate>delegate;

@end
