using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Diagnostics;
using System.Threading;


namespace CupStarterConsoleSharp
{
    class ProcessStarter
    {
        private static log4net.ILog _log = log4net.LogManager.GetLogger(typeof(ProcessStarter));

        internal void ExecuteCmd(string rubyExe, string startScript)
        {
            string cmdoptionComplete = string.Format("'{0}'", startScript);

            _log.InfoFormat("Using comand: {0} {1}", rubyExe, cmdoptionComplete);

            Process myProcess = new Process();
            myProcess.StartInfo.UseShellExecute = false;
            myProcess.StartInfo.RedirectStandardOutput = true;
            myProcess.StartInfo.RedirectStandardError = true;
            myProcess.StartInfo.CreateNoWindow = true;
            myProcess.StartInfo.FileName = rubyExe;
            myProcess.StartInfo.Arguments = cmdoptionComplete;
            myProcess.OutputDataReceived += new DataReceivedEventHandler(myProcess_OutputDataReceived);
            myProcess.ErrorDataReceived += new DataReceivedEventHandler(myProcess_ErrorDataReceived);
            myProcess.Start();
            _log.InfoFormat("Ruby process is started");
            myProcess.BeginOutputReadLine();

            do
            {

            } while (!myProcess.WaitForExit(1000));


            myProcess.OutputDataReceived -= myProcess_OutputDataReceived;
            myProcess.ErrorDataReceived -= myProcess_ErrorDataReceived;

            _log.DebugFormat("Application exit code {0}", myProcess.ExitCode);

        }

        void myProcess_ErrorDataReceived(object sender, DataReceivedEventArgs e)
        {
            if (!String.IsNullOrEmpty(e.Data))
            {
                _log.ErrorFormat("STDERR: {0}", e.Data);
            }
        }

        void myProcess_OutputDataReceived(object sender, DataReceivedEventArgs e)
        {
            if (!String.IsNullOrEmpty(e.Data))
            {
                _log.DebugFormat("STDOUT: {0}", e.Data);
            }
        }
    }
}
