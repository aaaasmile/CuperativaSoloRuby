using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using CupStarterConsoleSharp.Interfaces;
using Microsoft.Win32;

namespace CupStarterConsoleSharp
{
    class AppStarter
    {
        internal void Run()
        {
            CupUserSettings settings = new CupUserSettings(Registry.CurrentUser.CreateSubKey(@"Software\invido_it\Cuperativa"), isReadOnly: false);
            string installDir = settings.GetValue<string>("InstallDir");
            if(!settings.GetValue<bool>("RubyPackgeUnzipped", false))
            {
                string rubyZip = settings.GetValue<string>("RubyPackage");
                string rubyZipPackagePath = Path.Combine(Path.Combine(installDir, "Ruby"), rubyZip);
                if (!File.Exists(rubyZipPackagePath)) throw (
                        new ArgumentException(string.Format("Ruby {0} package not found", rubyZip)));


            }
        }
    }
}
