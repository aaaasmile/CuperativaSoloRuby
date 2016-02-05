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


// cCardItem.cpp: implementation of the cCardItem class.
//
//////////////////////////////////////////////////////////////////////

#include "StdAfx.h"
#include "cCardItem.h"
#include "win_type_global.h"



using namespace searchalpha;

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

// rank table to make card comparation
static const int g_RankTable[] = 
{ 
  /*Asso*/11, /*Due*/12, /*Tre*/13, /*Quattro*/4, /*cinque*/5, /*Sei*/6, /*Sette*/7, /*Fante*/8, /*Cavallo*/9, /*Re*/10,
  /*Asso*/11, /*Due*/12, /*Tre*/13, /*Quattro*/4, /*cinque*/5, /*Sei*/6, /*Sette*/7, /*Fante*/8, /*Cavallo*/9, /*Re*/10,
  /*Asso*/11, /*Due*/12, /*Tre*/13, /*Quattro*/4, /*cinque*/5, /*Sei*/6, /*Sette*/7, /*Fante*/8, /*Cavallo*/9, /*Re*/10,
  /*Asso*/11, /*Due*/12, /*Tre*/13, /*Quattro*/4, /*cinque*/5, /*Sei*/6, /*Sette*/7, /*Fante*/8, /*Cavallo*/9, /*Re*/10
}; 

// points table
static const int g_PointsTable[] = 
{ 
  /*Asso*/3, /*Due*/1, /*Tre*/1, /*Quattro*/0, /*cinque*/0, /*Sei*/0, /*Sette*/0, /*Fante*/1, /*Cavallo*/1, /*Re*/1,
  /*Asso*/3, /*Due*/1, /*Tre*/1, /*Quattro*/0, /*cinque*/0, /*Sei*/0, /*Sette*/0, /*Fante*/1, /*Cavallo*/1, /*Re*/1,
  /*Asso*/3, /*Due*/1, /*Tre*/1, /*Quattro*/0, /*cinque*/0, /*Sei*/0, /*Sette*/0, /*Fante*/1, /*Cavallo*/1, /*Re*/1,
  /*Asso*/3, /*Due*/1, /*Tre*/1, /*Quattro*/0, /*cinque*/0, /*Sei*/0, /*Sette*/0, /*Fante*/1, /*Cavallo*/1, /*Re*/1
}; 

static const char g_LetterName[] = 
{
  /*Asso*/'A', /*Due*/'2', /*Tre*/'3', /*Quattro*/'4', /*cinque*/'5', /*Sei*/'6', /*Sette*/'7', /*Fante*/'F', /*Cavallo*/'C', /*Re*/'R',
  /*Asso*/'A', /*Due*/'2', /*Tre*/'3', /*Quattro*/'4', /*cinque*/'5', /*Sei*/'6', /*Sette*/'7', /*Fante*/'F', /*Cavallo*/'C', /*Re*/'R',
  /*Asso*/'A', /*Due*/'2', /*Tre*/'3', /*Quattro*/'4', /*cinque*/'5', /*Sei*/'6', /*Sette*/'7', /*Fante*/'F', /*Cavallo*/'C', /*Re*/'R',
  /*Asso*/'A', /*Due*/'2', /*Tre*/'3', /*Quattro*/'4', /*cinque*/'5', /*Sei*/'6', /*Sette*/'7', /*Fante*/'F', /*Cavallo*/'C', /*Re*/'R'
};

static const std::string g_CardsNameX[]=
{
  "Asso di bastoni", "Due di bastoni", "Tre di bastoni", "Quattro di bastoni", "Cinque di bastoni","Sei di bastoni", "Sette di bastoni", "Fante di bastoni", "Cavallo di bastoni", "Re di bastoni",
  "Asso di  coppe", "Due di  coppe", "Tre di  coppe", "Quattro di  coppe", "Cinque di  coppe", "Sei di  coppe", "Sette di  coppe", "Fante di  coppe", "Cavallo di  coppe", "Re di  coppe",
  "Asso di  denari", "Due di  denari", "Tre di  denari", "Quattro di  denari", "Cinque di  denari", "Sei di  denari", "Sette di  denari", "Fante di  denari", "Cavallo di  denari", "Re di  denari",
  "Asso di  spade", "Due di  spade", "Tre di  spade", "Quattro di  spade", "Cinque di  spade", "Sei di  spade", "Sette di  spade", "Fante di  spade", "Cavallo di  spade", "Re di  spade"
};

