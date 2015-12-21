using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace CupStarterConsoleSharp
{
    class AppPackageSettings
    {
        private CupUserSettings settings;

        public AppPackageSettings(CupUserSettings settings)
        {
            this.settings = settings;
            MajorVer = settings.GetValue<int>("Ver0", 0);
            MedVer = settings.GetValue<int>("Ver1", 0);
            SmallVer = settings.GetValue<int>("Ver2", 0);
            if (MajorVer == 0 && MedVer == 0 && SmallVer == 0)
                throw new ArgumentException("Version is not set");

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
    }
}
