//
//  TiledPhotoScrollerController.m
//  TiledPhotoScroller
//
//  Created by Hiedi Utley on 2/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TiledPhotoScrollerController.h"
#import "MyScrollView.h"
#import "MyImageView.h"
#import "ThumbImageView.h"

#define THUMB_HEIGHT 100
#define THUMB_WIDTH 100
#define THUMB_V_PADDING 10
#define THUMB_H_PADDING 10
#define AUTOSCROLL_THRESHOLD 50
#define THUMB_ROWS 20

@interface TiledPhotoScrollerController (AutoscrollingMethods)
- (void)maybeAutoscrollForThumb:(ThumbImageView *)thumb;
- (void)autoscrollTimerFired:(NSTimer *)timer;
- (void)legalizeAutoscrollDistance;
- (float)autoscrollDistanceForProximityToEdge:(float)proximity;
- (void)createScrollViewIfNecessary;
@end

@implementation TiledPhotoScrollerController

-(void) awakeFromNib
{
    NSLog(@"here3");
    
    //replace the view with our scrollview;
    [self createScrollViewIfNecessary];
    
}

- (void)dealloc
{
    [scrollView release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
 // Implement loadView to create a view hierarchy programmatically, without using a nib.
 - (void)loadView
 {
 }
 */

/*
 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
 - (void)viewDidLoad
 {
 [super viewDidLoad];
 }
 */

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

#pragma mark ThumbImageViewDelegate methods

- (void)thumbImageViewWasTapped:(ThumbImageView *)tiv {
    
    //do nothing for now
}

- (void)thumbImageViewStartedTracking:(ThumbImageView *)tiv {
    [scrollView bringSubviewToFront:tiv];
}

- (void)thumbImageViewMoved:(ThumbImageView *)draggingThumb {
    
    // check if we've moved close enough to an edge to autoscroll, or far enough away to stop autoscrolling
    [self maybeAutoscrollForThumb:draggingThumb];
    
    /* The rest of this method handles the reordering of thumbnails in the thumbScrollView. See  */
    /* ThumbImageView.h and ThumbImageView.m for more information about how this works.          */
    
    // we'll reorder only if the thumb is overlapping the scroll view
    if (CGRectIntersectsRect([draggingThumb frame], [scrollView bounds])) {        
        
        BOOL draggingRight = [draggingThumb frame].origin.x > [draggingThumb home].origin.x ? YES : NO;
        BOOL draggingDown = [draggingThumb frame].origin.y > [draggingThumb home].origin.y ? YES : NO;

        /* we're going to shift over all the thumbs who live between the home of the moving thumb */
        /* and the current touch location. A thumb counts as living in this area if the midpoint  */
        /* of its home is contained in the area.                                                  */
        NSMutableArray *thumbsToShift = [[NSMutableArray alloc] init];
        
        // get the touch location in the coordinate system of the scroll view
        CGPoint touchLocation = [draggingThumb convertPoint:[draggingThumb touchLocation] toView:scrollView];
        
        // calculate minimum and maximum boundaries of the affected area
        float minX = draggingRight ? CGRectGetMaxX([draggingThumb home]) : touchLocation.x;
        float maxX = draggingRight ? touchLocation.x : CGRectGetMinX([draggingThumb home]);
        
        float minY = draggingDown ? CGRectGetMaxY([draggingThumb home]) : touchLocation.y;
        float maxY = draggingDown ? touchLocation.y : CGRectGetMinY([draggingThumb home]);
        
        NSLog(@"minX=%f maxX=%f minY=%f, maxY=%f",minX, maxX, minY, minY);
        
        // iterate through thumbnails and see which ones need to move over
        for (ThumbImageView *thumb in [scrollView subviews]) {
            
            // skip the thumb being dragged
            if (thumb == draggingThumb) continue;
            
            // skip non-thumb subviews of the scroll view (such as the scroll indicators)
            if (! [thumb isMemberOfClass:[ThumbImageView class]]) continue;
            
            
            float thumbMidpointX = CGRectGetMidX([thumb home]);
            float thumbMidpointY = CGRectGetMidY([thumb home]);
            
            //if midpoint of the thumb is within the bounds of the thumb being dragged
            if (thumbMidpointX >= minX && thumbMidpointX <= maxX) {
                NSLog(@"thumbMidX=%f thumbMidY=%f", thumbMidpointX, thumbMidpointY);

                //make sure its in the same y plane as well.
                if (thumbMidpointY <= minY && thumbMidpointY >= maxY)
                {
                    [thumbsToShift addObject:thumb];
                }
            }
        }
        
        // shift over the other thumbs to make room for the dragging thumb. (if we're dragging right, they shift to the left)
        float otherThumbShift = ([draggingThumb home].size.width + THUMB_H_PADDING) * (draggingRight ? -1 : 1);
        
        // as we shift over the other thumbs, we'll calculate how much the dragging thumb's home is going to move
        float draggingThumbShift = 0.0;
        
        // send each of the shifting thumbs to its new home
        for (ThumbImageView *otherThumb in thumbsToShift) {
            CGRect home = [otherThumb home];
            home.origin.x += otherThumbShift;
            [otherThumb setHome:home];
            [otherThumb goHome];
            draggingThumbShift += ([otherThumb frame].size.width + THUMB_H_PADDING) * (draggingRight ? 1 : -1);
        }
        
        [thumbsToShift release];
        
        // change the home of the dragging thumb, but don't send it there because it's still being dragged
        CGRect home = [draggingThumb home];
        home.origin.x += draggingThumbShift;
        [draggingThumb setHome:home];
    }
}

- (void)thumbImageViewStoppedTracking:(ThumbImageView *)tiv {
    // if the user lets go of the thumb image view, stop autoscrolling
    [autoscrollTimer invalidate];
    autoscrollTimer = nil;
}

#pragma mark Autoscrolling methods

- (void)maybeAutoscrollForThumb:(ThumbImageView *)thumb {
    
    autoscrollDistance = 0;
    
    // only autoscroll if the thumb is overlapping the thumbScrollView
    if (CGRectIntersectsRect([thumb frame], [scrollView bounds])) {
        
        CGPoint touchLocation = [thumb convertPoint:[thumb touchLocation] toView:scrollView];
        float distanceFromLeftEdge  = touchLocation.x - CGRectGetMinX([scrollView bounds]);
        float distanceFromRightEdge = CGRectGetMaxX([scrollView bounds]) - touchLocation.x;
        
        if (distanceFromLeftEdge < AUTOSCROLL_THRESHOLD) {
            autoscrollDistance = [self autoscrollDistanceForProximityToEdge:distanceFromLeftEdge] * -1; // if scrolling left, distance is negative
        } else if (distanceFromRightEdge < AUTOSCROLL_THRESHOLD) {
            autoscrollDistance = [self autoscrollDistanceForProximityToEdge:distanceFromRightEdge];
        }        
    }
    
    // if no autoscrolling, stop and clear timer
    if (autoscrollDistance == 0) {
        [autoscrollTimer invalidate];
        autoscrollTimer = nil;
    } 
    
    // otherwise create and start timer (if we don't already have a timer going)
    else if (autoscrollTimer == nil) {
        autoscrollTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / 60.0)
                                                           target:self 
                                                         selector:@selector(autoscrollTimerFired:) 
                                                         userInfo:thumb 
                                                          repeats:YES];
    } 
}

