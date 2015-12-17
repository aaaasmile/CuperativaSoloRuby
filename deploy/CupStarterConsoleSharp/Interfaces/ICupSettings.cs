using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace CupStarterConsoleSharp.Interfaces
{
    public interface ICupSettings
    {
        T GetValue<T>(string key);
        T GetValue<T>(string key, T defaultValue);

        void SetValue(string key, object value);

        void DeleteValue(string key);

        bool IsRootValid { get; }
    }
}
