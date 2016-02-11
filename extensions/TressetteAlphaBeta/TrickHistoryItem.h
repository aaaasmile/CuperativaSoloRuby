// TrickHistory.h: interface for the TrickHistory class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_TRICKHISTORY_H__E5BFD3AE_A7FE_4D9D_B146_3F2C42D1504C__INCLUDED_)
#define AFX_TRICKHISTORY_H__E5BFD3AE_A7FE_4D9D_B146_3F2C42D1504C__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#include <deque>
#include "InfoComm.h"
#include "ConstSearchAlpha.h"
#include "cCardItem.h"
#include "win_type_global.h"

//! class  TrickHistory
class TrickHistoryItem
{
public:
    TrickHistoryItem();
    virtual ~TrickHistoryItem();
    TrickHistoryItem(BYTE byPlS, BYTE byTn) {
        m_byPlayer_S = byPlS;
        m_byPlayer_T = 0xff; m_byTrickNum = byTn; m_byPointsTrick = 0;
    }

    //! card list trick
    CARDLIST    m_Trick;
    //! player that start the trick
    BYTE        m_byPlayer_S;
    //! player thar take the trick
    BYTE        m_byPlayer_T;
    //! trick number
    BYTE        m_byTrickNum;
    //! trick points
    BYTE        m_byPointsTrick;
};


typedef std::vector<TrickHistoryItem>TRICKHISTORY;




#endif // !defined(AFX_TRICKHISTORY_H__E5BFD3AE_A7FE_4D9D_B146_3F2C42D1504C__INCLUDED_)


