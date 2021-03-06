#import <Foundation/Foundation.h>
#import "MWMAnimator.h"

typedef void (^MWMSpringAnimationCompletionBlock) (void);

@interface MWMSpringAnimation : NSObject <Animation>

@property (nonatomic, readonly) CGPoint velocity;

+ (instancetype)animationWithView:(UIView *)view target:(CGPoint)target velocity:(CGPoint)velocity completion:(MWMSpringAnimationCompletionBlock)completion;

+ (CGFloat)approxTargetFor:(CGFloat)startValue velocity:(CGFloat)velocity;

@end
