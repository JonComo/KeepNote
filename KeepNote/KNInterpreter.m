//
//  KNInterpreter.m
//  KeepNote
//
//  Created by Jon Como on 11/28/12.
//  Copyright (c) 2012 Jon Como. All rights reserved.
//

#import "KNInterpreter.h"

#define NDay 86400

#define GalacticYear    @{@"multiplier" : @(725328e10), @"terms" : @[@"galactic year", @"galactic years", @"gy", @"gys"]} //Solar system orbits the milky way
#define Millennium      @{@"multiplier" : @(31536e6),   @"terms" : @[@"millennium", @"millenniums"]} //1000 years
#define Century         @{@"multiplier" : @(NDay * 365 * 100),    @"terms" : @[@"century", @"centuries"]} //100 years
#define Jubilees        @{@"multiplier" : @(NDay * 365 * 50),     @"terms" : @[@"jubilee", @"jubilees"]} //50 years
#define Gigaseconds     @{@"multiplier" : @(NDay * 365 * 31.7),   @"terms" : @[@"gigasecond", @"gigaseconds"]} //31.7 years
#define Generations     @{@"multiplier" : @(NDay * 365 * 26),     @"terms" : @[@"gens", @"gen", @"generations", @"generation"] } //26 years
#define Decades         @{@"multiplier" : @(NDay * 365 * 10),     @"terms" : @[@"decade", @"decades", @"dec", @"decs"] } //26 years
#define Lustrums        @{@"multiplier" : @(NDay * 365 * 5),      @"terms" : @[@"lustrum", @"lustrums"] } //5 years
#define Olympiads       @{@"multiplier" : @(NDay * 365 * 4),      @"terms" : @[@"olympiad", @"olympiads"] } //4 years
#define LeapYears       @{@"multiplier" : @(NDay * 366),          @"terms" : @[@"leap year", @"leap years"] } //366 days
#define Years           @{@"multiplier" : @(NDay * 365),          @"terms" : @[@"years", @"year", @"yrs", @"y", @"solar orbits", @"solar orbit"] } //365 days
#define Months          @{@"multiplier" : @(NDay * 30),           @"terms" : @[@"months", @"month", @"moon", @"moons"] }
#define Fortnights      @{@"multiplier" : @(NDay * 14),           @"terms" : @[@"fortnights", @"fortnight"] }
#define Weeks           @{@"multiplier" : @(NDay * 7),            @"terms" : @[@"weeks", @"week", @"wks"] }
#define Days            @{@"multiplier" : @(NDay),                @"terms" : @[@"days", @"day", @"d", @"earth rotations", @"earth rotation"] }
#define Hours           @{@"multiplier" : @(60 * 60),                     @"terms" : @[@"hours", @"hour", @"hrs"] }
#define Kiloseconds     @{@"multiplier" : @(1000),                        @"terms" : @[@"kiloseconds", @"kilosecond"] }
#define Moments         @{@"multiplier" : @(90),                          @"terms" : @[@"moment", @"moments"] } //90 seconds
#define Minutes         @{@"multiplier" : @(60),                          @"terms" : @[@"minutes", @"minute", @"min", @"mins", @"m"] }
#define Seconds         @{@"multiplier" : @(1),                           @"terms" : @[@"seconds", @"second", @"secs", @"sec", @"s"] }
#define Deciseconds     @{@"multiplier" : @(0.1),                         @"terms" : @[@"decisecond", @"deciseconds"] }
#define Centiseconds    @{@"multiplier" : @(0.01),                        @"terms" : @[@"centiseconds", @"centiseconds"] }
#define Milliseconds    @{@"multiplier" : @(0.001),                       @"terms" : @[@"milliseconds", @"millisecond"] }
#define Microseconds    @{@"multiplier" : @(1e-6),                        @"terms" : @[@"microsecond", @"microseconds"] }
#define Nanoseconds     @{@"multiplier" : @(1e-9),                        @"terms" : @[@"nanosecond", @"nanoseconds"] }
#define Picoseconds     @{@"multiplier" : @(1e-12),                       @"terms" : @[@"picosecond", @"picoseconds"] }
#define Femtoseconds    @{@"multiplier" : @(1e-15),                       @"terms" : @[@"femtosecond", @"femtoseconds"] }
#define PlankTimeUnits  @{@"multiplier" : @(1e-44),                       @"terms" : @[@"plank", @"planks", @"ptu", @"ptus", @"plank time unit", @"plank time units"] }

#define TERMS @[GalacticYear, Millennium, Century, Jubilees, Gigaseconds, Generations, Decades, Lustrums, Olympiads, LeapYears, Years, Months, Fortnights, Weeks, Days, Hours, Kiloseconds, Moments, Minutes, Seconds, Deciseconds, Centiseconds, Milliseconds, Microseconds, Nanoseconds, Picoseconds, Femtoseconds, PlankTimeUnits]

