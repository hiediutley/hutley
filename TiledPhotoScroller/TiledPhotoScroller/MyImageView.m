//
//  MyImageView.m
//  TiledPhotoScroller
//
//  Created by Hiedi Utley on 2/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MyImageView.h"
#import "MyScrollView.h"

@implementation MyImageView

- (void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
    CGPoint pt = [[touches anyObject] locationInView:self];
    startLocation = pt;
    NSLog(@"image touch begin");
    
    [self setBackgroundColor:[UIColor blueColor]];
    CGRect rect = [self frame];
    float height = rect.size.height * 1.25;
    float width = rect.size.width * 1.25;
    
    self.frame = CGRectMake(rect.origin.x, rect.origin.y, width, height);
    
}
- (void) touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
    
    UITouch * touch = [touches anyObject];
    
    CGPoint pt = [[touches anyObject] locationInView:self];
    
    CGPoint windowPt = [[touch window] convertPoint:pt fromView:self];
    
    
    CGRect frame = [self frame];
    frame.origin.x += pt.x - startLocation.x;
    frame.origin.y += pt.y - startLocation.y;
    [self setFrame: frame];

    
    NSLog(@"moved x=%f y=%f ht=%f", windowPt.x, windowPt.y, self.frame.size.height);
    
    if ((1024 - windowPt.y) < (self.frame.size.height /2 ))
    {
        NSLog(@"hi!!");
        
        UIScrollView * scroll =(UIScrollView *)[self superview];
        [scroll scrollRectToVisible:frame animated:YES];
    }

    
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"image touch ended");
    CGRect rect = [self frame];
    [self setBackgroundColor:[UIColor clearColor]];

    self.frame = CGRectMake(rect.origin.x, rect.origin.y, (rect.size.width/5)*4, (rect.size.height/5)*4);

    [super touchesEnded:touches withEvent:event];
    
}

-(void) dealloc
{
    [super dealloc];
}
@end
