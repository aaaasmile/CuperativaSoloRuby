using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Ionic.Zip;
using System.IO;
using System.Reflection;

namespace StarterLib
{
    public class InstallApp
    {
        private static log4net.ILog _log = log4net.LogManager.GetLogger(typeof(InstallApp));
        private StarterSettings _starteSettings = new StarterSettings();

        public void InstallMe()
        {
            _log.Debug("Install application");
            if (CustomSettings.CheckOrCreateRootKey())
            {
                string exeDir = Path.GetDirectoryName(Assembly.GetEntryAssembly().Location);
                string zipFileName = Path.Combine(exeDir, CustomSettings.AppDataFilename);
                if (!File.Exists(zipFileName))
                {
                    _log.ErrorFormat("Zip file {0} not found", zipFileName);
                }
                else
                {
                    using (ZipFile zipFile = new ZipFile(zipFileName))
                    {
                        ExtractFiles(zipFile);
                    }
                    CustomSettings.SerilizeToXmlFile(new StarterSettings());
                }
            }
            else
            {
                _log.ErrorFormat("Unable to access User Application data directory, install failed");
            }
        }

        public void CreateXmlSettings()
        {
            _log.Debug("Create settings file");
            if (CustomSettings.CheckOrCreateRootKey())
            {
                CustomSettings.SerilizeToXmlFile(new StarterSettings());
            }
            else
            {
                _log.ErrorFormat("Unable to access User Application data directory");
            }
        }

        private void ExtractFiles(ZipFile zipFile)
        {
            _log.Info("Extracting application files");
            string extractToDir = CustomSettings.RootDataDir;

            foreach (ZipEntry entry in zipFile.Entries)
            {
                
                if (extractToDir != null)
                {
                    try
                    {
                        string destinationPath = Path.Combine(extractToDir, entry.FileName);
                        entry.Extract(extractToDir, ExtractExistingFileAction.OverwriteSilently);
                        _log.DebugFormat("{0} extracted", entry.FileName);
                    }
                    catch
                    {
                        _log.WarnFormat("{0} extraction failed", entry.FileName);
                    }
                }
            }
        }

    }
}
