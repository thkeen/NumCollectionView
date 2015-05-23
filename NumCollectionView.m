//
//  NumCollectionView.m
//  num
//
//  Created by KEEN on 25/8/14.
//  Copyright (c) 2014 Thkeen. All rights reserved.
//

#import "NumCollectionView.h"

@protocol NumHoverViewDelegate <NSObject>
- (void)hoverViewTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)hoverViewTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)hoverViewTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)hoverViewTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
@end

@interface NumHoverView : UIView
@property (nonatomic, weak) id<NumHoverViewDelegate>delegate;
@end

@interface UIView (Transform)
- (void)zoomOut;
- (void)zoomNormal;
@end
@implementation UIView (Transform)
- (void)zoomOut {
  UIView *darkView = [self viewWithTag:1234];
  if (!darkView) {
    darkView = [[UIView alloc] initWithFrame:self.bounds];
    darkView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.15];
    darkView.alpha = 0;
    darkView.tag = 1234;
    [self addSubview:darkView];
  }
  [UIView animateWithDuration:0.27 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:0.2 options:UIViewAnimationCurveEaseIn|UIViewAnimationOptionBeginFromCurrentState animations:^{
    self.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.9, 0.9);
    self.layer.shadowOffset = CGSizeZero;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOpacity = 0.3;
    self.layer.masksToBounds = NO;
    self.layer.shadowRadius = 3;
    darkView.alpha = 1;
  } completion:^(BOOL finished) {
    
  }];
}
- (void)zoomNormal {
  self.layer.shadowOffset = CGSizeZero;
  self.layer.shadowColor = [UIColor clearColor].CGColor;
  UIView *darkView = [self viewWithTag:1234];
  [UIView animateWithDuration:0.27 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:0.2 options:UIViewAnimationCurveEaseIn|UIViewAnimationOptionBeginFromCurrentState animations:^{
    self.transform = CGAffineTransformIdentity;
    darkView.alpha = 0;
  } completion:^(BOOL finished) {
    [darkView removeFromSuperview];
  }];
}
@end

@interface NumCollectionView() <NumHoverViewDelegate>
@property (nonatomic, strong) UICollectionViewCell *beganCell;
@property (nonatomic, strong) UICollectionViewCell *selectedCell;
@property (nonatomic, strong) NSTimer *holdTimer;
@end

@implementation NumCollectionView

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self setup];
  }
  return self;
}
- (BOOL)touchesShouldCancelInContentView:(UIView *)view
{
  return YES;
}
- (void)setup {
  NumHoverView *hoverView = [[NumHoverView alloc] initWithFrame:self.bounds];
  hoverView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
  hoverView.delegate = self;
  hoverView.layer.zPosition = MAXFLOAT;
  [self addSubview:hoverView];
  [self bringSubviewToFront:hoverView];
}

- (void)didSelectCell {
  if (self.beganCell) {
    NSIndexPath *indexPath = [self indexPathForCell:self.beganCell];
    if (indexPath) {
      [self.delegate collectionView:self didSelectItemAtIndexPath:[self indexPathForCell:self.beganCell]];
    }
  }
}

#pragma mark - NumHoverViewDelegate

- (void)hoverViewTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  UITouch *touch = touches.allObjects.firstObject;
  CGPoint point = [touch locationInView:self];
  for (UICollectionViewCell *cell in self.visibleCells) {
    if (CGRectContainsPoint(cell.frame, point)) {
      [cell zoomOut];
      cell.layer.zPosition = MAXFLOAT-1;
      self.beganCell = cell;
      self.selectedCell = cell;
      [self.holdTimer invalidate];
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (cell == self.beganCell && self.beganCell == self.selectedCell && self.beganCell != nil) {
          [self.holdTimer invalidate]; // make sure all previous timers stop
          self.holdTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(didSelectCell) userInfo:nil repeats:YES];
        }
      });
    }
  }
}
- (void)hoverViewTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  UITouch *touch = touches.allObjects.firstObject;
  CGPoint point = [touch locationInView:self];
  for (UICollectionViewCell *cell in self.visibleCells) {
    if (CGRectContainsPoint(cell.frame, point)) {
      if (cell != self.selectedCell) {
        [self.holdTimer invalidate];
        [self.selectedCell zoomNormal];
        self.selectedCell.layer.zPosition = 0;
        [cell zoomOut];
        cell.layer.zPosition = MAXFLOAT-1;
        self.selectedCell = cell;
      }
    }
  }
}
- (void)hoverViewTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  [self.holdTimer invalidate];
  UITouch *touch = touches.allObjects.firstObject;
  CGPoint point = [touch locationInView:self];
  for (UICollectionViewCell *cell in self.visibleCells) {
    cell.layer.zPosition = 0;
    [cell zoomNormal];
  }
  if (self.beganCell == self.selectedCell) {
    if (CGRectContainsPoint(self.selectedCell.frame, point)) {
      [self didSelectCell];
    }
  }
  self.beganCell = nil;
  self.selectedCell = nil;
}
- (void)hoverViewTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  [self.holdTimer invalidate];
  for (UICollectionViewCell *cell in self.visibleCells) {
    cell.layer.zPosition = 0;
    [cell zoomNormal];
  }
  self.beganCell = nil;
  self.selectedCell = nil;
}

@end

@implementation NumHoverView

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  [self.delegate hoverViewTouchesBegan:touches withEvent:event];
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  [self.delegate hoverViewTouchesMoved:touches withEvent:event];
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  [self.delegate hoverViewTouchesEnded:touches withEvent:event];
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  [self.delegate hoverViewTouchesCancelled:touches withEvent:event];
}

@end
