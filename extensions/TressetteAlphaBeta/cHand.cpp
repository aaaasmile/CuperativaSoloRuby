
// cHand.cpp: implementation of the cHand class.
//
//////////////////////////////////////////////////////////////////////

#include "StdAfx.h"
#include "cHand.h"
#include "cStateAB.h"


//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

cHand::cHand()
{

}

cHand::~cHand()
{

}

////////////////////////////////////////
//       AddCards
/*! Add a card to the hand list
// \param CARDLIST& handSubmit :
*/
void  cHand::AddCards(CARDLIST& handSubmit)
{
    for (UINT i = 0; i < handSubmit.size(); i++)
    {
        eSUIT esuit = handSubmit[i]->card.eSuit;
        suitList[esuit].push_back(handSubmit[i]);
    }

}

////////////////////////////////////////
//       RenderSuit
/*! Display into a string a list that belongs to a suit.
// \param eSUIT suit :
*/
STRING cHand::RenderSuit(eSUIT esuit)
{
    STRING strText;
    char buff[256];
    char* pCurr = buff;
    int offset = 0;

    for (UINT i = 0; i < suitList[esuit].size(); i++)
    {
        pCurr += offset;
        cCardItem* pCard = suitList[esuit][i];
        offset = sprintf(pCurr, "%c%c,", pCard->chCardLetter, pCard->chSuitLetter);
    }
    if (offset > 0)
    {
        offset--;
    }
    pCurr += offset;
    *pCurr = '\0';

    strText = buff;

    return strText;
}


////////////////////////////////////////
//       PlayCard
/*! A card was played, remove it from the player hand
// \param cCardItem* pCard : card played
*/
void cHand::PlayCard(cCardItem* pCard)
{
    CARDLIST*  tmpList = &suitList[pCard->card.eSuit];

    //    cStateAB::TraceCardListDbg(*tmpList); 

    CARDLIST_IT pCurrIter = tmpList->begin();

    BOOL bFound = FALSE;
    int iIniItems = tmpList->size();
    int i;
    for (i = 0; !bFound && i < iIniItems; i++)
    {
        cCardItem* pCardInList = (*tmpList)[i];
        if (pCardInList->card.byIndex == pCard->card.byIndex)
        {
            // card found
            bFound = TRUE;
            // remove it
            //tmpList->erase(pCurrIter);
        }
        else
        {
            pCurrIter++;
        }
    }
    ASSERT(bFound);
    if (i == 1)
    {
        // first item
        tmpList->pop_front();
    }
    else if (i == iIniItems)
    {
        tmpList->pop_back();
    }
    else
    {
        tmpList->erase(pCurrIter);
    }
    //cStateAB::TraceCardListDbg(*tmpList); 
}


////////////////////////////////////////
//       GetLastPlayableCard
/*! Provides the last card to be played. If there are more cards to playa the function return null.
*/
cCardItem* cHand::GetLastPlayableCard()
{
    cCardItem* pRes = 0;
    if (suitList[0].size() == 1)
    {
        // look on bastoni suit
        pRes = suitList[0][0];
    }
    else if (suitList[1].size() == 1)
    {
        // look on coppe suit
        pRes = suitList[1][0];
    }
    else if (suitList[2].size() == 1)
    {
        // look on denari suit
        pRes = suitList[2][0];
    }
    else if (suitList[3].size() == 1)
    {
        // look on denari suit
        pRes = suitList[3][0];
    }
    return pRes;
}


