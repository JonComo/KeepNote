//
//  KNTextView.m
//  KeepNote
//
//  Created by Jon Como on 2/19/14.
//  Copyright (c) 2014 Jon Como. All rights reserved.
//

#import "KNTextView.h"

@implementation KNTextView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)deleteBackward
{
    [super deleteBackward];
    
    if ([self.delegate respondsToSelector:@selector(textViewDidDelete:)])
        [self.delegate textViewDidDelete:self];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
