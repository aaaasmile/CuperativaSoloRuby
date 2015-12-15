using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using System.Reflection;
using log4net.Config;
using System.Xml.Serialization;
using System.Diagnostics;
using System.Threading;

namespace StarterLib
{
    public class StartProcess
    {
        private static log4net.ILog _log = log4net.LogManager.GetLogger(typeof(InstallApp));

        private string _rootAppDir = CustomSettings.RootDataDir;
        public event EventHandler RunGot = delegate { };
        public event EventHandler ShutDownGot = delegate { };

        private StarterSettings _starteSettings = new StarterSettings();
        private Process _currProcess;

        public StartProcess()
        {

        }

        public void Run()
        {
            _log.Debug("Run the process");
            CheckIfAppIsInstalled();
            _starteSettings = CustomSettings.DeSerilizeFromXmlFile();
            _log.DebugFormat("Using settings {0}", CustomSettings.SerilizeToXmlString(_starteSettings));

            int restartNum = 2;
            while (restartNum > 0)
            {
                StartCuperativa();
                StartUpdater();
                bool needRestart = CheckForRestart();
                if (needRestart)
                {
                    restartNum -= 1;
                    Thread.Sleep(200);
                    _log.Debug("Application want to be restarted");
                }
                else
                {
                    break;
                }
            }
            ShutDownGot(this, null);
            _log.Debug("Application terminated");

        }

        private bool CheckForRestart()
        {
            bool restart = false;
            string str_result_fname = Path.Combine(_rootAppDir, _starteSettings.AppResultFname);
            TextReader r = null;
            try
            {
                if (File.Exists(str_result_fname))
                {
                    r = new StreamReader(str_result_fname);
                    string line = r.ReadLine();
                    _log.DebugFormat("Termination msg: {0}", line);
                    if (!string.IsNullOrEmpty(line)
                        && line.Contains("restart"))
                    {
                        restart = true;
                    }
                }
            }
            catch (Exception e)
            {
                _log.ErrorFormat("Check result failed {0}", e.Message);
            }
            finally
            {
                if (r != null) { r.Close(); }
            }
            return restart;            
        }

        private void StartCuperativa()
        {
            string str_script_start = Path.Combine(_rootAppDir, _starteSettings.GetRelStartScriptName());
            string str_cmdexe = Path.Combine(_rootAppDir, _starteSettings.CmdRubyName);
            string str_cmdoption_complete = string.Format("'{0}'", str_script_start);

            string strCompleteCmdLine = string.Format("{0} {1}", str_cmdexe, str_cmdoption_complete);
            _log.DebugFormat("Using comand: {0}", strCompleteCmdLine);

            Process myProcess = new Process();
            myProcess.StartInfo.UseShellExecute = false;
            myProcess.StartInfo.RedirectStandardOutput = true;
            myProcess.StartInfo.RedirectStandardError = true;
            myProcess.StartInfo.CreateNoWindow = true;
            myProcess.StartInfo.FileName = str_cmdexe;
            myProcess.StartInfo.Arguments = str_cmdoption_complete;
            myProcess.OutputDataReceived += new DataReceivedEventHandler(myProcess_OutputDataReceived);
            myProcess.ErrorDataReceived += new DataReceivedEventHandler(myProcess_ErrorDataReceived);
            _currProcess = myProcess;
            myProcess.Start();

            _log.DebugFormat("Cuperativa is started");
            myProcess.BeginOutputReadLine();

            long count = 0;
            do
            {
                if (count == 1) { RunGot(this, null); }
                count += 1;
            } while (!myProcess.WaitForExit(1000));
            _currProcess = null;

            myProcess.OutputDataReceived -= myProcess_OutputDataReceived;
            myProcess.ErrorDataReceived -= myProcess_ErrorDataReceived;

            _log.DebugFormat("Cuperativa exit code {0}", myProcess.ExitCode);
        }

        private void StartUpdater()
        {
            string str_script_start = Path.Combine(_rootAppDir, _starteSettings.UpdaterScript);
            string str_cmdexe = Path.Combine(_rootAppDir, _starteSettings.CmdRubyName);
            string str_cmdoption_complete = string.Format("'{0}'", str_script_start);

            Process myProcess = new Process();
            myProcess.StartInfo.UseShellExecute = false;
            myProcess.StartInfo.RedirectStandardOutput = true;
            myProcess.StartInfo.RedirectStandardError = true;
            myProcess.StartInfo.CreateNoWindow = true;
            myProcess.StartInfo.FileName = str_cmdexe;
            myProcess.StartInfo.Arguments = str_cmdoption_complete;
            myProcess.OutputDataReceived += new DataReceivedEventHandler(myProcess_OutputDataReceived);
            myProcess.ErrorDataReceived += new DataReceivedEventHandler(myProcess_ErrorDataReceived);
            _currProcess = myProcess;
            myProcess.Start();

            string strCompleteCmdLine = string.Format("{0} {1}", str_cmdexe, str_cmdoption_complete);
            _log.DebugFormat("Using comand: {0}", strCompleteCmdLine);

            _log.DebugFormat("Updater is started");
            myProcess.BeginOutputReadLine();

            do
            {

            } while (!myProcess.WaitForExit(1000));
            _currProcess = null;

            myProcess.OutputDataReceived -= myProcess_OutputDataReceived;
            myProcess.ErrorDataReceived -= myProcess_ErrorDataReceived;

            _log.DebugFormat("Updater exit code {0}", myProcess.ExitCode);
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

        private void CheckIfAppIsInstalled()
        {
            if (!File.Exists(CustomSettings.StarterSettingsFname))
            {
                _log.DebugFormat("Starter settings file not found, install app data");
                InstallApp inst = new InstallApp();
                inst.InstallMe();
            }
            else
            {
                _log.Debug("App data installation sane");
            }
        }


        public void Exit()
        {
            if (_currProcess != null)
            {
                _log.Warn("Watcher exit and process is active, kill it");
                _currProcess.Kill();
            }
        }
    }
}
