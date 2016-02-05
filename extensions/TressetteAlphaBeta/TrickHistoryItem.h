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
    TrickHistoryItem(BYTE byPlS, BYTE byTn ){m_byPlayer_S = byPlS; 
                         m_byPlayer_T = 0xff; m_byTrickNum = byTn; m_byPointsTrick = 0;}

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


