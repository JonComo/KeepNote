//
//  KNInterpreter.h
//  KeepNote
//
//  Created by Jon Como on 11/28/12.
//  Copyright (c) 2012 Jon Como. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KNInterpreter;

@protocol KNInterpreterDelegate <NSObject>

-(void)interpreterLookingForDate:(KNInterpreter *)interpreter;
-(void)interpreter:(KNInterpreter *)interpreter foundDate:(NSDate *)date formattedString:(NSString *)formattedString;
-(void)interpreterFailedToFindDate:(KNInterpreter *)interpreter;

@end

@interface KNInterpreter : NSObject

@property id delegate;

@property (strong, nonatomic) NSDate *date;

-(id)initWithDelegate:(id)interpreterDelegate;

-(void)interpretString:(NSString *)userInputString;

@end
