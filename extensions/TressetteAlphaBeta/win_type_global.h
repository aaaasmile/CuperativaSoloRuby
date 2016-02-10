/*
    Tressette
    Copyright (C) 2005  Igor Sarzi Sartori

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.

    You should have received a copy of the GNU Library General Public
    License along with this library; if not, write to the Free
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

    Igor Sarzi Sartori
    www.invido.it
    6colpiunbucosolo@gmx.net
*/

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
	#pragma warning( disable: 4251 )
    #pragma warning(disable:4786)
	#pragma warning(disable:4996)
    #include <vector> 
    #include <deque>
    #include <string>
#else
	#include <iostream>
	#include <vector>
    #include <deque>
    #include <string>
    #include <sys/time.h>
    #include <string.h>
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
            char myBuff[512];
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
