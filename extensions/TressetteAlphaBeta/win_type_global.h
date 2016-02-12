////////////////////////////////////////////////////////////////////////////////
// win_type_global.h


#ifndef _AIGLOBAL_TYPE_H
#define _AIGLOBAL_TYPE_H

#if _MSC_VER > 1000
    #include "StdAfx.h"
#endif

#ifdef TRE_LIBRARY_EXPORT
	#define DLL_EXPORTIMPORT   __declspec( dllexport )
#else
	#define DLL_EXPORTIMPORT   __declspec( dllimport )
#endif

#ifdef USEDIALOGTRACE
    #include <iostream>
#endif

#ifdef WIN32
    #include <windows.h>
#endif
#if _MSC_VER > 1000
	#pragma warning(disable:4996) // unsafe sprintf
    #include <vector> 
    #include <deque>
    #include <string>
#else
	#include <iostream>
	#include <vector>
    #include <deque>
    #include <string>
    #include <sys/time.h>
    #include <string>
#endif

#ifndef BOOL 
    typedef int BOOL;
#endif

#ifndef BYTE
    typedef unsigned char BYTE;
#endif

#ifndef TRUE 
    #define TRUE 1==1
#endif

#ifndef FALSE 
    #define FALSE 0==1
#endif

#ifndef CHAR 
    #define CHAR char
#endif

#ifndef STRING 
	typedef std::string STRING;
#endif

#ifndef ASSERT
    #include <assert.h>
    #define ASSERT(f) \
	assert(f);
#endif

#ifndef CONST
	#define CONST const 
#endif

#ifndef ULONG
        #define ULONG unsigned long
#endif

#ifndef UINT
    typedef unsigned int    UINT;
#endif

#ifndef LPCSTR
    typedef CONST CHAR *LPCSTR, *PCSTR;
#endif

#ifndef LP_FNTHREAD
    //! function pointer for thread proxy casting
    typedef int (*LP_FNTHREAD)(void*);
#endif

#ifndef TRACE
    #include <stdio.h>
    #ifdef _MSC_VER
        // windows platform
        inline void TRACE(const char* fmt, ...)
        {
            static char myBuff[1024];
            va_list args;

            va_start( args, fmt );     /* Initialize variable arguments. */

            int result = vsprintf(myBuff, fmt, args); 
        #ifdef USEDIALOGTRACE
                    std::cout << "[TR] " <<myBuff;
        #else
                    ::OutputDebugStringA(myBuff);
        #endif
        }
    #else
        // non windows
		 #include <stdarg.h>
	    inline void TRACE(const char* fmt, ...)
        {
     	    char myBuff[512];
            va_list args;

            va_start( args, fmt );     /* Initialize variable arguments. */

            int result = vsprintf(myBuff, fmt, args); 
			std::cout << "[TR] " <<myBuff;
        }
    #endif
#endif


//random value between [0,x)
#define CASO(x) (x * rand()) / RAND_MAX

typedef std::vector<STRING> VCT_STRING;

#endif
