//
//  MyScrollView.m
//  TiledPhotoScroller
//
//  Created by Hiedi Utley on 2/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MyScrollView.h"
#import "MyImageView.h"

@implementation MyScrollView

/*
-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"scroll touches began");
    [super touchesBegan: touches withEvent: event];

}

- (void) touchesEnded: (NSSet *) touches withEvent: (UIEvent *) event 
{	
    NSLog(@"scroll touches ended");

    [self setScrollEnabled:YES];

        [super touchesEnded: touches withEvent: event];
    
    
    
}

-(BOOL) touchesShouldBegin:(NSSet *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view
{
    NSLog(@"scroll touches should begin");

    
    UITouch * touch = [touches anyObject];
    NSLog(@"Touch event for: %@", [[touch view] class]);

    if ([[touch view] isKindOfClass: [MyImageView class]])
    {
        NSLog(@"scroll disabled");

        [self setScrollEnabled:NO];
        return NO;
    }
    else 
    {
        NSLog(@"scroll enabled");

        [self setScrollEnabled:YES];
        return YES;
    }
     
    //return [super touchesShouldBegin:touches withEvent:event inContentView:view];
}

-(BOOL) touchesShouldCancelInContentView:(UIView *)view
{
    NSLog(@"scroll touches should cancel");

    return [super touchesShouldCancelInContentView:view];
}
 */

@end
