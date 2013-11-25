//
//  Draw.h
//  plussz
//
//  Created by Dragan Petrovic on 29/10/2013.
//
//

#import <Cocoa/Cocoa.h>

struct _cocontrol ;
typedef void(*delegate_point)(struct _cocontrol* object, double x, double y);
typedef void(*delegate_count)(struct _cocontrol* object, int32_t count);

typedef enum render_t {
    PointClick,
    PointAdd,
    AnimDraw
} render_t;

@interface Draw : NSView {
    
@private
    struct _cocontrol *max_object;
    delegate_point point_function;
    delegate_count count_function;
    NSPoint             mousePoint;
    NSPoint             animPoint;
    NSMutableArray*     pointsContainer;
    CGLayerRef layer;
    NSRect oldRect;

    render_t render;
    CGContextRef g_context;
}

- (void) gotoPosition:(int32_t)position;
- (void) clear;
- (void) random:(int32_t)count;
- (void) delegate_point:(delegate_point)function
       withObject:(struct _cocontrol*)object;
- (void) delegate_count:(delegate_count)function
             withObject:(struct _cocontrol*)object;


@end
