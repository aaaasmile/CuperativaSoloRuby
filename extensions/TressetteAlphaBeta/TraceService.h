
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
    //! channel id
    int     m_iChannel;
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
    BOOL   AddNewEntry(int iChannel, EntryTraceDetail::eType eValType, LPCSTR lpszFileName, int iLineNr);
    //! add a comment to the last entry
    void   AddCommentToLastEntry(LPCSTR lpszForm);
    void   AddCommentToLastEntry(LPCSTR lpszForm, int arg1);
    void   AddCommentToLastEntry(LPCSTR lpszForm, LPCSTR arg1);
    void   AddCommentToLastEntry(LPCSTR lpszForm, int arg1, int arg2);
    void   AddCommentToLastEntry(LPCSTR lpszForm, LPCSTR arg1, int arg2, LPCSTR arg3);
    //! enable channel
    void   EnableChannel(int iChann, BOOL bVal) { if (iChann >= 0 && iChann < NUM_OF_CHANN)m_abChannelMask[iChann] = bVal; }
    //! change the output channel
    void   SetOutputChannel(int iChannel, eOutType eVal, LPCSTR lpszFileName);
    //! set the custom trace interface
    void   SetCustomTacerInterface(I_GuiTracer* pIval) { m_pICustomTracer = pIval; }

private:
    // Flash m_entryTraceDetails into the channel output
    void   flashTheEntry();

private:
    CHAR               _bufferForComment[1024];
    EntryTraceDetail   m_entryTraceDetails;
    //! channel mask
    BOOL               m_abChannelMask[NUM_OF_CHANN];
    //! type output
    eOutType           m_aeChannelOut[NUM_OF_CHANN];
    //! file tracer for each channel
    std::ofstream      m_aChannelFiles[NUM_OF_CHANN];
    //! custom tracer inetrface
    I_GuiTracer*       m_pICustomTracer;

};


#endif