static const std::string g_SuitName[] = 
{
    "Bastoni", "Coppe", "Denari", "Spade", "undef"
};

cCardItem::cCardItem()
{

}

cCardItem::~cCardItem()
{

}

////////////////////////////////////////
//       SetCardIndex
/*! 
// \param int itmpIndex : 
*/
void cCardItem::SetCardIndex(int itmpIndex)
{
    if (itmpIndex >= 0 && itmpIndex <= DECKSIZE)
    {
        card.byIndex = itmpIndex;
        card.iRank = g_RankTable[itmpIndex];
        chCardLetter = g_LetterName[itmpIndex];
        byPoints = g_PointsTable[itmpIndex];
    }
    else
    {
        return;
    }

    if (itmpIndex >= 0 && itmpIndex < DECKSIZE)
    {
        strcpy(card.CardName, const_cast<char*>(g_CardsNameX[itmpIndex].c_str()) );
    }

    if (card.byIndex >= 0 && card.byIndex < 10 )
    {
        card.eSuit = BASTONI;
        m_strSuitName = g_SuitName[BASTONI];
        chSuitLetter = g_SuitName[BASTONI].at(0) ;
    }
    else if (card.byIndex >= 10 && card.byIndex < 20 )
    {
        card.eSuit = COPPE;
        m_strSuitName = g_SuitName[COPPE];
        chSuitLetter = g_SuitName[COPPE].at(0) ;
    }
    else if (card.byIndex >= 20 && card.byIndex < 30 )
    {
        card.eSuit = DENARI;
        m_strSuitName = g_SuitName[DENARI];
        chSuitLetter = g_SuitName[DENARI].at(0) ;
    }
    else if (card.byIndex  >= 30 && card.byIndex < 40 )
    {
        card.eSuit = SPADE;
        m_strSuitName = g_SuitName[SPADE];
        chSuitLetter = g_SuitName[SPADE].at(0) ;
    }
    else
    {
        card.eSuit = UNDEF;
        m_strSuitName = g_SuitName[UNDEF];
        chSuitLetter = g_SuitName[UNDEF].at(0) ;
    }
}



////////////////////////////////////////
//       LetterToIndex
/*! 
// \param char lett : 
*/
int cCardItem::LetterToIndex(char lett)
{
    int iRet = -1;
    switch(lett)
    {
    case 'A':
        iRet = 0;
        break;
    case '2':
        iRet = 1;
        break;
    case '3':
        iRet = 2;
        break;
    case '4':
        iRet = 3;
        break;
    case '5':
        iRet = 4;
        break;
    case '6':
        iRet = 5;
        break;
    case '7':
        iRet = 6;
        break;
    case 'F':
        iRet = 7;
        break;
    case 'C':
        iRet = 8;
        break;
    case 'R':
        iRet = 9;
        break;
    default:
        ASSERT(0);
        break;
    }

    return iRet;
}


////////////////////////////////////////
//       CardCompareSbF
/*! Compare two card. Say about if the second card is bigger as the first.
// \param cCardItem* pFirst : 
// \param cCardItem* pSecond :
// \return return -1 if the second is smaller, 0 if first is equal the second, 1 if the second is bigger as the first 
*/
int cCardItem::CardCompareSbF(cCardItem* pFirst, cCardItem* pSecond)
{
    int iRet = 0;
    if (pFirst->card.eSuit == pSecond->card.eSuit )
    {
        if (pFirst->card.iRank < pSecond->card.iRank )
        {
            iRet = 1;
        }
        else if (pFirst->card.iRank ==  pSecond->card.iRank)
        {
            iRet = 0;
        }
        else
        {
            iRet = -1;
        }
    }
    else
    {
        iRet = -1;
    }
    return iRet;
}

