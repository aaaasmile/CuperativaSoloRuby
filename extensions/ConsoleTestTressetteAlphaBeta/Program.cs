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
            solver.SetHand(0, "7D, 4B, 7C, 3B, 6B, 3D, 6S, AB");
            solver.SetHand(1, "CC, AS, FS, AD, 5S, RD, 2S, 7B");
            solver.SetHand(2, "2B, CD, CB, 3S, 4C, 4S, FD, CS");
            solver.SetHand(3, "RB, RS, 5B, FB, 2D, 6D, 5D, AC");
            solver.Solve();
        }
    }
}
