//
//  LLMoveAbleTableView.m
//  LLMoveTableView
//
//  Created by cwli on 16/3/5.
//  Copyright © 2016年 lichengwu. All rights reserved.
//

#import "LLMoveAbleTableView.h"
#import "UITableViewCell+LLAdd.h"

/**
 * When the long press gesture recognizer began, we create a snap shot of the touched
 * cell so the user thinks that he is moving the cell itself. Instead we clear out the
 * touched cell and just move snap shot.
 */

@interface LLSnapShotImageView : UIImageView

- (void)moveByOffset:(CGPoint)offset;

@end

@implementation LLSnapShotImageView

#pragma mark - Autoscroll utilites
- (void)moveByOffset:(CGPoint)offset{
    CGRect frame = [self frame];
    frame.origin.x += offset.x;
    frame.origin.y += offset.y;
    [self setFrame:frame];
}

@end

/**
 * We need a little helper to cancel the current touch of the long press gesture recognizer
 * in the case the user does not tap on a row but on a section or table header
 */

@interface UIGestureRecognizer (LLUtilities)

- (void)cancelTouch;

@end


@implementation UIGestureRecognizer (LLUtilities)

- (void)cancelTouch
{
    [self setEnabled:NO];
    [self setEnabled:YES];
}

@end

@interface LLMoveAbleTableView ()

@property (nonatomic, assign) CGPoint touchOffset;
@property (nonatomic, strong) LLSnapShotImageView *snapShotImageView;
@property (nonatomic, strong) UILongPressGestureRecognizer *movingGestureRecognizer;

@property (nonatomic, strong) NSTimer *autoscrollTimer;
@property (nonatomic, assign) NSInteger autoscrollDistance;
@property (nonatomic, assign) NSInteger autoscrollThreshold;

@end

/**
 * The autoscroll methods are based on Apple's sample code 'ScrollViewSuite'
 */

@interface LLMoveAbleTableView (AutoscrollingMethods)

- (void)maybeAutoscrollForSnapShotImageView:(LLSnapShotImageView *)snapShot;
- (void)autoscrollTimerFired:(NSTimer *)timer;
- (void)legalizeAutoscrollDistance;
- (float)autoscrollDistanceForProximityToEdge:(float)proximity;
- (void)stopAutoscrolling;

@end

@implementation LLMoveAbleTableView
@dynamic dataSource;
@dynamic delegate;
@synthesize movingIndexPath = _movingIndexPath;
@synthesize touchOffset = _touchOffset;
@synthesize snapShotImageView = _snapShotImageView;
@synthesize movingGestureRecognizer = _movingGestureRecognizer;

@synthesize autoscrollTimer = _autoscrollTimer;
@synthesize autoscrollDistance = _autoscrollDistance;
@synthesize autoscrollThreshold = _autoscrollThreshold;

#pragma mark -
#pragma mark View life cycle

- (UILongPressGestureRecognizer *)movingGestureRecognizer {
    if (!_movingGestureRecognizer) {
        _movingGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        _movingGestureRecognizer.minimumPressDuration = 0.2f;
    }
    return _movingGestureRecognizer;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self removeGestureRecognizer:self.movingGestureRecognizer];
    [self addGestureRecognizer:self.movingGestureRecognizer];
}

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
    self = [super initWithFrame:frame style:style];
    
    if (self) {
        [self removeGestureRecognizer:self.movingGestureRecognizer];
        [self addGestureRecognizer:self.movingGestureRecognizer];
    }
    
    return self;
}

