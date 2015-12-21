using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using CupStarterConsoleSharp.Interfaces;
using Ionic.Zip;
using Microsoft.Win32;

namespace CupStarterConsoleSharp
{
    class AppStarter
    {
        private static log4net.ILog _log = log4net.LogManager.GetLogger(typeof(AppStarter));

        public event EventHandler<EventArgs> ApplicationStarting = delegate { };

        internal void Run()
        {
            CupUserSettings settings = new CupUserSettings(Registry.CurrentUser.CreateSubKey(@"Software\invido_it\Cuperativa"), isReadOnly: false);
            string installDir = settings.GetValue<string>("InstallDir", null);
            string rubyZip = settings.GetValue<string>("RubyPackage", null);
            if (!settings.GetValue<bool>("RubyPackgeUnzipped", false))
            {
                ExtractRubyPackage(installDir, rubyZip);
                settings.SetValue("RubyPackgeUnzipped", true);
            }
            AppPackageSettings appPackageSettings = new AppPackageSettings(settings);
            if (!settings.GetValue<bool>("AppPackgeUnzipped", false))
            {
                ExtractAppPackage(installDir, appPackageSettings.AppZipName, appPackageSettings.AppVersion);
                settings.SetValue("AppPackgeUnzipped", true);
            }

            string rubyExePath = GetRubyExePath(rubyZip);
            if (!File.Exists(rubyExePath)) throw (
                   new ArgumentException(string.Format("Ruby.exe  {0} not found", rubyExePath)));
            _log.InfoFormat("Ruby cmd {0}", rubyExePath);

            string startScriptFullPath = GetStartScript(appPackageSettings.AppVersion, appPackageSettings.AppStartScript);
            if (!File.Exists(startScriptFullPath)) throw (
                   new ArgumentException(string.Format("Start script  {0} not found", startScriptFullPath)));

            ProcessStarter processStarter = new ProcessStarter();
            ApplicationStarting(this, null);
            processStarter.ExecuteCmd(rubyExePath, startScriptFullPath);
        }

        private void ExtractAppPackage(string installDir, string appZip, string appVersion)
        {
            string appZipPackagePath = Path.Combine(Path.Combine(installDir, "App"), appZip);
            if (!File.Exists(appZipPackagePath)) throw (
                    new ArgumentException(string.Format("App package {0} not found", appZip)));

            string appDestinationDir = GetAppDestinationDir(appVersion);
            ExtractFiles(appZipPackagePath, appDestinationDir);
        }

        private void ExtractRubyPackage(string installDir, string rubyZip)
        {
            string rubyZipPackagePath = Path.Combine(Path.Combine(installDir, "Ruby"), rubyZip);
            if (!File.Exists(rubyZipPackagePath)) throw (
                    new ArgumentException(string.Format("Ruby package {0} not found", rubyZip)));

            string rubyDestinationDir = GetRubyDestinationDir(rubyZip);
            ExtractFiles(rubyZipPackagePath, rubyDestinationDir);
        }

        private string GetRootUnpackedData()
        {
            return Path.Combine(
                     Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                     @"invido_it\Cuperativa");
        }

        private string GetStartScript(string appVersion, string appStartScript)
        {
            return Path.Combine(
                GetAppDestinationDir(appVersion),
                string.Format(@"app/{0}", appStartScript));
        }

        private string GetAppDestinationDir(string appVersion)
        {
            return Path.Combine(GetRootUnpackedData(), appVersion);
        }

        private string GetRubyExePath(string rubyZip)
        {
            string root = GetRubyDestinationDir(rubyZip);
            return Path.Combine(root, "ruby/bin/ruby.exe");
        }

        private string GetRubyDestinationDir(string rubyZip)
        {
            return Path.Combine(GetRootUnpackedData(),
                Path.GetFileNameWithoutExtension(rubyZip));
        }

        private void ExtractFiles(string archPath, string destinationDir)
        {
            _log.InfoFormat("Extracting {0} files into {1}", archPath, destinationDir);

            using (ZipFile zipFile = new ZipFile(archPath))
                foreach (ZipEntry entry in zipFile.Entries)
                {

                    string destinationPath = Path.Combine(destinationDir, entry.FileName);
                    entry.Extract(destinationDir, ExtractExistingFileAction.OverwriteSilently);
                    _log.DebugFormat("{0} extracted", entry.FileName);
                }
        }
    }
}
