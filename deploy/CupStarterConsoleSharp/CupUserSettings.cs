using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using CupStarterConsoleSharp.Interfaces;
using Microsoft.Win32;

namespace CupStarterConsoleSharp
{
    class CupUserSettings : ICupSettings
    {
        private static readonly log4net.ILog _log = log4net.LogManager.GetLogger(typeof(CupUserSettings));

        private readonly RegistryKey _rootKey;
        private readonly bool _isReadOnly;

        public CupUserSettings(RegistryKey rootkey, bool isReadOnly)
        {
            _isReadOnly = isReadOnly;
            _rootKey = rootkey;
        }

        ~CupUserSettings()
        {
            if (_rootKey != null)
            { _rootKey.Close(); }
        }

        public T GetValue<T>(string key)
        {
            if (_rootKey == null) { return default(T); }

            return (T)_rootKey.GetValue(key, null);
        }

        public T GetValue<T>(string key, T defaultValue)
        {
            if (typeof(T) == typeof(double))
            {
                return (T)(object)GetDoubleValue(key, (double)(object)defaultValue);
            }
            else if (typeof(T) == typeof(bool))
            {
                return (T)(object)GetBooleanValue(key, (bool)(object)defaultValue);
            }

            if (_rootKey == null) { return defaultValue; }
            return (T)_rootKey.GetValue(key, defaultValue);
        }

        private bool GetBooleanValue(string key, bool defaultValue)
        {
            var valueString = GetValue<string>(key, null);
            if (valueString == null) { return defaultValue; }

            bool boolValue;
            if (Boolean.TryParse(valueString, out boolValue))
            {
                return boolValue;
            }
            else
            {
                _log.WarnFormat("Error parsing double: {0}", valueString);
                return defaultValue;
            }
        }

        private double GetDoubleValue(string key, double defaultValue)
        {
            var valueString = GetValue<string>(key, null);
            if (valueString == null) { return defaultValue; }

            double doubleValue;
            if (Double.TryParse(valueString, NumberStyles.Any, CultureInfo.InvariantCulture, out doubleValue))
            {
                return doubleValue;
            }
            else
            {
                _log.WarnFormat("Error parsing double: {0}", valueString);
                return defaultValue;
            }
        }

        public void SetValue(string key, object value)
        {
            if (value is double)
            {
                var doubleValue = (double)value;
                value = doubleValue.ToString(CultureInfo.InvariantCulture);
            }
            else if (value is bool)
            {
                var boolValue = (bool)value;
                value = boolValue.ToString(CultureInfo.InvariantCulture);
            }

            if (_rootKey == null || _isReadOnly) { return; }
            _rootKey.SetValue(key, value);
        }

        public void DeleteValue(string key)
        {
            if (_rootKey == null || _isReadOnly) { return; }

            if (_rootKey.GetValue(key) != null)
            {
                _rootKey.DeleteValue(key);
            }
        }

        public bool IsRootValid
        {
            get
            {
                return _rootKey != null;
            }
        }
    }
}
