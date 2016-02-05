/*
    Invido
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


// TraceService.cpp

#include "StdAfx.h"
#include "win_type_global.h"
#include <iostream>
#include <fstream>
//#include "AlgPlayerInterface.h"
#include "TraceService.h"

///////////////////////////////////////////////////////
//// class EntryTraceDetail ///////////////////////////
///////////////////////////////////////////////////////
static const char* alpszDetTypeName[] =
{
    "TR_INFO",
    "TR_WARN",
    "TR_ERR",
    "TR_NOTSET"
};

////////////////////////////////////////
//       Reset
/*! Reset the detail
*/
void EntryTraceDetail::Reset()
{
    m_ulTimeStamp = 0;
    m_iID = 0;
    m_eTrType = TR_NOTSET;
    m_strFileName = "";
    m_iLineNumber = 0;
    m_strComment = "";
}


////////////////////////////////////////
//       ToString
/*! Format the trace detail in a string 
*/
STRING EntryTraceDetail::ToString()
{
    STRING strRes;
    STRING strOnlyFileName;
    CHAR buff[1024];

    // use only the filename and not the complete path
    int iIndex = m_strFileName.rfind('\\');
    if (iIndex != -1)
    {
        // eat slash
        iIndex++;
        strOnlyFileName = m_strFileName.substr(iIndex, m_strFileName.length() -  iIndex); 
    }
    else
    {
        strOnlyFileName = m_strFileName;
    }
    if (m_iID >= 0)
    {
        sprintf(buff, "%d, %d, %s, %s, %d, %s", m_ulTimeStamp, m_iID, alpszDetTypeName[m_eTrType], 
              strOnlyFileName.c_str() , m_iLineNumber, m_strComment.c_str() );
    }
    else
    {
        sprintf(buff, "%s", m_strComment.c_str() );
    }
    
    strRes = buff;
    return strRes;
}


//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////// TraceService   ///////////////////////
// singleton stuff

TraceService* TraceService::pinstance = 0;// initialize pointer
TraceService* TraceService::Instance () 
{
    if (pinstance == 0)  // is it the first call?
    {  
      pinstance = new TraceService; // create sole instance
    }
    return pinstance; // address of sole instance
}



////////////////////////////////////////
//       TraceService
/*! Constructor
*/
TraceService::TraceService()
{
    int i;
    for (i = 0; i < NUM_OF_CHANN; i++)
    {
        m_abChannelMask[i] = FALSE;
        m_aeChannelOut[i] = OT_MEMORY;
        m_aiChannelCursor[i] = 0;
    }

    for ( i = 0; i < NUM_OF_CHANN; i++)
    {
        for (int j = 0; j < NUM_OF_ENTRIES; j++)
        {
            m_mtxEntryTraceDetails[i][j].Reset(); 
        }
    }
    m_iLastChannelUsed = -1;
    m_iLastEntryUsed = -1;
    m_pICustomTracer = 0;
}


////////////////////////////////////////
//       ~TraceService
/*! 
*/
TraceService::~TraceService()
{
    for (int i = 0; i < NUM_OF_CHANN; i++)
    {
        if (m_aChannelFiles[i].is_open())
        {
            m_aChannelFiles[i].close(); 
        }
    }
}

////////////////////////////////////////
//       AddNewEntry
/*! Add a new entry in the trace buffer
// \param int iChannel : 
// \param int iId : 
// \param EntryTraceDetail::eType eValType : 
// \param LPCSTR lpszFileName : 
// \param int iLineNr : 
*/
BOOL   TraceService::AddNewEntry(int iChannel, int iId, EntryTraceDetail::eType eValType, 
                                                          LPCSTR lpszFileName, int iLineNr)
{
    BOOL bRet = FALSE;
    ASSERT(iChannel >= 0 && iChannel < NUM_OF_CHANN);
    if (m_abChannelMask[iChannel])
    {
        int iIndexNew = m_aiChannelCursor[iChannel];
        ASSERT(iIndexNew >= 0 && iIndexNew < NUM_OF_ENTRIES);

        // update info trace
        m_mtxEntryTraceDetails[iChannel][iIndexNew].m_eTrType = eValType;
        m_mtxEntryTraceDetails[iChannel][iIndexNew].m_iID  = iId;
        m_mtxEntryTraceDetails[iChannel][iIndexNew].m_iLineNumber  = iLineNr;
        m_mtxEntryTraceDetails[iChannel][iIndexNew].m_strFileName  = lpszFileName;
#ifdef WIN32
        SYSTEMTIME SysTm;
        GetSystemTime( &SysTm);
        m_mtxEntryTraceDetails[iChannel][iIndexNew].m_ulTimeStamp  = SysTm.wMinute * 60 + SysTm.wSecond;
#else
	m_mtxEntryTraceDetails[iChannel][iIndexNew].m_ulTimeStamp  = 0;
#endif
        // enable the call to add a comment
        m_iLastEntryUsed = iIndexNew;
        m_iLastChannelUsed = iChannel;

        // set the cursor to a new entry
        m_aiChannelCursor[iChannel] ++;
        if (m_aiChannelCursor[iChannel] >= NUM_OF_ENTRIES)
        {
            // circular buffer
            m_aiChannelCursor[iChannel] = 0;
        }
        bRet = TRUE;
    }
    
    return bRet;

}