- (void)moveRowFromIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath {
    
    if ([newIndexPath section] != NSNotFound
        && [newIndexPath row] != NSNotFound
        && [newIndexPath compare:indexPath] != NSOrderedSame)
    {
        UITableViewCell *movingCell = (UITableViewCell *)[self cellForRowAtIndexPath:indexPath];
        [movingCell setSelected:NO animated:NO];
        [movingCell setHighlighted:NO animated:NO];
        
        // Create a snap shot of the moving cell and store it
        CGRect cellFrame = [movingCell bounds];
        
        if ([[UIScreen mainScreen] scale] == 2.0) {
            UIGraphicsBeginImageContextWithOptions(cellFrame.size, NO, 2.0);
        } else {
            UIGraphicsBeginImageContext(cellFrame.size);
        }
        [[movingCell layer] renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        LLSnapShotImageView *snapShotOfMovingCell = [[LLSnapShotImageView alloc] initWithImage:image];
        CGRect snapShotFrame = [self rectForRowAtIndexPath:indexPath];
        snapShotFrame.size = cellFrame.size;
        [snapShotOfMovingCell setFrame:snapShotFrame];
        [snapShotOfMovingCell setAlpha:1.0f];
        [self setSnapShotImageView:snapShotOfMovingCell];
        [self addSubview:[self snapShotImageView]];
        
        CGRect destFrame = [self rectForRowAtIndexPath:newIndexPath];
        
        // 这个地方，0.3f可以考虑改为动态计算，确保移动速度相同
        [UIView animateWithDuration:0.3f animations:^{
            [[self snapShotImageView] setFrame:destFrame];
            [[self snapShotImageView] setAlpha:1.0];
        } completion:^(BOOL finished) {
            if (finished)
            {
                // Clean up snap shot
                [[self snapShotImageView] removeFromSuperview];
                [self setSnapShotImageView:nil];
                
                [self beginUpdates];
                
                // Move the row
                [self deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
                [self insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationNone];
                
                // Inform the delegate to update it's model
                if ([[self delegate] respondsToSelector:@selector(moveableTableView:didMoveRowFromIndexPath:toIndexPath:)]) {
                    [[self delegate] moveableTableView:self didMoveRowFromIndexPath:indexPath toIndexPath:newIndexPath];
                }
                
                [self endUpdates];
            }
        }];
    }
}


#pragma mark - Helper methods
- (void)moveRowToIndexPath:(NSIndexPath *)newIndexPath
{
    // Analyze the new moving index path
    // 1. It's a valid index path
    // 2. It's not the current index path of the cell
    if ([newIndexPath section] != NSNotFound
        && [newIndexPath row] != NSNotFound
        && [newIndexPath compare:[self movingIndexPath]] != NSOrderedSame)
    {
        [self beginUpdates];
        
        // Move the row
        [self deleteRowsAtIndexPaths:[NSArray arrayWithObject:[self movingIndexPath]] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        // Inform the delegate to update it's model
        if ([[self delegate] respondsToSelector:@selector(moveableTableView:didMoveRowFromIndexPath:toIndexPath:)]) {
            [[self delegate] moveableTableView:self didMoveRowFromIndexPath:[self movingIndexPath] toIndexPath:newIndexPath];
        }
        
        // Update the moving index path
        [self setMovingIndexPath:newIndexPath];
        [self endUpdates];
    }
}

#pragma mark - #pragma mark Handle long press
- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    switch ([gestureRecognizer state])
    {
        case UIGestureRecognizerStateBegan:
        {
            CGPoint touchPoint = [gestureRecognizer locationInView:self];
            
            // Grap the touched index path
            NSIndexPath *touchedIndexPath = [self indexPathForRowAtPoint:touchPoint];
            
            // Check for a valid index path, otherwise cancel the touch
            if (!touchedIndexPath || [touchedIndexPath section] == NSNotFound || [touchedIndexPath row] == NSNotFound) {
                [gestureRecognizer cancelTouch];
                break;
            }
            
            if ([self.delegate respondsToSelector:@selector(moveableTableView:shouldMoveRowAtIndexPath:)]) {
                if (![self.delegate moveableTableView:self shouldMoveRowAtIndexPath:touchedIndexPath]) {
                    [gestureRecognizer cancelTouch];
                    break;
                }
            }
            
            [self setMovingIndexPath:touchedIndexPath];
            
            // Get the touched cell and reset it's selection state
            UITableViewCell *touchedCell = (UITableViewCell *)[self cellForRowAtIndexPath:touchedIndexPath];
            [touchedCell setSelected:NO];
            [touchedCell setHighlighted:NO];
            
            // Compute the touch offset from the cell's center
            CGPoint touchOffset = CGPointMake([touchedCell center].x - touchPoint.x, [touchedCell center].y - touchPoint.y);
            [self setTouchOffset:touchOffset];
            
            
            // Create a snap shot of the touched cell and store it
            CGRect cellFrame = [touchedCell bounds];
            
            if ([[UIScreen mainScreen] scale] == 2.0) {
                UIGraphicsBeginImageContextWithOptions(cellFrame.size, NO, 2.0);
            } else {
                UIGraphicsBeginImageContext(cellFrame.size);
            }
            
            [[touchedCell layer] renderInContext:UIGraphicsGetCurrentContext()];
            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            LLSnapShotImageView *snapShotOfMovingCell = [[LLSnapShotImageView alloc] initWithImage:image];
            CGRect snapShotFrame = [self rectForRowAtIndexPath:touchedIndexPath];
            snapShotFrame.size = cellFrame.size;
            [snapShotOfMovingCell setFrame:snapShotFrame];
            [snapShotOfMovingCell setAlpha:0.95];
            
            [self setSnapShotImageView:snapShotOfMovingCell];
            [self addSubview:[self snapShotImageView]];
            
            
            // Prepare the cell for moving (e.g. clear it's labels and imageView)
            [touchedCell prepareForMove];
            
            // Inform the delegate about the beginning of the move
            //            if ([[self delegate] respondsToSelector:@selector(moveableTableView:willMoveRowAtIndexPath:)]) {
            //                [[self delegate] moveableTableView:self willMoveRowAtIndexPath:touchedIndexPath];
            //            }
            
            // Set a threshold for autoscrolling and reset the autoscroll distance
            [self setAutoscrollThreshold:([[self snapShotImageView] frame].size.height * 0.6)];
            [self setAutoscrollDistance:0.0];
            
            break;
        }
            
        case UIGestureRecognizerStateChanged:
        {
            CGPoint touchPoint = [gestureRecognizer locationInView:self];
            
            // Update the snap shot's position
            CGPoint currentCenter = [[self snapShotImageView] center];
            [[self snapShotImageView] setCenter:CGPointMake(currentCenter.x, touchPoint.y + [self touchOffset].y)];
            
            // Check if the table view has to scroll
            [self maybeAutoscrollForSnapShotImageView:[self snapShotImageView]];
            
            // If the table view does not scroll, compute a new index path for the moving cell
            if ([self autoscrollDistance] == 0) {
                NSIndexPath *newIndexPath = [self indexPathForRowAtPoint:touchPoint];
                
                if ([self.delegate respondsToSelector:@selector(moveableTableView:targetIndexPathForMoveFromRowAtIndexPath:toProposedIndexPath:)]) {
                    newIndexPath = [self.delegate moveableTableView:self targetIndexPathForMoveFromRowAtIndexPath:self.movingIndexPath toProposedIndexPath:newIndexPath];
                }
                
                if (newIndexPath) {
                    [self moveRowToIndexPath:newIndexPath];
                }
            }
            
            break;
        }
            
        case UIGestureRecognizerStateEnded:
        {
            [self stopAutoscrolling];
            
            // Get to final index path
            CGRect finalFrame = [self rectForRowAtIndexPath:[self movingIndexPath]];
            
            // Place the snap shot to it's final position and fade it out
            
            __weak typeof(self)_self = self;
            [UIView animateWithDuration:0.2
                             animations:^{
                                 
                                 [[self snapShotImageView] setFrame:finalFrame];
                                 [[self snapShotImageView] setAlpha:1.0];
                                 
                             }
                             completion:^(BOOL finished) {
                                 
                                 if (finished)
                                 {
                                     // Clean up snap shot
                                     [[self snapShotImageView] removeFromSuperview];
                                     [self setSnapShotImageView:nil];
                                     
                                     // Reload row at moving index path to reset it's content
                                     NSIndexPath *movingIndexPath = [self movingIndexPath];
                                     if (movingIndexPath) {
                                         [self reloadRowsAtIndexPaths:[NSArray arrayWithObject:movingIndexPath]
                                                     withRowAnimation:UITableViewRowAnimationNone];
                                         [self setMovingIndexPath:nil];
                                         if (_self.delegate && [_self.delegate respondsToSelector:@selector(didEndMoveableTableView:)] ) {
                                             [_self.delegate didEndMoveableTableView:_self];
                                         }
                                     }
                                 }
                                 
                             }];
            
            break;
        }
            
        default:
        {
            // Do some cleanup if necessary
            if ([self movingIndexPath])
            {
                [self stopAutoscrolling];
                
                [[self snapShotImageView] removeFromSuperview];
                [self setSnapShotImageView:nil];
                
                NSIndexPath *movingIndexPath = [self movingIndexPath];
                [self setMovingIndexPath:nil];
                [self reloadRowsAtIndexPaths:[NSArray arrayWithObject:movingIndexPath] withRowAnimation:UITableViewRowAnimationNone];
            }
            
            break;
        }
    }
}



#pragma mark -
#pragma mark Autoscrolling

- (void)maybeAutoscrollForSnapShotImageView:(LLSnapShotImageView *)snapShot
{
    [self setAutoscrollDistance:0];
    
    if (CGRectIntersectsRect([snapShot frame], [self bounds]))
    {
        CGPoint touchLocation = [[self movingGestureRecognizer] locationInView:self];
        touchLocation.y += [self touchOffset].y;
        
        float distanceToTopEdge  = touchLocation.y - CGRectGetMinY([self bounds]);
        float distanceToBottomEdge = CGRectGetMaxY([self bounds]) - touchLocation.y;
        
        if (distanceToTopEdge < [self autoscrollThreshold])
        {
            [self setAutoscrollDistance:[self autoscrollDistanceForProximityToEdge:distanceToTopEdge] * -1];
        }
        else if (distanceToBottomEdge < [self autoscrollThreshold])
        {
            [self setAutoscrollDistance:[self autoscrollDistanceForProximityToEdge:distanceToBottomEdge]];
        }
    }
    
    if ([self autoscrollDistance] == 0)
    {
        [[self autoscrollTimer] invalidate];
        [self setAutoscrollTimer:nil];
    }
    else if (![self autoscrollTimer])
    {
        NSTimer *autoscrollTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / 60.0) target:self selector:@selector(autoscrollTimerFired:) userInfo:snapShot repeats:YES];
        [self setAutoscrollTimer:autoscrollTimer];
    }
}


