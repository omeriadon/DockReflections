@import AppKit;
@import QuartzCore;
@import CoreImage;

#import <objc/message.h>
#import <objc/runtime.h>

static NSString *const DRReflectionName = @"com.omeriadon.DockReflections.reflection";
static NSString *const DRIndicatorFillName = @"com.omeriadon.DockReflections.indicator.fill";
static NSString *const DRIndicatorGlowName = @"com.omeriadon.DockReflections.indicator.glow";
static NSString *const DRIndicatorTransitionBlurName = @"com.omeriadon.DockReflections.indicator.transitionBlur";

static BOOL DREnabled = YES;
static BOOL DRIndicatorsEnabled = YES;
static BOOL DRReflectFolders = NO;
static BOOL DRReflectTrash = NO;
static CGFloat DRBottomInset = -5.0;
static CGFloat DRReflectionScale = 0.90;
static CGFloat DRReflectionOpacity = 1.0;
static CGFloat DRReflectionBlurRadius = 0.0;
static CGFloat DRIndicatorWidth = 12.0;
static CGFloat DRIndicatorHeight = 6.0;
static CGFloat DRIndicatorCornerRadius = 3.0;
static CGFloat DRIndicatorGlowRadius = 24.0;
static CGFloat DRIndicatorYOffset = -4.0;
static CGFloat DRIndicatorOpacity = 1.0;
static CGFloat DRIndicatorGlowOpacity = 1.0;
static NSInteger DRIndicatorGlowLayers = 6;
static CGFloat DRIndicatorEntryDuration = 0.28;
static CGFloat DRIndicatorExitDuration = 0.34;
static CGFloat DRIndicatorTransitionBlurRadius = 16.0;
static CGImageRef DRBlurredIndicatorImage = NULL;
static CGImageRef DRTransitionBlurredIndicatorImage = NULL;
static CGFloat DRBlurredIndicatorPadding = 0.0;
static CGFloat DRTransitionBlurredIndicatorPadding = 0.0;

static void (*DROriginalTileLayerLayout)(id, SEL) = NULL;
static void (*DROriginalTileRender)(id, SEL) = NULL;
static void (*DROriginalTileUpdateRect)(id, SEL) = NULL;
static void (*DROriginalAddIndicator)(id, SEL) = NULL;
static void (*DROriginalRemoveIndicator)(id, SEL) = NULL;
static float (*DROriginalTargetIndicatorOpacity)(id, SEL) = NULL;
static void (*DROriginalIndicatorSize)(id, SEL, float) = NULL;
static void (*DROriginalIndicatorBackground)(id, SEL) = NULL;

static void *DRReflectionAttachmentKey = &DRReflectionAttachmentKey;
static void *DREligibilityKey = &DREligibilityKey;
static void *DRFloorCacheKey = &DRFloorCacheKey;
static void *DRIndicatorGenerationKey = &DRIndicatorGenerationKey;
static BOOL DRRecordedRuntimeState = NO;

@interface DRReflectionAttachment : NSObject
@property (nonatomic, weak) CALayer *layer;
@property (nonatomic, strong) id sourceContents;
@property (nonatomic, assign) CGImageRef blurredContents;
@property (nonatomic) CGFloat blurPaddingPoints;
@end

@implementation DRReflectionAttachment
- (void)dealloc {
    [_layer removeFromSuperlayer];
    if (_blurredContents) CGImageRelease(_blurredContents);
}
@end


static NSUserDefaults *DRDefaults(void) {
    return [[NSUserDefaults alloc] initWithSuiteName:@"com.omeriadon.DockReflections"];
}

static double DRReadNumber(NSUserDefaults *defaults, NSString *key, double fallback) {
    id value = [defaults objectForKey:key];
    return value ? [value doubleValue] : fallback;
}

static BOOL DRReadBoolean(NSUserDefaults *defaults, NSString *key, BOOL fallback) {
    id value = [defaults objectForKey:key];
    return value ? [value boolValue] : fallback;
}

