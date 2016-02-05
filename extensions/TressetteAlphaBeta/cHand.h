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



// cHand.h: interface for the cHand class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_CHAND_H__1254BA53_DB52_4071_B806_B5588C98FE41__INCLUDED_)
#define AFX_CHAND_H__1254BA53_DB52_4071_B806_B5588C98FE41__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#include <deque>
#include "InfoComm.h"
#include "ConstSearchAlpha.h"
#include "cCardItem.h"
#include "win_type_global.h"

//! class  cHand
class cHand  
{
    
public:
	cHand();
	virtual ~cHand();
    //! add a card to the list
    void    AddCards(CARDLIST& handSubmit);
    //! render a suit in a string
    STRING  RenderSuit(eSUIT esuit);
    //! provides the suit leength
    int     Suitlength(eSUIT esuit){return suitList[esuit].size();}
    //! lenght of the hand
    int     Length(){return suitList[0].size() + suitList[1].size() + suitList[2].size() + suitList[3].size();}
    //! a card in the hand was played, adjust hand information
    void    PlayCard( cCardItem* pCard );
    //! reset the hand
    void    ResetHand(){for(int i = 0; i < searchalpha::SUITCOUNT; i++)suitList[i].clear();}
    //! provides the last card
    cCardItem* GetLastPlayableCard();

public:
    CARDLIST  suitList[searchalpha::SUITCOUNT];

};

#endif // !defined(AFX_CHAND_H__1254BA53_DB52_4071_B806_B5588C98FE41__INCLUDED_)