- (float)autoscrollDistanceForProximityToEdge:(float)proximity {
    // the scroll distance grows as the proximity to the edge decreases, so that moving the thumb
    // further over results in faster scrolling.
    return ceilf((AUTOSCROLL_THRESHOLD - proximity) / 5.0);
    
}

- (void)legalizeAutoscrollDistance {
    // makes sure the autoscroll distance won't result in scrolling past the content of the scroll view
    float minimumLegalDistance = [scrollView contentOffset].x * -1;
    float maximumLegalDistance = [scrollView contentSize].width - ([scrollView frame].size.width + [scrollView contentOffset].x);
    autoscrollDistance = MAX(autoscrollDistance, minimumLegalDistance);
    autoscrollDistance = MIN(autoscrollDistance, maximumLegalDistance);
}

- (void)autoscrollTimerFired:(NSTimer*)timer {
    [self legalizeAutoscrollDistance];
    
    // autoscroll by changing content offset
    CGPoint contentOffset = [scrollView contentOffset];
    contentOffset.x += autoscrollDistance;
    [scrollView setContentOffset:contentOffset];
    
    // adjust thumb position so it appears to stay still
    ThumbImageView *thumb = (ThumbImageView *)[timer userInfo];
    [thumb moveByOffset:CGPointMake(autoscrollDistance, 0)];
    
    NSLog(@"scrollBy:%f" , autoscrollDistance);
}

- (void)createScrollViewIfNecessary {
    
    if (!scrollView) {        
        
        float scrollViewHeight = 1024;
        float scrollViewWidth  = [[self view] bounds].size.width;
        scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, scrollViewWidth, scrollViewHeight)];
        [scrollView setCanCancelContentTouches:NO];
        [scrollView setClipsToBounds:NO];
        [scrollView setBackgroundColor:[UIColor grayColor]];
        
        // now place all the thumb views as subviews of the scroll view 
        // and in the course of doing so calculate the content width
        float xPosition = THUMB_H_PADDING;
        float yPosition = THUMB_V_PADDING;
        
        for (int row = 0; row < THUMB_ROWS; row++)
        {
            //reset x
            xPosition = THUMB_H_PADDING;
            for (int i = 0; i < 10 ; i++)
            {
                UIImage *thumbImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", @"apple"]];
                if (thumbImage) {
                    ThumbImageView *thumbView = [[ThumbImageView alloc] initWithImage:thumbImage];
                    [thumbView setDelegate:self];
                    [thumbView setImageName: [NSString stringWithFormat:@"%@%i", @"apple", i]];
                    CGRect frame = [thumbView frame];
                    frame.origin.y = yPosition;
                    frame.origin.x = xPosition;
                    frame.size.width = THUMB_WIDTH;
                    frame.size.height = THUMB_HEIGHT;
                    [thumbView setFrame:frame];
                    [thumbView setHome:frame];
                    [scrollView addSubview:thumbView];
                    [thumbView release];
                    xPosition += (frame.size.width + THUMB_H_PADDING);
                }
                
                yPosition = (row * (THUMB_HEIGHT + THUMB_V_PADDING));
            }
        }
        [scrollView setContentSize:CGSizeMake(xPosition, yPosition)];
        [[self view] addSubview:scrollView];
    }    
}

@end
