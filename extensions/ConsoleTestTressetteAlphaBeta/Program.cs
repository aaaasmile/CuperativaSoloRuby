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

            Console.ReadLine();
        }

        private void runTest()
        {
            AlphaBetaSolver solver = new AlphaBetaSolver();
            solver.Solve();
        }
    }
}
