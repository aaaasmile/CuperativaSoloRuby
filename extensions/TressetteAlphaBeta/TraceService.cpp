// TraceService.cpp

#include "StdAfx.h"
#include <iostream>
#include <fstream>
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
    m_iChannel = 0;
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
        strOnlyFileName = m_strFileName.substr(iIndex, m_strFileName.length() - iIndex);
    }
    else
    {
        strOnlyFileName = m_strFileName;
    }
    sprintf(buff, "%d, %s, %s, %d, %s", m_ulTimeStamp, alpszDetTypeName[m_eTrType],
        strOnlyFileName.c_str(), m_iLineNumber, m_strComment.c_str());

    strRes = buff;
    return strRes;
}


//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////// TraceService   ///////////////////////
// singleton stuff

TraceService* TraceService::pinstance = 0;// initialize pointer
TraceService* TraceService::Instance()
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
    }

    m_entryTraceDetails.Reset();
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
/*! Add a new entry in the trace buffer. Separate AddNewEntry and AddCommentToLastEntry to spare time using
// string sprintf if the trace is not enabled.
// \param int iChannel :
// \param EntryTraceDetail::eType eValType :
// \param LPCSTR lpszFileName :
// \param int iLineNr :
*/
BOOL   TraceService::AddNewEntry(int iChannel, EntryTraceDetail::eType eValType,
    LPCSTR lpszFileName, int iLineNr)
{
    BOOL bRet = FALSE;
    ASSERT(iChannel >= 0 && iChannel < NUM_OF_CHANN);
    if (m_abChannelMask[iChannel])
    {
        m_entryTraceDetails.m_eTrType = eValType;
        m_entryTraceDetails.m_iChannel = iChannel;
        m_entryTraceDetails.m_iLineNumber = iLineNr;
        m_entryTraceDetails.m_strFileName = lpszFileName;
#ifdef WIN32
        SYSTEMTIME SysTm;
        GetSystemTime(&SysTm);
        m_entryTraceDetails.m_ulTimeStamp = SysTm.wMinute * 60 + SysTm.wSecond;
#else
        m_mtxEntryTraceDetails[iChannel][iIndexNew].m_ulTimeStamp = 0;
#endif
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
void   TraceService::AddCommentToLastEntry(LPCSTR lpszForm)
{
    sprintf(_bufferForComment, lpszForm);
    m_entryTraceDetails.m_strComment = _bufferForComment;
    flashTheEntry();
}

void   TraceService::AddCommentToLastEntry(LPCSTR lpszForm, int arg1)
{
    sprintf(_bufferForComment, lpszForm, arg1);
    m_entryTraceDetails.m_strComment = _bufferForComment;
    flashTheEntry();
}

void   TraceService::AddCommentToLastEntry(LPCSTR lpszForm, LPCSTR arg1)
{
    sprintf(_bufferForComment, lpszForm, arg1);
    m_entryTraceDetails.m_strComment = _bufferForComment;
    flashTheEntry();
}

void   TraceService::AddCommentToLastEntry(LPCSTR lpszForm, LPCSTR arg1, int arg2, LPCSTR arg3)
{
    sprintf(_bufferForComment, lpszForm, arg1, arg2, arg3);
    m_entryTraceDetails.m_strComment = _bufferForComment;
    flashTheEntry();
}

void   TraceService::AddCommentToLastEntry(LPCSTR lpszForm, int arg1, int arg2)
{
    sprintf(_bufferForComment, lpszForm, arg1, arg2);
    m_entryTraceDetails.m_strComment = _bufferForComment;
    flashTheEntry();
}

void   TraceService::flashTheEntry()
{
    int channel = m_entryTraceDetails.m_iChannel;
    STRING strEntry = m_entryTraceDetails.ToString();
    switch (m_aeChannelOut[channel])
    {
    case OT_FILE:
        m_aChannelFiles[channel] << strEntry.c_str() << std::endl;
        break;
    case OT_STDOUT:
        std::cout << strEntry.c_str() << std::endl;
        break;
    case OT_STDERR:
        std::cerr << strEntry.c_str() << std::endl;
        break;
    case OT_CUSTOMFN:
        if (m_pICustomTracer)
        {
            //m_pICustomTracer->Trace( strEntry.c_str() ); 
            ASSERT(0); // TO DO
        }
        break;
    case OT_MSVDEBUGGER:
        // visual studio debugger
        if (strEntry.length() < 512)
        {
            TRACE(strEntry.c_str());
            TRACE("\n");
        }
        break;
    case OT_MEMORY:
    default:
        // do nothing
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
    if (iChannel >= 0 && iChannel < NUM_OF_CHANN)
    {
        m_aeChannelOut[iChannel] = eVal;
        if (eVal == OT_FILE)
        {
            m_aChannelFiles[iChannel].open(lpszFileName);
        }
    }
}