static void DRLoadConfiguration(void) {
    NSUserDefaults *defaults = DRDefaults();
    DREnabled = DRReadBoolean(defaults, @"enabled", YES);
    DRIndicatorsEnabled = DRReadBoolean(defaults, @"indicatorsEnabled", YES);
    DRReflectFolders = DRReadBoolean(defaults, @"reflectFolders", NO);
    DRReflectTrash = DRReadBoolean(defaults, @"reflectTrash", NO);
    id reflectionYOffset = [defaults objectForKey:@"reflectionYOffset"];
    DRBottomInset = reflectionYOffset ? [reflectionYOffset doubleValue]
                                      : DRReadNumber(defaults, @"bottomInset", -5.0);
    DRReflectionScale = MIN(MAX(DRReadNumber(defaults, @"reflectionScale", 0.90), 0.35), 1.0);
    DRReflectionOpacity = MIN(MAX(DRReadNumber(defaults, @"reflectionOpacity", 1.0), 0.0), 1.0);
    DRReflectionBlurRadius = MAX(0.0, DRReadNumber(defaults, @"reflectionBlurRadius", 0.0));
    DRIndicatorWidth = DRReadNumber(defaults, @"indicatorWidth", 12.0);
    DRIndicatorHeight = DRReadNumber(defaults, @"indicatorHeight", 6.0);
    DRIndicatorCornerRadius = DRReadNumber(defaults, @"indicatorCornerRadius", 3.0);
    id blurRadius = [defaults objectForKey:@"indicatorBlurRadius"];
    DRIndicatorGlowRadius = blurRadius ? [blurRadius doubleValue]
                                       : DRReadNumber(defaults, @"indicatorGlowRadius", 24.0);
    DRIndicatorYOffset = DRReadNumber(defaults, @"indicatorYOffset", -4.0);
    DRIndicatorOpacity = MIN(MAX(DRReadNumber(defaults, @"indicatorOpacity", 1.0), 0.0), 1.0);
    DRIndicatorGlowOpacity = MIN(MAX(DRReadNumber(defaults, @"indicatorGlowOpacity", 1.0), 0.0), 1.0);
    DRIndicatorGlowLayers = MIN(MAX((NSInteger)DRReadNumber(defaults, @"indicatorGlowLayers", 6), 1), 12);
    DRIndicatorEntryDuration = MAX(0.05, DRReadNumber(defaults, @"indicatorEntryDuration", 0.28));
    DRIndicatorExitDuration = MAX(0.05, DRReadNumber(defaults, @"indicatorExitDuration", 0.34));
    DRIndicatorTransitionBlurRadius = MAX(0.0, DRReadNumber(defaults, @"indicatorTransitionBlurRadius", 16.0));
}

static CALayer *DRFindNamedLayer(CALayer *parent, NSString *name) {
    for (CALayer *layer in parent.sublayers.copy) {
        if ([layer.name isEqualToString:name]) return layer;
    }
    return nil;
}

static CALayer *DRFloorLayer(CALayer *parent) {
    if (!parent) return nil;
    CALayer *cached = objc_getAssociatedObject(parent, DRFloorCacheKey);
    if (cached.superlayer == parent && [NSStringFromClass(cached.class) containsString:@"FloorLayer"]) {
        return cached;
    }

    for (CALayer *layer in parent.sublayers.copy) {
        if ([NSStringFromClass(layer.class) containsString:@"FloorLayer"]) {
            objc_setAssociatedObject(parent, DRFloorCacheKey, layer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            return layer;
        }
    }
    return nil;
}

static CALayer *DRImageLayer(CALayer *tileLayer) {
    SEL selector = NSSelectorFromString(@"imageLayer");
    if (![tileLayer respondsToSelector:selector]) return nil;
    id layer = ((id (*)(id, SEL))objc_msgSend)(tileLayer, selector);
    return [layer isKindOfClass:CALayer.class] ? layer : nil;
}

static DRReflectionAttachment *DRAttachment(CALayer *tileLayer, BOOL create) {
    DRReflectionAttachment *attachment = objc_getAssociatedObject(tileLayer, DRReflectionAttachmentKey);
    if (!attachment && create) {
        attachment = [DRReflectionAttachment new];
        objc_setAssociatedObject(tileLayer, DRReflectionAttachmentKey, attachment, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return attachment;
}

static void DRRemoveReflection(CALayer *tileLayer) {
    DRReflectionAttachment *attachment = DRAttachment(tileLayer, NO);
    [attachment.layer removeFromSuperlayer];
    attachment.layer = nil;
}

static void DRSetBlurredReflectionContents(DRReflectionAttachment *attachment,
                                           CGImageRef image) {
    if (attachment.blurredContents == image) return;
    if (attachment.blurredContents) CGImageRelease(attachment.blurredContents);
    attachment.blurredContents = image;
}

static CIContext *DRImageContext(void) {
    static CIContext *context;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        context = [CIContext contextWithOptions:nil];
    });
    return context;
}

static CGImageRef DRCreateBlurredReflectionImage(id contents,
                                                  CGRect contentsRect,
                                                  CGFloat contentsScale,
                                                  CGFloat blurRadius,
                                                  CGFloat *paddingPointsOut) CF_RETURNS_RETAINED {
    if (!contents || CFGetTypeID((__bridge CFTypeRef)contents) != CGImageGetTypeID()) return NULL;

    CGImageRef sourceImage = (__bridge CGImageRef)contents;
    CGFloat pixelWidth = CGImageGetWidth(sourceImage);
    CGFloat pixelHeight = CGImageGetHeight(sourceImage);
    if (pixelWidth <= 0.0 || pixelHeight <= 0.0) return NULL;

    if (CGRectIsEmpty(contentsRect)) contentsRect = CGRectMake(0.0, 0.0, 1.0, 1.0);
    CGRect cropRect = CGRectMake(contentsRect.origin.x * pixelWidth,
                                 contentsRect.origin.y * pixelHeight,
                                 contentsRect.size.width * pixelWidth,
                                 contentsRect.size.height * pixelHeight);
    CIImage *input = [[CIImage imageWithCGImage:sourceImage] imageByCroppingToRect:cropRect];
    input = [input imageByApplyingTransform:CGAffineTransformMakeTranslation(-cropRect.origin.x,
                                                                              -cropRect.origin.y)];

    CGFloat scale = MAX(contentsScale, 1.0);
    CGFloat blurPixels = blurRadius * scale;
    CGFloat paddingPixels = ceil(blurPixels * 3.0);
    if (paddingPointsOut) *paddingPointsOut = paddingPixels / scale;

    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setValue:input forKey:kCIInputImageKey];
    [filter setValue:@(blurPixels) forKey:kCIInputRadiusKey];
    CGRect outputRect = CGRectInset(input.extent, -paddingPixels, -paddingPixels);
    return [DRImageContext() createCGImage:filter.outputImage fromRect:outputRect];
}

