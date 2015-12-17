﻿using System;
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
        private static readonly log4net.ILog _log = log4net.LogManager.GetLogger(typeof(Program));

        static string _consoleTitle = "CupStarter";

        static void Main(string[] args)
        {
            Console.Title = _consoleTitle;
            //HideWindow(0);
            string filename = Log4NetConfigFileName();
            XmlConfigurator.ConfigureAndWatch(new FileInfo(filename));

            try
            {
                AppStarter starter = new AppStarter();
                starter.Run();
            }
            catch (Exception ex)
            {
                _log.ErrorFormat("Fatal error, please reinstall the application. {0}", ex);
                HideWindow(5);
                Console.ReadKey();
            }
            
        }

        [DllImport("user32.dll")]
        public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
        [DllImport("user32.dll")]
        static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
        private static void HideWindow(int val)
        {
            IntPtr hWnd = FindWindow(null, _consoleTitle); 
            if (hWnd != IntPtr.Zero)
            {
                ShowWindow(hWnd, val); // 0 = SW_HIDE, 5 = SW_SHOW
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
