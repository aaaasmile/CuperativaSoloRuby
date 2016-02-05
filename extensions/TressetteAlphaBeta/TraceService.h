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

// TraceService.h

#ifndef TRACESERVICE__H___
#define TRACESERVICE__H___

#include "win_type_global.h"
#include <fstream>

class I_GuiTracer;

//! class EntryTraceDetail 
class EntryTraceDetail
{
public:
    enum eType
    {
        TR_INFO,
        TR_WARN,
        TR_ERR,
        TR_NOTSET
    };
public:
    //! reset the detail
    void    Reset();
    //! format detail in a string
    STRING  ToString();

public:
    //! time stamp
    ULONG   m_ulTimeStamp;
    //! trace entry id
    int     m_iID;
    //! type
    eType   m_eTrType;
    //! filename
    STRING  m_strFileName;
    //! line number
    int     m_iLineNumber;
    //! comment
    STRING  m_strComment;
};


//! class TraceService
class TraceService
{
    enum
    {
        //! number of entries in a channel
        NUM_OF_ENTRIES = 500,
        //! number of channel
        NUM_OF_CHANN = 5
    };
protected:
    TraceService();
   
public:
	static  TraceService* Instance();
	
private:
    static TraceService* pinstance;

public:
    enum eOutType
    {
        OT_MEMORY,
        OT_STDOUT,
        OT_STDERR,
        OT_FILE,
        OT_CUSTOMFN,
        OT_SOCKET,
        OT_MSVDEBUGGER
    };

public:
    //! destructor
    ~TraceService();
    //! add a new trace entry
    BOOL   AddNewEntry(int iChannel, int iId, EntryTraceDetail::eType eValType, LPCSTR lpszFileName, int iLineNr);
    //! add a comment to the last entry
    void   AddCommentToLastEntry(LPCSTR lpszForm, ... );
    //! enable channel
    void   EnableChannel(int iChann, BOOL bVal){if(iChann>= 0 && iChann < NUM_OF_CHANN)m_abChannelMask[iChann] = bVal;}
    //! change the output channel
    void   SetOutputChannel(int iChannel, eOutType eVal, LPCSTR lpszFileName);
    //! add a simple trace
    void   AddSimpleTrace(int iChannel, LPCSTR lpszForm, ...);
    //! set the custom trace interface
    void   SetCustomTacerInterface(I_GuiTracer* pIval){m_pICustomTracer = pIval;}

private:
    void   flashTheEntry();

private:
    //! tracer channels in circular buffer
    EntryTraceDetail   m_mtxEntryTraceDetails[NUM_OF_CHANN][NUM_OF_ENTRIES];
    //! channel mask
    BOOL               m_abChannelMask[NUM_OF_CHANN];
    //! type output
    eOutType           m_aeChannelOut[NUM_OF_CHANN];
    //! cursor new entry
    int                m_aiChannelCursor[NUM_OF_CHANN];
    //! last entry index
    int                m_iLastEntryUsed;
    //! last channel used
    int                m_iLastChannelUsed;
    //! file tracer for each channel
    std::ofstream      m_aChannelFiles[NUM_OF_CHANN];
    //! custom tracer inetrface
    I_GuiTracer*       m_pICustomTracer;
    
};


#endif