static CALayer *DRCreateReflection(CALayer *tileLayer, CALayer *parent, CALayer *floor) {
    DRReflectionAttachment *attachment = DRAttachment(tileLayer, YES);
    CALayer *reflection = attachment.layer;
    if (!reflection) {
        reflection = [CALayer layer];
        reflection.name = DRReflectionName;
        reflection.opacity = DRReflectionOpacity;
        reflection.masksToBounds = NO;
        reflection.allowsGroupOpacity = NO;
        reflection.magnificationFilter = kCAFilterLinear;
        reflection.minificationFilter = kCAFilterTrilinear;
        reflection.actions = @{
            @"bounds": NSNull.null,
            @"position": NSNull.null,
            @"contents": NSNull.null,
            @"transform": NSNull.null,
            @"opacity": NSNull.null
        };
        reflection.transform = CATransform3DMakeScale(1.0, -1.0, 1.0);
        attachment.layer = reflection;
        [parent insertSublayer:reflection below:floor];
    }
    return reflection;
}

static BOOL DRLayerIsEligible(CALayer *tileLayer) {
    NSNumber *eligible = objc_getAssociatedObject(tileLayer, DREligibilityKey);
    return eligible.boolValue;
}

static void DRUpdateReflection(CALayer *tileLayer) {
    if (!DREnabled || !DRLayerIsEligible(tileLayer)) {
        DRRemoveReflection(tileLayer);
        return;
    }

    CALayer *parent = tileLayer.superlayer;
    CALayer *floor = DRFloorLayer(parent);
    CALayer *source = DRImageLayer(tileLayer);
    if (!parent || !floor || !source) return;

    DRReflectionAttachment *attachment = DRAttachment(tileLayer, NO);
    CALayer *reflection = attachment.layer;
    id contents = source.contents;
    if (!reflection && !contents) return;

    CGRect sourceFrame = [tileLayer convertRect:source.frame toLayer:parent];
    CGFloat sourceWidth = CGRectGetWidth(sourceFrame);
    CGFloat sourceHeight = CGRectGetHeight(sourceFrame);
    if (sourceWidth < 12.0 || sourceHeight < 12.0) return;

    if (!reflection) {
        reflection = DRCreateReflection(tileLayer, parent, floor);
        attachment = DRAttachment(tileLayer, NO);
    }
    if (reflection.superlayer != parent) {
        [reflection removeFromSuperlayer];
        [parent insertSublayer:reflection below:floor];
    } else {
        NSArray<CALayer *> *siblings = parent.sublayers;
        if ([siblings indexOfObjectIdenticalTo:reflection] > [siblings indexOfObjectIdenticalTo:floor]) {
            [reflection removeFromSuperlayer];
            [parent insertSublayer:reflection below:floor];
        }
    }

    CGFloat width = sourceWidth * DRReflectionScale;
    CGFloat height = sourceHeight * DRReflectionScale;
    CGRect baseFrame = CGRectMake(CGRectGetMidX(sourceFrame) - width * 0.5,
                                  CGRectGetMinY(floor.frame) + DRBottomInset,
                                  width,
                                  height);

    if (DRReflectionBlurRadius > 0.0 && contents && attachment.sourceContents != contents) {
        CGFloat paddingPoints = 0.0;
        CGImageRef blurred = DRCreateBlurredReflectionImage(contents,
                                                            source.contentsRect,
                                                            source.contentsScale,
                                                            DRReflectionBlurRadius,
                                                            &paddingPoints);
        DRSetBlurredReflectionContents(attachment, blurred);
        attachment.sourceContents = contents;
        attachment.blurPaddingPoints = paddingPoints;
    }

    BOOL usesBlurredContents = DRReflectionBlurRadius > 0.0 && attachment.blurredContents;
    CGFloat scaledPadding = usesBlurredContents
        ? attachment.blurPaddingPoints * DRReflectionScale
        : 0.0;
    CGRect frame = CGRectInset(baseFrame, -scaledPadding, -scaledPadding);
    if (!CGRectEqualToRect(reflection.frame, frame)) reflection.frame = frame;

    id displayedContents = usesBlurredContents
        ? (__bridge id)attachment.blurredContents
        : contents;
    if (displayedContents && reflection.contents != displayedContents) {
        reflection.contents = displayedContents;
        reflection.contentsScale = source.contentsScale;
        reflection.contentsRect = usesBlurredContents
            ? CGRectMake(0.0, 0.0, 1.0, 1.0)
            : source.contentsRect;
        reflection.contentsGravity = source.contentsGravity ?: kCAGravityResizeAspect;
        reflection.cornerRadius = usesBlurredContents ? 0.0 : source.cornerRadius * DRReflectionScale;
    }

    reflection.opacity = DRReflectionOpacity;
    reflection.filters = nil;
    reflection.compositingFilter = nil;

    if (!DRRecordedRuntimeState) {
        DRRecordedRuntimeState = YES;
        NSUserDefaults *diagnostics = DRDefaults();
        [diagnostics setObject:NSStringFromRect(NSRectFromCGRect(frame)) forKey:@"lastReflectionFrame"];
        [diagnostics setObject:NSStringFromRect(NSRectFromCGRect(floor.frame)) forKey:@"lastFloorFrame"];
        [diagnostics setDouble:reflection.transform.m22 forKey:@"reflectionVerticalScale"];
        NSArray<CALayer *> *siblings = parent.sublayers;
        [diagnostics setBool:([siblings indexOfObjectIdenticalTo:reflection] <
                              [siblings indexOfObjectIdenticalTo:floor])
                        forKey:@"reflectionBehindFloor"];
    }
}

