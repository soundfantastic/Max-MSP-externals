/**
	@file
	cocontrol.c - Objective-C NSPanel&NSView based controller
*/

#include "ext.h"
#include "ext_obex.h"
#import "Draw.h"

typedef struct _cocontrol {
	t_object p_ob;
	long point_index;
    long total_points;
    void *x_outlet;
    void *y_outlet;
    void *count_outlet;
    NSPanel* panel;
    Draw*   drawView;
} t_cocontrol;


// these are prototypes for the methods that are defined below
void cocontrol_list(t_cocontrol *x, t_symbol *msg, long argc, t_atom *argv);
void cocontrol_bang(t_cocontrol *x);
void cocontrol_left_inlet(t_cocontrol *x, long n);
void cocontrol_assist(t_cocontrol *x, void *b, long m, long a, char *s);
void *cocontrol_new(long n);
void cocontrol_free(t_cocontrol *x);
void cocontrol_dblclick(t_cocontrol *x);
t_class *cocontrol_class;		// global pointer to the object class - so max can reference the object


//--------------------------------------------------------------------------

int C74_EXPORT main(void) {
	t_class *c;
	
	c = class_new("cocontrol", (method)cocontrol_new, (method)cocontrol_free, sizeof(t_cocontrol), 0L, A_DEFLONG, 0);
	
    class_addmethod(c, (method)cocontrol_bang,          "bang",		0);
    class_addmethod(c, (method)cocontrol_left_inlet,	"int",		A_LONG, 0);
    class_addmethod(c, (method)cocontrol_dblclick,      "dblclick",	A_CANT, 0);
    class_addmethod(c, (method)cocontrol_list,          "anything", A_GIMME, 0);
    class_addmethod(c, (method)cocontrol_assist,        "assist",	A_CANT, 0);
	
	class_register(CLASS_BOX, c);
	cocontrol_class = c;

	post("cocontrol loaded...",0);
	return 0;
}

//--------------------------------------------------------------------------
//private delegate functions
void point_delegate(t_cocontrol *x, double xpos, double ypos) {
    outlet_float(x->x_outlet, xpos);
    outlet_float(x->y_outlet, ypos);
}

void position_delegate(t_cocontrol *x, int32_t count) {
    x->total_points = count;
    outlet_int(x->count_outlet, x->total_points);
}

//
void cocontrol_free(t_cocontrol *x) {
    [x->drawView release];
    x->drawView = nil;
    [x->panel release];
    x->panel = nil;
}

void* cocontrol_new(long n)	 {
	t_cocontrol *x;
	x = (t_cocontrol*)object_alloc(cocontrol_class);
	intin(x, 1);
    x->count_outlet = intout(x);
    x->y_outlet = floatout(x);
	x->x_outlet = floatout(x);
    x->total_points = 0;
	x->point_index	= 0;
	
	post(" new cocontrol object instance added to patch...",0);
    
    int style =  NSTitledWindowMask | NSClosableWindowMask | NSResizableWindowMask | NSUtilityWindowMask;
    x->panel = [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, 200, 200)
                                            styleMask:style
                                              backing:NSBackingStoreBuffered
                                              defer:NO];
    
    [x->panel setTitle:@"cocontrol"];
    [x->panel setFloatingPanel:YES];
    NSView* mainView = x->panel.contentView;
    x->drawView = [[Draw alloc] initWithFrame:mainView.frame];
    [x->drawView delegate_point:point_delegate withObject:x];
    [x->drawView delegate_count:position_delegate withObject:x];
    [mainView addSubview:x->drawView];
    
    [x->panel makeKeyAndOrderFront:NSApp];
	
	return(x);					// return a reference to the object instance 
}


//--------------------------------------------------------------------------

void cocontrol_dblclick(t_cocontrol *x) {
    if(![x->panel isVisible]) {
        [x->panel makeKeyAndOrderFront:NSApp];
    }
}

void cocontrol_assist(t_cocontrol *x, void *b, long m, long a, char *s) {
	if (m == ASSIST_OUTLET)
        switch (a) {
            case 0:
                sprintf(s,"X output");
                break;
            case 1:
                sprintf(s,"Y output");
                break;
            case 2:
                sprintf(s,"Total points output");
                break;
        }
	else {
		switch (a) {	
		case 0:
			sprintf(s,"Inlet %ld: Counter (Max = total points output - 1)", a);
			break;
		}
	}
}

void cocontrol_list(t_cocontrol *x, t_symbol *s, long argc, t_atom *argv) {
    t_atom *atom = 0;
    if(!strcmp(s->s_name, "clear")) {
        [x->drawView clear];
        return;
    }
    else if(!strcmp(s->s_name, "random")) {
        atom = argv;
        long maxValue = atom_getlong(atom);
        if(maxValue < 1) {
            maxValue = 1;
        }
        [x->drawView random:maxValue];
        return;
    }
    else if(!strcmp(s->s_name, "count")) {
        outlet_int(x->count_outlet, x->total_points);
        return;
    }
}

void cocontrol_bang(t_cocontrol *x)	{

}

void cocontrol_left_inlet(t_cocontrol *x, long n) {
	x->point_index = n;
    [x->drawView gotoPosition:x->point_index];
}

