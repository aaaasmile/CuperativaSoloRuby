
// cStateAB.h: interface for the cStateAB class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_CSTATEAB_H__31CCD296_4849_4A13_B315_A66EF7CBDA4F__INCLUDED_)
#define AFX_CSTATEAB_H__31CCD296_4849_4A13_B315_A66EF7CBDA4F__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#include "win_type_global.h"
#include "cHand.h"
#include "TrickHistoryItem.h"


//! class cStateAB
class cStateAB  
{
#ifdef WIN32
typedef unsigned __int64 stateid;
#else
typedef long long stateid;
#endif
public:
	cStateAB();
    cStateAB(cStateAB* pCopy);
	virtual ~cStateAB();
    //! state to string
    STRING   State_repr();
    //! Provides all legal moves using the euristic
    void     GenerateLegalMoves(CARDLIST& cardlistState);
    //! make a move
    void     MakeMove( cCardItem* pCard );
    //! get the number of tricks left
    int      GetTrickLeft(){return m_byTricksleft;}
    //! set the number of tricks left
    void     SetTrickLeft(BYTE byVal){m_byTricksleft = byVal;}
    //! add cards to a player
    void     AddCards(int iPlayerIx, CARDLIST& handSubmit);
    //! provides the current player on turn
    int      GetInitialPlayer(){return m_PlayerIx;}
    //! set the current player on turn
    void     SetInitialPlayer(int iVal);
    //! flag if the team turn is changed
    BOOL     IsTeamOnTurnChanged(){return m_bTeamOnTurnChange;}
    //! evaluate the state
    int      EvaluateState();
    //! provides the best line
    void     GetBestLine(cBestLine& lstBest);
    //! evaluate the last trick in the giocata
    int      EvaluateLastTrick();
    //! add a trick history
    void     AddTrickHist(int iPlIx_Start, CARDLIST& trickHist);
    //! trace a card list in the debugger
    static void  TraceCardListDbg(CARDLIST& cardlistState);
    void     TraceTrickHistory(int iAlpha);
    //! set calculation timeout
    void     SetTimeout(){m_bTimeOut = TRUE;}
    //! provides timeout flag
    BOOL     GetTimeout(){return m_bTimeOut;}

private:
    BYTE  getNextPlayerIndex(BYTE byPlIx){byPlIx++;if(byPlIx>= searchalpha::PLAYERCOUNT){byPlIx = 0;}return byPlIx;}
    void  narrowones_first(CARDLIST& cardlistState);
    void  takeit_or_leaveit(CARDLIST& cardlistState);
    BYTE  getTeamIndex(BYTE byPlIx){if( (byPlIx & 1) == 0){return 0;}else{return 1;}}
    
    BYTE  getPlayerIncremented(BYTE byPlIx, BYTE iInc){while(iInc>0){byPlIx = getNextPlayerIndex(byPlIx); iInc--;} return byPlIx; }
    void  appendList(CARDLIST& lstFirst, CARDLIST& lstSecond);

private:
    //! state id
    stateid        m_id;
    //! hands of all players
    cHand          m_HanPlayers[searchalpha::PLAYERCOUNT];
    //! current player index on turn
    BYTE           m_PlayerIx;
    //! trick left
    BYTE           m_byTricksleft;
    //! current suit
    eSUIT          m_eSuit;
    //! trick history
    TRICKHISTORY   m_trickHist;
    //! team points
    BYTE           m_arrTeamPoints[searchalpha::TEAMCOUNT];
    //! flag if the team on turn is changed
    BOOL           m_bTeamOnTurnChange;
    //! flag if the player on turn is maximize
    BOOL           m_bIsMaximize;
    //! flag foe calculation timeout
    BOOL           m_bTimeOut;
};

#endif // !defined(AFX_CSTATEAB_H__31CCD296_4849_4A13_B315_A66EF7CBDA4F__INCLUDED_)
