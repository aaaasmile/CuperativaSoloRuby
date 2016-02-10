// Include the Ruby headers and goodies
// this file is the extension entry point, it is intended to be compiled in mingw and not in visual studio
#ifndef _MSC_VER

#include "ruby.h"
#include "RubyTre4AlphaBeta.h"

// compiled with ruby 1.8.7 (2010-08-16 patchlevel 302) [i386-mingw32]

// Defining a space for information and references about the module to be stored internally
VALUE RubyTre4AlphaBeta = Qnil;

// Prototype for the initialization method - Ruby calls this, not you
void Init_RubyTre4AlphaBeta();

// Prototype for our method 'test1' - methods are prefixed by 'method_' here
VALUE method_test1(ANYARGS);

// The initialization method for this module
void Init_RubyTre4AlphaBeta() {
    RubyTre4AlphaBeta = rb_define_module("RubyTre4AlphaBeta");
    rb_define_method(RubyTre4AlphaBeta, "test1", method_test1, 0);
}

// Our 'test1' method.. it simply returns a value of '10' for now.
VALUE method_test1(ANYARGS) {
    int x = 10;
    return INT2NUM(x);
}
#endif