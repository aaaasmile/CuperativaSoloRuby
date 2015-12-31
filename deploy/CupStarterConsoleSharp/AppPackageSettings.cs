using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace CupStarterConsoleSharp
{
    class AppPackageSettings
    {
        private CupUserSettings settings;

        public AppPackageSettings(CupUserSettings appSettings)
        {
            this.settings = appSettings;
            MajorVer = appSettings.GetValue<int>("Ver0", 0);
            MedVer = appSettings.GetValue<int>("Ver1", 0);
            SmallVer = appSettings.GetValue<int>("Ver2", 0);
            if (MajorVer == 0 && MedVer == 0 && SmallVer == 0)
                throw new ArgumentException("Version is not set");

            AppStartScript = appSettings.GetValue<string>("StartScript", "");

            CalculateAppVersion();
            CalcualteAppZipName();
        }

        private void CalcualteAppZipName()
        {
            AppZipName = string.Format("app_{0}.zip", AppVersion);
        }

        private void CalculateAppVersion()
        {
            AppVersion = string.Format("{0}_{1}_{2}", MajorVer, MedVer, SmallVer);
        }

        public int MajorVer { get; internal set; }
        public int MedVer { get; internal set; }
        public int SmallVer { get; internal set; }
        public string AppVersion { get; internal set; }
        public string AppZipName { get; internal set; }
        public string AppStartScript { get; internal set; }
    }
}