static CALayer *DRTileLayerForTile(id tile) {
    Ivar ivar = class_getInstanceVariable(object_getClass(tile), "_layer");
    if (!ivar) return nil;
    id layer = object_getIvar(tile, ivar);
    return [layer isKindOfClass:CALayer.class] ? layer : nil;
}

static CALayer *DRIndicatorForTile(id tile) {
    Ivar ivar = class_getInstanceVariable(object_getClass(tile), "_indicatorLayer");
    if (!ivar) return nil;
    id layer = object_getIvar(tile, ivar);
    return [layer isKindOfClass:CALayer.class] ? layer : nil;
}

static BOOL DRTileShouldReflect(id tile) {
    NSString *className = NSStringFromClass(object_getClass(tile));
    if (!DRReflectTrash && [className containsString:@"TrashTile"]) {
        return NO;
    }
    if (!DRReflectFolders && ([className containsString:@"FolderTile"] ||
                              [className containsString:@"SmartFolderTile"])) {
        return NO;
    }

    SEL stackSelector = NSSelectorFromString(@"stack");
    if ([tile respondsToSelector:stackSelector]) {
        id stack = ((id (*)(id, SEL))objc_msgSend)(tile, stackSelector);
        if (stack && !DRReflectFolders) return NO;
    }
    return YES;
}

static CGPathRef DRTopRoundedPath(CGRect bounds, CGFloat radius) CF_RETURNS_RETAINED {
    CGFloat minX = CGRectGetMinX(bounds);
    CGFloat maxX = CGRectGetMaxX(bounds);
    CGFloat minY = CGRectGetMinY(bounds);
    CGFloat maxY = CGRectGetMaxY(bounds);
    radius = MIN(radius, MIN(CGRectGetWidth(bounds) * 0.5, CGRectGetHeight(bounds)));

    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, minX, minY);
    CGPathAddLineToPoint(path, NULL, maxX, minY);
    CGPathAddLineToPoint(path, NULL, maxX, maxY - radius);
    CGPathAddArcToPoint(path, NULL, maxX, maxY, maxX - radius, maxY, radius);
    CGPathAddLineToPoint(path, NULL, minX + radius, maxY);
    CGPathAddArcToPoint(path, NULL, minX, maxY, minX, maxY - radius, radius);
    CGPathCloseSubpath(path);
    return path;
}

