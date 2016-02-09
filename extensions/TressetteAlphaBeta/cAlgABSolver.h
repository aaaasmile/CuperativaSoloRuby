// cAlgABSolver.h: interface for the cAlgABSolver class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_CALGABSOLVER_H__15F6DC19_13E2_4D6F_85C3_2DB15F4A7E02__INCLUDED_)
#define AFX_CALGABSOLVER_H__15F6DC19_13E2_4D6F_85C3_2DB15F4A7E02__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

//#include <SDL.h> // only for using  an OS indipendent tick counter 
#include "InfoComm.h"
#include "cCardItem.h"
#include "ConstSearchAlpha.h"
#include "cStateAB.h"
#include "win_type_global.h"



class TraceService;

//! class cAlgABSolver
/** This class calculate the alpha-beta algorithm of the game
*/ 
class cAlgABSolver  
{
public:
	cAlgABSolver();
	virtual ~cAlgABSolver();

public:
    //! initialize deck
    void    InitDeck();
    //! set a player hands
    void    SetHands(int  iPlayerIx, CARDINFO* arrCards, int iNumItem);
    //! set the plaer index that start
    void    SetInitialPlayer(int  iPlayerIx);
    //! solve the hand
    void    Solve();
    //! resolve the player name in a index
    static int PlayerNameToIndex(LPCSTR lpstrName);
    //! resolve the player index ini a string
    static STRING PlayerIndexToName(BYTE byIndex);
    //! set the hand deph
    void    SetHandDeph(int iVal){m_iSearchdHandDeph = iVal;}
    //! set the calculation max time in millisec 
    void    SetMaxCalcTime(Uint32 uiVal){m_uiMaxCalcTime = uiVal;}
    //! provides the best card to play found with solve
    void    GetBestCardToPlay(int iPlayerIx, CARDINFO* pCardInfo);
    //! set the history of the current trick
    void    SetCurrTrickHistory(int iPlIx_Start,CARDINFO* arrCards, int iNumItem);

private:
    void   renderHandStdOut();
    void   renderBestLine(cBestLine& lstMainLine);
    void   vrb(int n, char* strPar, ...);
    int    alphaBeta(int depth, int alpha, int beta, cStateAB* pCurrState);
    void   alphaBeta_progress();
	int    getTicks();
    
private:
    //! initial state
    cStateAB   m_StateInitial;
    //! default deck
    cCardItem  m_Deck[searchalpha::DECKSIZE];
    //! verbose level
    int        m_iVerboseLevel;
    //! main line (best move)
    cBestLine  m_lstMainLine;
    //! count the total number of calculations
    int        m_iNumOfCalc;
    //! search deph in number of hands 
    int        m_iSearchdHandDeph;
    //! initial time mark
    Uint32     m_uiInitialTime;
    //! max calc time
    Uint32     m_uiMaxCalcTime;
    //! tracer
    TraceService*             m_pTracer;

#ifndef _MSC_VER
    struct timeval    _start;
#endif

};

#endif // !defined(AFX_CALGABSOLVER_H__15F6DC19_13E2_4D6F_85C3_2DB15F4A7E02__INCLUDED_)
