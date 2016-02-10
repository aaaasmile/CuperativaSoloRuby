// File: RubyTre4AlphaBeta.h

#ifndef _RUBY_TRE4_ALPHA_BETA__H
#define _RUBY_TRE4_ALPHA_BETA__H

#ifndef _MSC_VER
extern "C" {
    void Init_RubyTre4AlphaBeta();
}

#else

#include "cAlgABSolver.h"

namespace Tre4AlphaBeta
{
    public ref class AlphaBetaSolver
    {
    public:
        AlphaBetaSolver();
        void Solve();


    private:
        cAlgABSolver*  _aBSolver;
    };
}

#endif

#endif