static CGImageRef DRCreateBlurredIndicatorImage(CGFloat blurRadius,
                                                 CGFloat *paddingOut) CF_RETURNS_RETAINED {
    CGFloat scale = 2.0;
    blurRadius = MAX(0.0, blurRadius);
    CGFloat padding = MAX(2.0, ceil(blurRadius * 3.0));
    if (paddingOut) *paddingOut = padding;

    size_t pixelWidth = (size_t)ceil((DRIndicatorWidth + padding * 2.0) * scale);
    size_t pixelHeight = (size_t)ceil((DRIndicatorHeight + padding * 2.0) * scale);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmap = CGBitmapContextCreate(NULL,
                                                 pixelWidth,
                                                 pixelHeight,
                                                 8,
                                                 pixelWidth * 4,
                                                 colorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    if (!bitmap) return NULL;

    CGContextScaleCTM(bitmap, scale, scale);
    CGContextSetFillColorWithColor(bitmap, NSColor.whiteColor.CGColor);
    CGPathRef path = DRTopRoundedPath(CGRectMake(padding,
                                                 padding,
                                                 DRIndicatorWidth,
                                                 DRIndicatorHeight),
                                      DRIndicatorCornerRadius);
    CGContextAddPath(bitmap, path);
    CGContextFillPath(bitmap);
    CGPathRelease(path);

    CGImageRef sharpImage = CGBitmapContextCreateImage(bitmap);
    CGContextRelease(bitmap);
    if (!sharpImage) return NULL;

    CIImage *input = [CIImage imageWithCGImage:sharpImage];
    CGImageRelease(sharpImage);
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setValue:input forKey:kCIInputImageKey];
    [filter setValue:@(blurRadius * scale) forKey:kCIInputRadiusKey];
    CIImage *output = filter.outputImage;
    CIContext *context = [CIContext contextWithOptions:nil];
    return [context createCGImage:output fromRect:CGRectMake(0.0, 0.0, pixelWidth, pixelHeight)];
}

static CAShapeLayer *DRIndicatorShape(CALayer *indicator, NSString *name) {
    CAShapeLayer *shape = (CAShapeLayer *)DRFindNamedLayer(indicator, name);
    if (!shape) {
        shape = [CAShapeLayer layer];
        shape.name = name;
        shape.actions = @{
            @"bounds": NSNull.null,
            @"position": NSNull.null,
            @"path": NSNull.null,
            @"opacity": NSNull.null
        };
        [indicator addSublayer:shape];
    }
    return shape;
}

static void DRAnimateLayerOpacityKeyframes(CALayer *layer,
                                           NSArray<NSNumber *> *values,
                                           NSArray<NSNumber *> *keyTimes,
                                           CGFloat modelOpacity,
                                           CFTimeInterval duration) {
    [layer removeAnimationForKey:@"com.omeriadon.DockReflections.opacity"];
    layer.opacity = modelOpacity;
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    animation.values = values;
    animation.keyTimes = keyTimes;
    animation.duration = duration;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.fillMode = kCAFillModeBackwards;
    [layer addAnimation:animation forKey:@"com.omeriadon.DockReflections.opacity"];
}

static void DRAnimateIndicatorEntry(CALayer *indicator) {
    CALayer *transitionBlur = DRFindNamedLayer(indicator, DRIndicatorTransitionBlurName);
    if (transitionBlur) {
        DRAnimateLayerOpacityKeyframes(transitionBlur,
                                       @[@0.0, @1.0, @0.0, @0.0],
                                       @[@0.0, @0.18, @0.78, @1.0],
                                       0.0,
                                       DRIndicatorEntryDuration);
    }

    CAShapeLayer *fill = (CAShapeLayer *)DRFindNamedLayer(indicator, DRIndicatorFillName);
    if (fill) {
        DRAnimateLayerOpacityKeyframes(fill,
                                       @[@0.0, @0.0, @(DRIndicatorOpacity * 0.2), @(DRIndicatorOpacity)],
                                       @[@0.0, @0.55, @0.75, @1.0],
                                       DRIndicatorOpacity,
                                       DRIndicatorEntryDuration);
    }

    for (NSInteger index = 0; index < DRIndicatorGlowLayers; index++) {
        NSString *name = [NSString stringWithFormat:@"%@.%ld", DRIndicatorGlowName, (long)index];
        CALayer *glow = DRFindNamedLayer(indicator, name);
        if (glow) {
            DRAnimateLayerOpacityKeyframes(glow,
                                           @[@0.0,
                                             @(DRIndicatorGlowOpacity * 0.25),
                                             @(DRIndicatorGlowOpacity)],
                                           @[@0.0, @0.45, @1.0],
                                           DRIndicatorGlowOpacity,
                                           DRIndicatorEntryDuration);
        }
    }
}

