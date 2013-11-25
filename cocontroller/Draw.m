//
//  Draw.m
//  plussz
//
//  Created by Dragan Petrovic on 29/10/2013.
//
//

#import "Draw.h"


@implementation Draw

- (BOOL) becomeFirstResponder {
    return YES;
}

- (void) dealloc {
    [pointsContainer removeAllObjects];
    [pointsContainer release];
    pointsContainer = nil;
    [super dealloc];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        srand (time(NULL));
        g_context = NULL;
        layer = NULL;
        mousePoint = NSMakePoint(-9999, -9999);
        [self setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        pointsContainer = [[NSMutableArray alloc] initWithCapacity:9999];
        oldRect = frame;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
    
	[[NSColor lightGrayColor] setFill];
    NSRectFill(dirtyRect);
    
    if(!NSPointInRect(mousePoint, dirtyRect) || pointsContainer.count == 0) {
        return;
    }
    
    // Drawing code here.
//    NSString* str = [NSString stringWithFormat:@"%.f %.f", mousePoint.x, mousePoint.y];
//    NSSize size = [str sizeWithAttributes:nil];
//    [str drawAtPoint:NSMakePoint(1, dirtyRect.size.height - size.height) withAttributes:nil];
    
    if(!g_context) {
        g_context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    }
    if(!layer) {
        layer = CGLayerCreateWithContext(g_context, NSSizeToCGSize(dirtyRect.size), NULL);
    }
    
    CGSize newSize = CGSizeZero;
    switch(render) {
            
        case PointClick:
            newSize = CGSizeMake(oldRect.size.width/dirtyRect.size.width, oldRect.size.height/dirtyRect.size.height);
            CGContextScaleCTM(g_context, newSize.width, newSize.height);
            [self drawClickPoint:g_context];
            [self renderContainerPointsAndLines:g_context];
            CGContextDrawLayerAtPoint(g_context, CGPointZero, layer);
            break;
            
        case PointAdd:
            break;
          
        case AnimDraw:
            newSize = CGSizeMake(oldRect.size.width/dirtyRect.size.width, oldRect.size.height/dirtyRect.size.height);
            CGContextDrawLayerAtPoint(g_context, CGPointZero, layer);
            [self animPoint:g_context];
            break;
    }
    
    oldRect = dirtyRect;
}

- (void) animPoint:(CGContextRef)context {
    CGContextSaveGState(context);
    CGContextSetStrokeColorWithColor(context, [NSColor colorWithCalibratedRed:1 green:0 blue:0 alpha:0.5].CGColor);
    CGContextSetLineWidth(context, 3);
    CGFloat r = 10.0;
    CGRect newRect = CGRectMake(animPoint.x-r, animPoint.y-r, r*2, r*2);
    CGContextStrokeEllipseInRect(context, newRect);
    CGContextRestoreGState(context);
}

- (void) drawClickPoint:(CGContextRef)context {
    CGContextSaveGState(context);
    CGContextSetFillColorWithColor(context, [NSColor colorWithCalibratedRed:1 green:0 blue:0 alpha:0.8].CGColor);
    CGFloat r = 4.0;
    CGRect newRect = CGRectMake(mousePoint.x-r, mousePoint.y-r, r*2, r*2);
    CGContextFillEllipseInRect(context, newRect);
    CGContextRestoreGState(context);
}

- (void) renderContainerPointsAndLines:(CGContextRef)context_ {
    
    CGContextRef context = CGLayerGetContext(layer);
    CGContextSetLineWidth(context, 0.5);
    NSPoint point = [[pointsContainer objectAtIndex:0] pointValue];
    CGContextMoveToPoint(context, point.x, point.y);
    CGContextSetStrokeColorWithColor(context, [NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0.5].CGColor);
    
    [pointsContainer enumerateObjectsUsingBlock:^(NSValue* obj, NSUInteger idx, BOOL *stop) {
        NSPoint point = [obj pointValue];
        CGFloat r = 8.0;
        
        //Lines
        CGContextAddLineToPoint(context, point.x, point.y);
        
        //Points
        CGLayerRef p_layer = CGLayerCreateWithContext(context, CGSizeMake(r*2, r*2), NULL);
        CGContextRef p_context = CGLayerGetContext(p_layer);
        CGContextSetFillColorWithColor(p_context, [NSColor colorWithCalibratedRed:0 green:0 blue:1 alpha:0.5].CGColor);
        CGRect newRect = CGRectMake(0, 0, r*2, r*2);
        CGContextFillEllipseInRect(p_context, newRect);
        CGContextDrawLayerAtPoint(context, CGPointMake(point.x-r, point.y-r), p_layer);
        CGLayerRelease(p_layer);
    }];
    
    CGContextStrokePath(context);
}

- (void) gotoPosition:(int32_t)position {
    if(position < 0 || pointsContainer.count < 1) {
        return;
    }
    animPoint = [[pointsContainer objectAtIndex:position] pointValue];
    point_function(max_object, animPoint.x, animPoint.y);
    render = AnimDraw;
    [self setNeedsDisplay:YES];
}

- (void) clear {
    [pointsContainer removeAllObjects];
    if(layer) {
        CGLayerRelease(layer);
        layer = NULL;
    }
    count_function(max_object, pointsContainer.count);
    mousePoint = NSMakePoint(-9999, -9999);
    [self setNeedsDisplay:YES];
}

- (void) random:(int32_t)count {
    
    CGFloat (^Random)(CGFloat max) = ^CGFloat(CGFloat max) {
        return (rand()/(CGFloat)RAND_MAX)*max;
    };
    
    for(int i = 0; i < count; ++i) {
        mousePoint = NSMakePoint(Random(CGRectGetWidth(NSRectToCGRect(self.bounds))),
                                 Random(CGRectGetHeight(NSRectToCGRect(self.bounds))));
        if(NSPointInRect(mousePoint, self.bounds)) {
            [pointsContainer addObject:[NSValue valueWithPoint:mousePoint]];
        }
    }
    
    count_function(max_object, pointsContainer.count);
    render = PointClick;
    [self setNeedsDisplay:YES];
}

- (void) delegate_point:(delegate_point)function
             withObject:(struct _cocontrol*)object {
    max_object = object;
    point_function = function;
}

- (void) delegate_count:(delegate_count)function
             withObject:(struct _cocontrol*)object {
    max_object = object;
    count_function = function;
}

- (void) mouseDown: (NSEvent *) event {
    mousePoint = [self convertPoint:[event locationInWindow] fromView:nil];
    if(NSPointInRect(mousePoint, self.bounds)) {
        [pointsContainer addObject:[NSValue valueWithPoint:mousePoint]];
        count_function(max_object, pointsContainer.count);
        render = PointClick;
        [self setNeedsDisplay:YES];
    }
}

- (void) mouseDragged: (NSEvent *) event {
    return;
    mousePoint = [self convertPoint:[event locationInWindow] fromView:nil];
    if(NSPointInRect(mousePoint, self.bounds)) {
        [pointsContainer addObject:[NSValue valueWithPoint:mousePoint]];
        count_function(max_object, pointsContainer.count);
        render = PointClick;
        [self setNeedsDisplay:YES];
    }
}

- (BOOL) inLiveResize {
    [self setNeedsDisplay:YES];
    return YES;
}

@end
