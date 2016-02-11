// Include the Ruby headers and goodies
// this file is the extension entry point, it is intended to be compiled in mingw and not in visual studio


#ifndef _MSC_VER
// rubybinding
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
#else
// c# binding
#include "stdafx.h"
#include "RubyTre4AlphaBeta.h"

namespace Tre4AlphaBeta
{
    using namespace System;

    AlphaBetaSolver::AlphaBetaSolver()
    {
        _aBSolver = new cAlgABSolver();
        _aBSolver->InitDeck();
    }

    void AlphaBetaSolver::Solve()
    {
        _aBSolver->Solve();
    }

    void AlphaBetaSolver::SetHand(int playerIx, String^ handDescription)
    {
        int currHandIxs[searchalpha::MAXNUMTRICKS] = { -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 };
        array<String^>^ separators = gcnew array< String^ >(1);

        separators[0] = ",";
        array<String^>^ items = handDescription->Split(separators, StringSplitOptions::RemoveEmptyEntries);
        int count = 0;
        for each (String^ cdItem in items)
        {
            bool recognized = false;
            int ix = -1;
            String^ noSpace = cdItem->Trim();
            if (noSpace->Length == 2)
            {
                ix = cCardItem::SuitAndLettToIndex(noSpace[0], noSpace[1]);
                recognized = (ix >= 0 && ix < searchalpha::DECKSIZE && count < searchalpha::MAXNUMTRICKS);
            }
            if (!recognized)
                throw gcnew Exception(String::Format("invalid card item {0}", cdItem));

            currHandIxs[count] = ix;
            count++;
        }

        if (count > 0)
        {
            _aBSolver->SetHands(0, &currHandIxs[0], count);
        }

    }

}

#endif