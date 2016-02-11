
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
    int     Suitlength(eSUIT esuit) { return suitList[esuit].size(); }
    //! lenght of the hand
    int     Length() { return suitList[0].size() + suitList[1].size() + suitList[2].size() + suitList[3].size(); }
    //! a card in the hand was played, adjust hand information
    void    PlayCard(cCardItem* pCard);
    //! reset the hand
    void    ResetHand() { for (int i = 0; i < searchalpha::SUITCOUNT; i++)suitList[i].clear(); }
    //! provides the last card
    cCardItem* GetLastPlayableCard();

public:
    CARDLIST  suitList[searchalpha::SUITCOUNT];

};

#endif // !defined(AFX_CHAND_H__1254BA53_DB52_4071_B806_B5588C98FE41__INCLUDED_)