@interface KNInterpreter ()
{
    NSDateFormatter *formatter;
    NSDateFormatter *prettyFormatter;
    
    NSDataDetector *detector;
}

@end

@implementation KNInterpreter

-(id)initWithDelegate:(id)interpreterDelegate
{
    if (self = [super init]) {
        //init
        _delegate = interpreterDelegate;
        formatter = [[NSDateFormatter alloc] init];
        [formatter setLenient:YES];
        
        prettyFormatter = [[NSDateFormatter alloc] init];
        [prettyFormatter setDateFormat:@"h:mm a, EEE, MMM d, yyyy"];
        
        NSError *error;
        detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingAllTypes error:&error];
    }
    
    return self;
}

-(void)interpretString:(NSString *)userInputString
{
    [_delegate interpreterLookingForDate:self];
    
    _date = nil;
    NSString *lowerCaseString = [[NSString stringWithString:userInputString] lowercaseString];
    NSString *noPeriodString = [[NSString stringWithString:userInputString] stringByReplacingOccurrencesOfString:@"." withString:@""];
    
    [self findDateInString:noPeriodString];
    
    if (_date) {
        [_delegate interpreter:self foundDate:_date formattedString:[prettyFormatter stringFromDate:_date]];
        return;
    }
    
    _date = [self dateFromInput:lowerCaseString];
    if (_date)
    {
        [_delegate interpreter:self foundDate:_date formattedString:[prettyFormatter stringFromDate:_date]];
        return;
    }
    
    if (!_date) {
        [_delegate interpreterFailedToFindDate:self];
    }
}

#pragma Formatter date search

-(void)findDateInString:(NSString *)string
{
    [detector enumerateMatchesInString:string options:0 range:NSMakeRange(0, string.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        if (result.resultType == NSTextCheckingTypeDate)
        {
            self.date = result.date;
        }
    }];
}

#pragma Date search

-(NSDate *)dateFromInput:(NSString *)input
{
    NSScanner *aScanner = [NSScanner scannerWithString:input];
    
    float value;
    [aScanner setCharactersToBeSkipped:[[NSCharacterSet characterSetWithCharactersInString:@"1234567890."] invertedSet]];
    BOOL foundValue = [aScanner scanFloat:&value];
    
    NSString *unitString;
    [aScanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@" "]];
    NSString *floatString = [NSString stringWithFormat:@"%f", value];
    BOOL foundUnit = [aScanner scanUpToString:floatString intoString:&unitString];
    
    NSLog(@"Scanned and got %f %@", value, unitString);
    
    if (foundValue) {
        if (foundUnit) {
            for (u_int i = 0; i<TERMS.count; i++) {
                NSDictionary *timeUnit = TERMS[i];
                NSArray *subTerms  = timeUnit[@"terms"];
                for (u_int j = 0; j<subTerms.count; j++) {
                    NSString *subTerm = subTerms[j];
                    if ([subTerm isEqualToString:unitString]) {
                        //Got the right dictionary
                        return [self dateFromValue:value unit:timeUnit];
                    }
                }
            }
        }else{
            //Didn't find value, so just use minutes as the default
            return [self dateFromValue:value unit:Minutes];
        }
    }
    
    return nil;
}

-(NSDate *)dateFromValue:(float)value unit:(NSDictionary *)timeUnit
{
    NSNumber *multiplierNumber = (NSNumber *)timeUnit[@"multiplier"];
    
    NSTimeInterval interval = value * multiplierNumber.doubleValue;
    
    return [NSDate dateWithTimeIntervalSinceNow:interval];
}

-(NSDate *)dateFromInfo:(NSDictionary *)info
{
    NSNumber *value = (NSNumber *)[info objectForKey:@"value"];
    return [self dateFromValue:value.floatValue unit:[info objectForKey:@"unit"]];
}

-(NSDictionary *)unitFromString:(NSString *)string
{
    for (u_int i = 0; i<TERMS.count; i++)
    {
        NSDictionary *timeUnit = TERMS[i];
        if ([self string:string containsStringFromArray:timeUnit[@"terms"]]) {
            return timeUnit;
        }
    }
    
    return nil;
}

-(BOOL)string:(NSString *)string containsStringFromArray:(NSArray *)array
{
    for (NSString *term in array)
    {
        if ([string isEqualToString:term]) {
            return YES;
        }
    }
    
    return NO;
}

-(id)objectAtIndex:(int)index ofArray:(NSArray *)array
{
    if (index<0) return nil;
    if (index>array.count-1) return nil;
    return [array objectAtIndex:index];
}

@end
