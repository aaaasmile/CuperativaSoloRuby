using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using log4net.Config;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using StarterLib;

namespace CupStarterConsoleSharp
{
    class Program
    {
        static string _consoleTitle = "CupStarter";

        static void Main(string[] args)
        {
            Console.Title = _consoleTitle;
            //HideWindow();
            string filename = Log4NetConfigFileName();
            XmlConfigurator.ConfigureAndWatch(new FileInfo(filename));

            // NOTE: uninstall is done using UnInstallSupport library
            if (args.Count() > 0 && args[0] == "InstallMe")
            {
                InstallApp inst = new InstallApp();
                inst.InstallMe();
            }
            else if (args.Count() > 0 && args[0] == "CreateXml")
            {
                InstallApp inst = new InstallApp();
                inst.CreateXmlSettings();
            }
            else
            {
                StartProcess prc = new StartProcess();
                prc.Run();
            }
        }

        [DllImport("user32.dll")]
        public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
        [DllImport("user32.dll")]
        static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
        private static void HideWindow()
        {
            IntPtr hWnd = FindWindow(null, _consoleTitle); 
            if (hWnd != IntPtr.Zero)
            {
                //Hide the window
                ShowWindow(hWnd, 0); // 0 = SW_HIDE
            }

        }

        private static string Log4NetConfigFileName()
        {
            string dir = Path.GetDirectoryName(Assembly.GetEntryAssembly().Location);
            string name = Assembly.GetEntryAssembly().GetName().Name;

            return Path.Combine(
                dir,
                name + ".Log4net.config");
        }
    }
}