////////////////////////////////////////
//       AddCommentToLastEntry
/*! Add a comment to the last trace entry and flush in the medium 
// \param LPCSTR lpszForm : 
// \param ... : 
*/
void   TraceService::AddCommentToLastEntry(LPCSTR lpszForm, ... )
{
    if (m_iLastEntryUsed >= 0 && m_iLastEntryUsed < NUM_OF_ENTRIES &&
        m_iLastChannelUsed >= 0 && m_iLastChannelUsed < NUM_OF_CHANN)
    {
        static CHAR buff[1024];
        va_list marker;
	    va_start(marker, lpszForm);										
	    vsprintf(buff, lpszForm, marker);						
	    va_end(marker);	
        m_mtxEntryTraceDetails[m_iLastChannelUsed][m_iLastEntryUsed].m_strComment = buff ;
        
        flashTheEntry();

        // avoid to overwrite the comment
        m_iLastChannelUsed = -1;
        m_iLastEntryUsed = -1;
    }
    else
    {
        // trace usage not correct
        ASSERT(0);
    }
}


////////////////////////////////////////
//       AddSimpleTrace
/*! Add a simple trace, this is a info with no information about line and file
// \param int iChannel : 
// \param LPCSTR lpszForm : 
// \param ... : 
*/
void TraceService::AddSimpleTrace(int iChannel, LPCSTR lpszForm, ...)
{
    ASSERT(iChannel >= 0 && iChannel < NUM_OF_CHANN);
    if (m_abChannelMask[iChannel])
    {
        int iIndexNew = m_aiChannelCursor[iChannel];
        ASSERT(iIndexNew >= 0 && iIndexNew < NUM_OF_ENTRIES);


        // updat info trace
        m_mtxEntryTraceDetails[iChannel][iIndexNew].m_eTrType = EntryTraceDetail::TR_INFO;
        m_mtxEntryTraceDetails[iChannel][iIndexNew].m_iID  = -1;
        m_mtxEntryTraceDetails[iChannel][iIndexNew].m_iLineNumber  = -1;
        m_mtxEntryTraceDetails[iChannel][iIndexNew].m_strFileName  = "\\nofile";
#ifdef WIN32
        SYSTEMTIME SysTm;
        GetSystemTime( &SysTm);
        m_mtxEntryTraceDetails[iChannel][iIndexNew].m_ulTimeStamp  = SysTm.wMinute * 60 + SysTm.wSecond;
#else
	m_mtxEntryTraceDetails[iChannel][iIndexNew].m_ulTimeStamp  = 0;
#endif
        // info for flashout
        m_iLastEntryUsed = iIndexNew;
        m_iLastChannelUsed = iChannel;

        static CHAR buff[1024];
        va_list marker;
	va_start(marker, lpszForm);										
	vsprintf(buff, lpszForm, marker);						
	va_end(marker);	
        m_mtxEntryTraceDetails[m_iLastChannelUsed][m_iLastEntryUsed].m_strComment = buff ;

        // put it out
        flashTheEntry();

        m_iLastEntryUsed = -1;
        m_iLastChannelUsed = -1;

        // set the cursor to a new entry
        m_aiChannelCursor[iChannel] ++;
        if (m_aiChannelCursor[iChannel] >= NUM_OF_ENTRIES)
        {
            // circular buffer
            m_aiChannelCursor[iChannel] = 0;
        }
    }
}


////////////////////////////////////////
//       flashTheEntry
/*! flash the entry in the output
*/
void  TraceService::flashTheEntry()
{
    // 
    STRING strEntry;
    switch (m_aeChannelOut[m_iLastChannelUsed])
    {
        case OT_FILE:
            strEntry = m_mtxEntryTraceDetails[m_iLastChannelUsed][m_iLastEntryUsed].ToString(); 
            m_aChannelFiles[m_iLastChannelUsed] << strEntry.c_str() << std::endl;
            break;
        case OT_STDOUT:
            strEntry = m_mtxEntryTraceDetails[m_iLastChannelUsed][m_iLastEntryUsed].ToString(); 
            std::cout << strEntry.c_str() << std::endl; 
            break;
        case OT_STDERR:
            strEntry = m_mtxEntryTraceDetails[m_iLastChannelUsed][m_iLastEntryUsed].ToString(); 
            std::cerr << strEntry.c_str() << std::endl;
            break;

        case OT_CUSTOMFN:
            if (m_pICustomTracer)
            {
                strEntry = m_mtxEntryTraceDetails[m_iLastChannelUsed][m_iLastEntryUsed].ToString();
                //m_pICustomTracer->Trace( strEntry.c_str() ); 
				ASSERT(0); // TO DO
            }
            
            break;

        case OT_SOCKET:
            strEntry = m_mtxEntryTraceDetails[m_iLastChannelUsed][m_iLastEntryUsed].ToString(); 
            ASSERT(0); // TO DO
            break;

        case OT_MSVDEBUGGER:
            // visual studio debugger
            strEntry = m_mtxEntryTraceDetails[m_iLastChannelUsed][m_iLastEntryUsed].ToString(); 
            if (strEntry.length() < 512) 
            {
                TRACE(strEntry.c_str() );
                TRACE("\n");
            }
            break;
    }
}

////////////////////////////////////////
//       SetOutputChannel
/*! Set the output type of the channel
// \param int iChannel : 
// \param eOutType eVal : 
*/
void TraceService::SetOutputChannel(int iChannel, eOutType eVal, LPCSTR lpszFileName)
{
    if (iChannel >= 0 && iChannel < NUM_OF_CHANN )
    {
        m_aeChannelOut[iChannel] = eVal;
        if (eVal == OT_FILE)
        {
            m_aChannelFiles[iChannel].open(lpszFileName); 
        }
    }
}