static void DRAnimateIndicatorExit(CALayer *indicator) {
    CALayer *transitionBlur = DRFindNamedLayer(indicator, DRIndicatorTransitionBlurName);
    if (transitionBlur) {
        DRAnimateLayerOpacityKeyframes(transitionBlur,
                                       @[@0.0, @1.0, @1.0, @0.0],
                                       @[@0.0, @0.28, @0.68, @1.0],
                                       0.0,
                                       DRIndicatorExitDuration);
    }

    CAShapeLayer *fill = (CAShapeLayer *)DRFindNamedLayer(indicator, DRIndicatorFillName);
    if (fill) {
        CALayer *presentation = (CALayer *)fill.presentationLayer;
        CGFloat current = presentation ? presentation.opacity : fill.opacity;
        DRAnimateLayerOpacityKeyframes(fill,
                                       @[@(current), @(current * 0.65), @(current * 0.15), @0.0],
                                       @[@0.0, @0.35, @0.68, @1.0],
                                       0.0,
                                       DRIndicatorExitDuration);
    }

    for (NSInteger index = 0; index < DRIndicatorGlowLayers; index++) {
        NSString *name = [NSString stringWithFormat:@"%@.%ld", DRIndicatorGlowName, (long)index];
        CALayer *glow = DRFindNamedLayer(indicator, name);
        if (glow) {
            CALayer *presentation = (CALayer *)glow.presentationLayer;
            CGFloat current = presentation ? presentation.opacity : glow.opacity;
            DRAnimateLayerOpacityKeyframes(glow,
                                           @[@(current),
                                             @(DRIndicatorGlowOpacity),
                                             @(DRIndicatorGlowOpacity * 0.7),
                                             @0.0],
                                           @[@0.0, @0.28, @0.68, @1.0],
                                           0.0,
                                           DRIndicatorExitDuration);
        }
    }
}

static void DRReplaceIndicator(CALayer *indicator) {
    if (!DRIndicatorsEnabled || !indicator) return;
    CALayer *floor = DRFloorLayer(indicator.superlayer);
    if (!floor) return;

    NSMutableSet<NSString *> *validGlowNames = [NSMutableSet setWithCapacity:DRIndicatorGlowLayers];
    for (NSInteger index = 0; index < DRIndicatorGlowLayers; index++) {
        [validGlowNames addObject:[NSString stringWithFormat:@"%@.%ld", DRIndicatorGlowName, (long)index]];
    }
    for (CALayer *sublayer in indicator.sublayers.copy) {
        if (![sublayer.name isEqualToString:DRIndicatorFillName] &&
            ![sublayer.name isEqualToString:DRIndicatorTransitionBlurName] &&
            ![validGlowNames containsObject:sublayer.name]) {
            [sublayer removeFromSuperlayer];
        }
    }

    indicator.contents = nil;
    indicator.backgroundColor = NSColor.clearColor.CGColor;
    indicator.borderWidth = 0.0;
    indicator.filters = nil;
    indicator.compositingFilter = nil;
    indicator.shadowOpacity = 0.0;
    indicator.masksToBounds = NO;

    CGFloat localX = (CGRectGetWidth(indicator.bounds) - DRIndicatorWidth) * 0.5;
    CGFloat floorYInIndicator = CGRectGetMinY(floor.frame) - CGRectGetMinY(indicator.frame);
    CGFloat localY = floorYInIndicator + DRIndicatorYOffset;
    CGRect shapeFrame = CGRectMake(localX, localY, DRIndicatorWidth, DRIndicatorHeight);
    CGPathRef fillPath = DRTopRoundedPath(CGRectMake(0.0, 0.0, DRIndicatorWidth, DRIndicatorHeight),
                                          DRIndicatorCornerRadius);

    if (!DRTransitionBlurredIndicatorImage) {
        DRTransitionBlurredIndicatorImage = DRCreateBlurredIndicatorImage(
            DRIndicatorTransitionBlurRadius,
            &DRTransitionBlurredIndicatorPadding
        );
    }
    CAShapeLayer *transitionBlur = DRIndicatorShape(indicator, DRIndicatorTransitionBlurName);
    transitionBlur.frame = CGRectInset(shapeFrame,
                                       -DRTransitionBlurredIndicatorPadding,
                                       -DRTransitionBlurredIndicatorPadding);
    transitionBlur.path = nil;
    transitionBlur.fillColor = NSColor.clearColor.CGColor;
    transitionBlur.contents = (__bridge id)DRTransitionBlurredIndicatorImage;
    transitionBlur.contentsScale = 2.0;
    transitionBlur.contentsGravity = kCAGravityResize;
    transitionBlur.opacity = 0.0;
    transitionBlur.filters = nil;
    transitionBlur.shadowOpacity = 0.0;
    transitionBlur.shadowPath = nil;
    transitionBlur.mask = nil;

    if (!DRBlurredIndicatorImage) {
        DRBlurredIndicatorImage = DRCreateBlurredIndicatorImage(DRIndicatorGlowRadius,
                                                                &DRBlurredIndicatorPadding);
    }
    for (NSInteger index = 0; index < DRIndicatorGlowLayers; index++) {
        NSString *name = [NSString stringWithFormat:@"%@.%ld", DRIndicatorGlowName, (long)index];
        CAShapeLayer *glow = DRIndicatorShape(indicator, name);
        glow.frame = CGRectInset(shapeFrame, -DRBlurredIndicatorPadding, -DRBlurredIndicatorPadding);
        glow.path = nil;
        glow.fillColor = NSColor.clearColor.CGColor;
        glow.contents = (__bridge id)DRBlurredIndicatorImage;
        glow.contentsScale = 2.0;
        glow.contentsGravity = kCAGravityResize;
        glow.opacity = DRIndicatorGlowOpacity;
        glow.filters = nil;
        glow.shadowOpacity = 0.0;
        glow.shadowPath = nil;
        glow.mask = nil;
    }

    CAShapeLayer *fill = DRIndicatorShape(indicator, DRIndicatorFillName);
    fill.frame = shapeFrame;
    fill.path = fillPath;
    fill.fillColor = NSColor.whiteColor.CGColor;
    fill.opacity = DRIndicatorOpacity;
    fill.filters = nil;
    fill.shadowOpacity = 0.0;
    fill.mask = nil;
    CGPathRelease(fillPath);
}

