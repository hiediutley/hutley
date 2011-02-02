//
//  TiledPhotoScrollerController.h
//  TiledPhotoScroller
//
//  Created by Hiedi Utley on 2/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ThumbImageView.h"

@class MyScrollView;

@interface TiledPhotoScrollerController : UIViewController < UIScrollViewDelegate,ThumbImageViewDelegate> {
@private
    UIScrollView * scrollView;
    NSTimer *autoscrollTimer;  // Timer used for auto-scrolling.
    float autoscrollDistance;  // Distance to scroll the thumb view when auto-scroll timer fires.

}

@end
