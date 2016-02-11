using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Tre4AlphaBeta;

namespace ConsoleTestTressetteAlphaBeta
{
    class Program
    {
        static void Main(string[] args)
        {
            Program prog = new Program();

            prog.runTest();

            Console.WriteLine("Program terminated");
            Console.ReadLine();
        }

        private void runTest()
        {
            AlphaBetaSolver solver = new AlphaBetaSolver();
            // ,,,
            solver.SetHand(0, "_3c,_Ab,_4b,_Cd,_6d,_Fb,_2b,_7s,_4c,_3b");
            solver.SetHand(1, "_7c,_3d,_5b,_Ad,_2s,_Rs,_Fd,_2d,_4s,_Cb");
            solver.SetHand(2, "_3s,_6b,_5c,_5s,_Cs,_7b,_Fs,_7d,_5d,_6c");
            solver.SetHand(3, "_Rb,_Rd,_As,_Fc,_Cc,_Rc,_Ac,_6s,_4d,_2c");
            solver.Solve();
        }
    }
}
