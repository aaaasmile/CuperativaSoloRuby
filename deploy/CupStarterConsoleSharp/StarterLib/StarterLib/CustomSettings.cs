using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml.Serialization;
using System.IO;

namespace StarterLib
{
    public class StarterSettings
    {
        public StarterSettings()
        {
            SubPathSrc = @"app\src";
            StartScriptName = "start_cuperativa.rb";
            CmdRubyName = @"ruby\bin\ruby.exe";
            UpdaterScript = @"updater\cupupdater.rb";
            AppResultFname = "result_exe";
        }

        public string SubPathSrc { get; set; }
        public string StartScriptName { get; set; }
        public string CmdRubyName { get; set; }
        public string UpdaterScript { get; set; }
        public string AppResultFname { get; set; }

        internal string GetRelStartScriptName()
        {
            return Path.Combine(SubPathSrc, StartScriptName);
        }

    }

    public class CustomSettings
    {
        private static log4net.ILog _log = log4net.LogManager.GetLogger(typeof(CustomSettings));

        private static string _customStarterSettingsFname = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                @"Invido.it\Cupeartiva\starter_info.xml");

        public static string StarterSettingsFname
        {
            get { return _customStarterSettingsFname; }
        }

        public static string RootDataDir
        {
            get
            {
                return Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                    @"Invido.it\Cupeartiva");
            }
        }

        public static string AppDataFilename
        {
            get
            {
                return "appdata.zip";
            }
        }

        internal static bool CheckOrCreateRootKey()
        {
            bool bres = false;
            string rootDir = Path.Combine(
                     Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                     "Invido.it");

            rootDir = RootDataDir;
            try
            {
                if (!Directory.Exists(rootDir))
                {
                    Directory.CreateDirectory(rootDir);
                }
                bres = true;
            }
            catch (Exception e)
            {
                _log.ErrorFormat("Failed to create application dir, error {0}", e.Message);
            }

            return bres;
        }


        public static void SerilizeToXmlFile(StarterSettings sett)
        {
            _log.DebugFormat("Save settings to xml file {0}", _customStarterSettingsFname);

            XmlSerializer s = new XmlSerializer(typeof(StarterSettings));
            TextWriter w = new StreamWriter(_customStarterSettingsFname);
            s.Serialize(w, sett);
            w.Close();
        }

        public static string SerilizeToXmlString(StarterSettings sett)
        {
            XmlSerializer s = new XmlSerializer(typeof(StarterSettings));
            MemoryStream ms = new MemoryStream();
            s.Serialize(ms, sett);
            StreamReader r = new StreamReader(ms);
            r.BaseStream.Seek(0, SeekOrigin.Begin);
            return r.ReadToEnd();
        }

        public static StarterSettings DeSerilizeFromXmlFile()
        {
            _log.DebugFormat("Load settings from file {0}", _customStarterSettingsFname);
            StarterSettings newSettings = new StarterSettings();
            XmlSerializer s = new XmlSerializer(typeof(StarterSettings));
            TextReader r = null;
            try
            {
                if (File.Exists(_customStarterSettingsFname))
                {
                    r = new StreamReader(_customStarterSettingsFname);
                    newSettings = s.Deserialize(r) as StarterSettings;
                }
            }
            catch (Exception e)
            {
                _log.ErrorFormat("Deserialize  failed: {0}", e.Message);
                _log.Debug("Use in memory default settings");
            }
            finally
            {
                if (r != null)
                {
                    r.Close();
                }
            }

            return newSettings;
        }




    }
}