- (float)autoscrollDistanceForProximityToEdge:(float)proximity
{
    return ceilf(([self autoscrollThreshold] - proximity) / 5.0);
}


- (void)legalizeAutoscrollDistance
{
    float minimumLegalDistance = [self contentOffset].y * -1;
    float maximumLegalDistance = [self contentSize].height - ([self frame].size.height + [self contentOffset].y);
    [self setAutoscrollDistance:MAX([self autoscrollDistance], minimumLegalDistance)];
    [self setAutoscrollDistance:MIN([self autoscrollDistance], maximumLegalDistance)];
}


- (void)autoscrollTimerFired:(NSTimer *)timer
{
    [self legalizeAutoscrollDistance];
    
    CGPoint contentOffset = [self contentOffset];
    contentOffset.y += [self autoscrollDistance];
    [self setContentOffset:contentOffset];
    
    // Move the snap shot appropriately
    LLSnapShotImageView *snapShot = (LLSnapShotImageView *)[timer userInfo];
    [snapShot moveByOffset:CGPointMake(0, [self autoscrollDistance])];
    
    // Even if we autoscroll we need to update the moved cell's index path
    CGPoint touchLocation = [[self movingGestureRecognizer] locationInView:self];
    NSIndexPath *newIndexPath = [self indexPathForRowAtPoint:touchLocation];
    if ([self.delegate respondsToSelector:@selector(moveableTableView:targetIndexPathForMoveFromRowAtIndexPath:toProposedIndexPath:)]) {
        newIndexPath = [self.delegate moveableTableView:self targetIndexPathForMoveFromRowAtIndexPath:self.movingIndexPath toProposedIndexPath:newIndexPath];
    }
    
    if (newIndexPath) {
        [self moveRowToIndexPath:newIndexPath];
    }
    
}


- (void)stopAutoscrolling
{
    [self setAutoscrollDistance:0];
    [[self autoscrollTimer] invalidate];
    [self setAutoscrollTimer:nil];
}

#pragma mark -
#pragma mark Accessor methods

- (void)setSnapShotImageView:(LLSnapShotImageView *)snapShotImageView
{
    if (snapShotImageView)
    {
        // Create the shadow if a new snap shot is created
        [[snapShotImageView layer] setShadowOpacity:0.7];
        [[snapShotImageView layer] setShadowRadius:3];
        [[snapShotImageView layer] setShadowOffset:CGSizeZero];
        
        CGPathRef shadowPath = [[UIBezierPath bezierPathWithRect:[[snapShotImageView layer] bounds]] CGPath];
        [[snapShotImageView layer] setShadowPath:shadowPath];
    }
    
    _snapShotImageView = snapShotImageView;
}


@end
