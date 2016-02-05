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


// cCardItem.h: interface for the cCardItem class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_CCARDITEM_H__1F659C33_A31B_4EE8_BC51_1456F440E7F1__INCLUDED_)
#define AFX_CCARDITEM_H__1F659C33_A31B_4EE8_BC51_1456F440E7F1__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#include "InfoComm.h"
#include <string>
#include "ConstSearchAlpha.h"
#include <deque>





//! class cCardItem
class cCardItem  
{
    
public:
	cCardItem();
	virtual ~cCardItem();

    void SetCardIndex(int itmpIndex);
    static int LetterToIndex(char lett);
    static int CardCompareSbF(cCardItem* pFirst, cCardItem* pSecond);

public:
    CARDINFO   card;
    char       chCardLetter;
    char       chSuitLetter;
    BYTE       byPoints;

private:
    std::string m_strSuitName;

};

typedef cCardItem* P_MYCARDITEM;
typedef std::deque<P_MYCARDITEM> CARDLIST; 
typedef CARDLIST::iterator CARDLIST_IT;


// Functor to sort the card list in ascending manner
class cmp2CardAscen
{
public:
    bool operator ()(const P_MYCARDITEM& Card_1, const P_MYCARDITEM& Card_2) const
    {
        if (Card_1->card.eSuit > Card_2->card.eSuit  )
        {
            // swap element
            return true;
        }
        else if (Card_1->card.eSuit == Card_2->card.eSuit)
        {
            if (Card_1->card.iRank > Card_2->card.iRank)
            {
                // bigger card, swap
                return true;
            }
            else
            {
                return false;
            }
        }
        else
        {
            // don't swap
            return false;
        }
    }
};

// Functor to sort the card list in descending manner. Using suit campare (same suit)
class cmp2CardDesc
{
public:
    bool operator ()(const P_MYCARDITEM& Card_1, const P_MYCARDITEM& Card_2) const
    {
        if (Card_1->card.eSuit < Card_2->card.eSuit  )
        {
            // swap element
            return true;
        }
        else if (Card_1->card.eSuit == Card_2->card.eSuit)
        {
            if (Card_1->card.iRank < Card_2->card.iRank)
            {
                // bigger card, swap
                return true;
            }
            else
            {
                return false;
            }
        }
        else
        {
            // don't swap
            return false;
        }
    }
};

// Functor to sort the card list in descending manner. Use only card value no matter wat the suite
class cmp2CardDescOnlyValue
{
public:
    bool operator ()(const P_MYCARDITEM& Card_1, const P_MYCARDITEM& Card_2) const
    {
        if (Card_1->byPoints < Card_2->byPoints)
        {
            // bigger card, swap
            return true;
        }
        else if (Card_1->byPoints == Card_2->byPoints)
        {
            if (Card_1->card.iRank < Card_2->card.iRank)
            {
                // bigger card, swap
                return true;
            }
            else
            {
                return false;
            }
        }
        else
        {
            return false;
        }       
    }
};

//! class cBestLine 
class cBestLine
{
public:
    cBestLine(){}
    void Clear(){m_CardListBest.clear(); m_vctPlayerList.clear();}

    CARDLIST  m_CardListBest;
    VCT_INT   m_vctPlayerList;

};

#endif // !defined(AFX_CCARDITEM_H__1F659C33_A31B_4EE8_BC51_1456F440E7F1__INCLUDED_)