static void DRTileLayerLayout(id self, SEL _cmd) {
    if (DROriginalTileLayerLayout) DROriginalTileLayerLayout(self, _cmd);
    DRUpdateReflection((CALayer *)self);
}

static void DRMarkTileAndInitializeReflection(id tile) {
    CALayer *tileLayer = DRTileLayerForTile(tile);
    if (!tileLayer) return;
    NSNumber *knownEligibility = objc_getAssociatedObject(tileLayer, DREligibilityKey);
    if (!knownEligibility) {
        BOOL eligible = DRTileShouldReflect(tile);
        objc_setAssociatedObject(tileLayer, DREligibilityKey, @(eligible), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        if (!eligible) {
            DRRemoveReflection(tileLayer);
            return;
        }
    }
    if ([objc_getAssociatedObject(tileLayer, DREligibilityKey) boolValue]) {
        DRUpdateReflection(tileLayer);
    }
}

static void DRTileRender(id self, SEL _cmd) {
    if (DROriginalTileRender) DROriginalTileRender(self, _cmd);
    DRMarkTileAndInitializeReflection(self);
}

static void DRTileUpdateRect(id self, SEL _cmd) {
    if (DROriginalTileUpdateRect) DROriginalTileUpdateRect(self, _cmd);
    DRMarkTileAndInitializeReflection(self);
}

static void DRTileAddIndicator(id self, SEL _cmd) {
    NSUInteger generation = [objc_getAssociatedObject(self, DRIndicatorGenerationKey) unsignedIntegerValue] + 1;
    objc_setAssociatedObject(self, DRIndicatorGenerationKey, @(generation), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (DROriginalAddIndicator) DROriginalAddIndicator(self, _cmd);
    CALayer *indicator = DRIndicatorForTile(self);
    DRReplaceIndicator(indicator);
    DRAnimateIndicatorEntry(indicator);
}

static float DRTileTargetIndicatorOpacity(id self, SEL _cmd) {
    float originalTarget = DROriginalTargetIndicatorOpacity
        ? DROriginalTargetIndicatorOpacity(self, _cmd)
        : 1.0f;
    return originalTarget <= 0.001f ? 0.0f : 1.0f;
}

static void DRTileRemoveIndicator(id self, SEL _cmd) {
    NSUInteger generation = [objc_getAssociatedObject(self, DRIndicatorGenerationKey) unsignedIntegerValue] + 1;
    objc_setAssociatedObject(self, DRIndicatorGenerationKey, @(generation), OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    CALayer *indicator = DRIndicatorForTile(self);
    if (!indicator) {
        if (DROriginalRemoveIndicator) DROriginalRemoveIndicator(self, _cmd);
        return;
    }

    [DRDefaults() setObject:NSDate.date forKey:@"lastIndicatorExitStartDate"];
    DRAnimateIndicatorExit(indicator);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(DRIndicatorExitDuration * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        NSUInteger current = [objc_getAssociatedObject(self, DRIndicatorGenerationKey) unsignedIntegerValue];
        if (current == generation && DROriginalRemoveIndicator) {
            DROriginalRemoveIndicator(self, NSSelectorFromString(@"removeIndicator"));
            [DRDefaults() setObject:NSDate.date forKey:@"lastIndicatorRemovedDate"];
        }
    });
}

static void DRIndicatorUpdateSize(id self, SEL _cmd, float size) {
    if (DROriginalIndicatorSize) DROriginalIndicatorSize(self, _cmd, size);
    DRReplaceIndicator((CALayer *)self);
}

static void DRIndicatorDockBackgroundChanged(id self, SEL _cmd) {
    if (DROriginalIndicatorBackground) DROriginalIndicatorBackground(self, _cmd);
    DRReplaceIndicator((CALayer *)self);
}

static IMP DRReplaceOwnedMethod(Class cls, SEL selector, IMP replacement) {
    unsigned int count = 0;
    Method *methods = class_copyMethodList(cls, &count);
    Method owned = NULL;
    for (unsigned int index = 0; index < count; index++) {
        if (method_getName(methods[index]) == selector) {
            owned = methods[index];
            break;
        }
    }
    free(methods);
    return owned ? method_setImplementation(owned, replacement) : NULL;
}

static void DRInstallHooks(void) {
    Class tileLayerClass = NSClassFromString(@"DOCKTileLayer");
    DROriginalTileLayerLayout = (void (*)(id, SEL))DRReplaceOwnedMethod(tileLayerClass,
                                                                        @selector(layoutSublayers),
                                                                        (IMP)DRTileLayerLayout);

    Class tileClass = NSClassFromString(@"Tile");
    DROriginalTileRender = (void (*)(id, SEL))DRReplaceOwnedMethod(tileClass,
                                                                   NSSelectorFromString(@"render"),
                                                                   (IMP)DRTileRender);
    DROriginalTileUpdateRect = (void (*)(id, SEL))DRReplaceOwnedMethod(tileClass,
                                                                       NSSelectorFromString(@"updateRect"),
                                                                       (IMP)DRTileUpdateRect);
    DROriginalAddIndicator = (void (*)(id, SEL))DRReplaceOwnedMethod(tileClass,
                                                                     NSSelectorFromString(@"addIndicator"),
                                                                     (IMP)DRTileAddIndicator);
    DROriginalRemoveIndicator = (void (*)(id, SEL))DRReplaceOwnedMethod(tileClass,
                                                                        NSSelectorFromString(@"removeIndicator"),
                                                                        (IMP)DRTileRemoveIndicator);
    DROriginalTargetIndicatorOpacity = (float (*)(id, SEL))DRReplaceOwnedMethod(tileClass,
                                                                                NSSelectorFromString(@"targetIndicatorOpacity"),
                                                                                (IMP)DRTileTargetIndicatorOpacity);

    Class indicatorClass = NSClassFromString(@"DOCKIndicatorLayer");
    DROriginalIndicatorSize = (void (*)(id, SEL, float))DRReplaceOwnedMethod(indicatorClass,
                                                                             NSSelectorFromString(@"updateIndicatorForSize:"),
                                                                             (IMP)DRIndicatorUpdateSize);
    DROriginalIndicatorBackground = (void (*)(id, SEL))DRReplaceOwnedMethod(indicatorClass,
                                                                            NSSelectorFromString(@"dockBackgroundChanged"),
                                                                            (IMP)DRIndicatorDockBackgroundChanged);

    NSUserDefaults *diagnostics = DRDefaults();
    [diagnostics setObject:NSDate.date forKey:@"lastHookDate"];
    [diagnostics setBool:(DROriginalTileLayerLayout != NULL) forKey:@"tileLayerHookInstalled"];
    [diagnostics setBool:(DROriginalTileRender != NULL) forKey:@"tileRenderHookInstalled"];
    [diagnostics setBool:(DROriginalTileUpdateRect != NULL) forKey:@"tileUpdateRectHookInstalled"];
    [diagnostics setBool:(DROriginalAddIndicator != NULL) forKey:@"indicatorReplacementInstalled"];
    [diagnostics setBool:(DROriginalRemoveIndicator != NULL) forKey:@"indicatorRemovalHookInstalled"];
    [diagnostics setBool:(DROriginalTargetIndicatorOpacity != NULL) forKey:@"indicatorTargetHookInstalled"];
    [diagnostics setBool:(DROriginalIndicatorSize != NULL) forKey:@"indicatorSizeHookInstalled"];
}

@interface DockReflectionsLoader : NSObject
@end


@implementation DockReflectionsLoader
+ (void)load {
    if (![NSProcessInfo.processInfo.processName isEqualToString:@"Dock"]) return;
    DRLoadConfiguration();
    dispatch_async(dispatch_get_main_queue(), ^{
        DRInstallHooks();
    });
}
@end
