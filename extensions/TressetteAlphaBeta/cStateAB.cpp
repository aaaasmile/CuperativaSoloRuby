// cStateAB.cpp: implementation of the cStateAB class.
//
//////////////////////////////////////////////////////////////////////

#include "StdAfx.h"
#include "cStateAB.h"
#include <algorithm>
#include <utility>
#include "TraceService.h"


using namespace searchalpha;

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

cStateAB::cStateAB()
{
    m_byTricksleft = 10;
    m_eSuit = UNDEF;
    m_arrTeamPoints[0] = 0;
    m_arrTeamPoints[1] = 0;
    m_id = 1;
    m_PlayerIx = 0;
    m_bTeamOnTurnChange = TRUE;
    m_bIsMaximize = TRUE;
    m_bTimeOut = FALSE;
}


cStateAB::cStateAB(cStateAB* pCopy)
{
    m_byTricksleft = pCopy->m_byTricksleft;
    m_eSuit = pCopy->m_eSuit;
    m_trickHist = pCopy->m_trickHist;
    m_PlayerIx = pCopy->m_PlayerIx;

    for (int i = 0; i < PLAYERCOUNT; i++)
    {
        m_HanPlayers[i] = pCopy->m_HanPlayers[i];
    }

    m_id = pCopy->m_id;
    m_arrTeamPoints[0] = pCopy->m_arrTeamPoints[0];
    m_arrTeamPoints[1] = pCopy->m_arrTeamPoints[1];
    m_bTeamOnTurnChange = pCopy->m_bTeamOnTurnChange;
    m_bIsMaximize = pCopy->m_bIsMaximize;
    m_bTimeOut = pCopy->m_bTimeOut;
}


cStateAB::~cStateAB()
{

}

////////////////////////////////////////
//       State_repr
/*! Provides the state in a string to be rendered.
*/
STRING cStateAB::State_repr()
{

    STRING strState;
    STRING suitbabble;
    int offset = 0;
    char babble[2048];
    char* bab = babble;
    int suit;

    // north
    for (suit = 0; suit < SUITCOUNT; ++suit)
    {
        bab += offset;
        suitbabble = m_HanPlayers[0].RenderSuit((eSUIT)suit);
        offset = sprintf(bab, "%13s%-20s\n", "", suitbabble.c_str());
    }

    // west - east
    for (suit = 0; suit < SUITCOUNT; ++suit)
    {
        bab += offset;
        suitbabble = m_HanPlayers[1].RenderSuit((eSUIT)suit);
        offset = sprintf(bab, "%1s%-20s", "", suitbabble.c_str());
        bab += offset;
        suitbabble = m_HanPlayers[3].RenderSuit((eSUIT)suit);
        offset = sprintf(bab, "%6s%-20s\n", "", suitbabble.c_str());
    }

    // south
    for (suit = 0; suit < SUITCOUNT; ++suit)
    {
        bab += offset;
        suitbabble = m_HanPlayers[2].RenderSuit((eSUIT)suit);
        offset = sprintf(bab, "%13s%-20s\n", "", suitbabble.c_str());
    }


    strState = babble;
    return strState;
}



////////////////////////////////////////
//       GenerateLegalMoves
/*! Provides all available moves using euristic.
// \param CARDLIST& cardlistState : card list result
*/
void cStateAB::GenerateLegalMoves(CARDLIST& cardlistState)
{
    if (m_eSuit == UNDEF)
    {
        narrowones_first(cardlistState);
    }
    else
    {
        takeit_or_leaveit(cardlistState);
    }
    //TraceCardListDbg(cardlistState);
}


////////////////////////////////////////
//       TraceCardListDbg
/*! Trace a card list in the debugger
// \param CARDLIST& cardlistState : card list to be traced
*/
void cStateAB::TraceCardListDbg(CARDLIST& cardlistState)
{
    CHAR buff[512];
    TraceService* pTracer = TraceService::Instance();
    for (UINT i = 0; i < cardlistState.size(); i++)
    {
        cCardItem* pCard = cardlistState[i];
        //TRACE("%c%c ",pCard->chCardLetter,pCard->chSuitLetter); 
        sprintf(&buff[3 * i], "%c%c ", pCard->chCardLetter, pCard->chSuitLetter);
    }
    //TRACE("\n");
    if (pTracer->AddNewEntry(TR_ALPHABETA_CH, 4, EntryTraceDetail::TR_INFO, __FILE__, __LINE__))
        pTracer->AddCommentToLastEntry("%s", buff);
}


////////////////////////////////////////
//       narrowones_first
/*! First player in the trick, provides all available cards sorted by better chance.
// \param CARDLIST& cardlistState : card list result
*/
void cStateAB::narrowones_first(CARDLIST& cardlistState)
{
    cardlistState.clear();

    int movecount[SUITCOUNT] = { 1, 1, 1, 1 };
    int suitorder[SUITCOUNT] = { 0, 1, 2, 3 };
    int i;

    // find the suit with more moves
    for (int player = 0; player < PLAYERCOUNT; ++player)
    {
        if (player == m_PlayerIx)
        {
            continue;
        }
        for (int suit = 0; suit < SUITCOUNT; ++suit)
        {
            int moves = m_HanPlayers[player].Suitlength((eSUIT)suit);
            if (moves > 0)
            {
                movecount[suit] *= moves;
            }
            else
            {
                m_HanPlayers[player].Length();
            }
        }
    }

    // sort the suit
    for (i = 1; i < SUITCOUNT; ++i)
    {
        for (int j = i - 1; j >= 0 && movecount[j] > movecount[i]; --j)
        {
            std::swap(movecount[j], movecount[i]);
            std::swap(suitorder[j], suitorder[i]);
            i = j;
        }
    }

    // now provides all cards of the player sorted by suit. Order is: first comes the suit 
    // with more combinations
    for (i = 0; i < SUITCOUNT; i++)
    {
        int iBestSuit = suitorder[i];
        CARDLIST TmpSuitPlayer = m_HanPlayers[m_PlayerIx].suitList[iBestSuit];
        //TraceCardListDbg(TmpSuitPlayer);
        for (UINT j = 0; j < TmpSuitPlayer.size(); j++)
        {
            cCardItem* pCard = TmpSuitPlayer[j];
            cardlistState.push_back(pCard);
        }
    }
    //TraceCardListDbg(cardlistState);
}


////////////////////////////////////////
//       takeit_or_leaveit
/*! Play as second, third or fourth
// \param CARDLIST& cardlistState :
*/
void cStateAB::takeit_or_leaveit(CARDLIST& cardlistState)
{
    cardlistState.clear();

    int iLastHistItemIx = m_trickHist.size() - 1;
    ASSERT(iLastHistItemIx >= 0);

    // get the last trick item
    TrickHistoryItem* pHistItem = &m_trickHist[iLastHistItemIx];

    // retrives the winning card
    int iCurrTrickLen = pHistItem->m_Trick.size();

    BYTE byPlTrickWinIx = 0;
    cCardItem* pWinCard = pHistItem->m_Trick[0];
    int i;
    for (i = 1; i < iCurrTrickLen; i++)
    {
        cCardItem* pCandCard = pHistItem->m_Trick[i];
        if (cCardItem::CardCompareSbF(pWinCard, pCandCard) > 0)
        {
            // ok, new winning card
            byPlTrickWinIx = i;
            pWinCard = pCandCard;
        }
    }

    // now create 2 list of cards, a winner and a loser

    CARDLIST lstWinner;
    CARDLIST lstLoser;
    CARDLIST* pListSuit = &(m_HanPlayers[m_PlayerIx].suitList[m_eSuit]);

    if (pListSuit->size() > 0)
    {
        // player can responce to suit
        for (UINT k = 0; k < pListSuit->size(); k++)
        {
            cCardItem* pMyCard = (*pListSuit)[k];
            if (cCardItem::CardCompareSbF(pWinCard, pMyCard) > 0)
            {
                // on the player hand there is winner card
                lstWinner.push_back(pMyCard);
            }
            else
            {
                lstLoser.push_back(pMyCard);
            }
        }
    }
    else
    {
        for (i = 0; i < SUITCOUNT; i++)
        {
            // the player can also refuse the suite, only loser cards
            pListSuit = &(m_HanPlayers[m_PlayerIx].suitList[(eSUIT)i]);
            for (UINT k = 0; k < pListSuit->size(); k++)
            {
                cCardItem* pMyCard = (*pListSuit)[k];
                lstLoser.push_back(pMyCard);
            }
        }
    }

    //TraceCardListDbg(lstLoser);
    //improve order of loser list: it is better to play lowest  cards
    std::sort(lstLoser.begin(), lstLoser.end(), cmp2CardDescOnlyValue());
    if (lstWinner.size() <= 3 && m_byTricksleft >= 5)
    {
        // the same also for winning card
        std::sort(lstWinner.begin(), lstWinner.end(), cmp2CardDescOnlyValue());
    }

    //TraceCardListDbg(lstWinner);
    //TraceCardListDbg(lstLoser);


    if (iCurrTrickLen == 1)
    {
        //  2 second player, try to take it
        cardlistState = lstWinner;
        appendList(cardlistState, lstLoser);
    }
    else if (iCurrTrickLen == 2)
    {
        //  3 third player
        if (byPlTrickWinIx == 0)
        {
            // teams already wins, leave it
            cardlistState = lstLoser;
            appendList(cardlistState, lstWinner);
        }
        else
        {
            // take it
            cardlistState = lstWinner;
            appendList(cardlistState, lstLoser);
        }

    }
    else if (iCurrTrickLen == 3)
    {
        // 4 fourth player
        if (byPlTrickWinIx == 1)
        {
            // teams already wins, leave it
            cardlistState = lstLoser;
            appendList(cardlistState, lstWinner);
        }
        else
        {
            // take it
            cardlistState = lstWinner;
            appendList(cardlistState, lstLoser);
        }

    }
    else
    {
        // lenght not correct
        ASSERT(0);
    }


    //TraceCardListDbg(cardlistState);
}


////////////////////////////////////////
//       appendList
/*! Append the second list to the first
// \param CARDLIST& lstFirst :
// \param CARDLIST& lstSecond :
*/
void cStateAB::appendList(CARDLIST& lstFirst, CARDLIST& lstSecond)
{
    for (UINT i = 0; i < lstSecond.size(); i++)
    {
        lstFirst.push_back(lstSecond[i]);
    }
}


////////////////////////////////////////
//       AddTrickHist
/*! Add the current trick history
// \param int iPlIx_Start : player that start the trick
// \param CARDLIST& trickHist : card list
*/
void cStateAB::AddTrickHist(int iPlIx_Start, CARDLIST& trickHist)
{
    if (getTeamIndex(m_PlayerIx) == getTeamIndex(iPlIx_Start))
    {
        // same team for the first player
        m_bIsMaximize = TRUE;
    }
    else
    {
        m_bIsMaximize = FALSE;
    }
    m_PlayerIx = iPlIx_Start;

    for (UINT i = 0; i < trickHist.size(); i++)
    {
        MakeMove(trickHist[i]);
    }
}


////////////////////////////////////////
//       SetInitialPlayer
/*! Set the player that begin to play, this is also the player for the algorithm is good for.
// \param int iVal :
*/
void  cStateAB::SetInitialPlayer(int iVal)
{
    m_PlayerIx = iVal;
    m_bIsMaximize = TRUE;
}

////////////////////////////////////////
//       MakeMove
/*! Make a move
// \param cCardItem* pCard :
*/
void  cStateAB::MakeMove(cCardItem* pCard)
{
    // remove the card from the hand
    m_HanPlayers[m_PlayerIx].PlayCard(pCard);

    // update history
    TrickHistoryItem* pLastItem = 0;
    int iNumTrick = m_trickHist.size();
    BOOL bAddNewTRick = FALSE;
    if (iNumTrick == 0)
    {
        // first trick, we need a new one
        bAddNewTRick = TRUE;
    }
    else
    {
        pLastItem = &(m_trickHist[iNumTrick - 1]);
        if (pLastItem->m_Trick.size() == PLAYERCOUNT)
        {
            // we need a new trick
            bAddNewTRick = TRUE;
        }
    }
    if (bAddNewTRick)
    {
        m_trickHist.push_back(TrickHistoryItem(m_PlayerIx, MAXNUMTRICKS - m_byTricksleft));
        iNumTrick = m_trickHist.size();
        pLastItem = &(m_trickHist[iNumTrick - 1]);
    }
    if (m_eSuit == UNDEF)
    {
        // first card played in the trick
        m_eSuit = pCard->card.eSuit;
    }
    ASSERT(pLastItem);
    // add card in the current trick
    pLastItem->m_Trick.push_back(pCard);
    // check if the trick is terminated
    if (pLastItem->m_Trick.size() == PLAYERCOUNT)
    {
        // --------  trick is terminated --------
        //TRACE("TRICK end:");TraceCardListDbg(pLastItem->m_Trick);

        BYTE byPlayerWinner = pLastItem->m_byPlayer_S;
        cCardItem* pWinCard = pLastItem->m_Trick[0];
        BYTE byPointsOnThisTrick = pWinCard->byPoints;
        // check the trick for the winning card
        for (int i = 1; i < PLAYERCOUNT; i++)
        {
            cCardItem* pCandCard = pLastItem->m_Trick[i];
            BYTE byPlayerCandidate = getPlayerIncremented(pLastItem->m_byPlayer_S, i);
            // accumulate also trick points
            byPointsOnThisTrick += pCandCard->byPoints;
            if (pWinCard->card.eSuit == pCandCard->card.eSuit)
            {
                // cards could be comparated
                if (pCandCard->card.iRank > pWinCard->card.iRank)
                {
                    // ok, new winning card
                    byPlayerWinner = byPlayerCandidate;
                    pWinCard = pCandCard;
                }
            }
        }
        pLastItem->m_byPlayer_T = byPlayerWinner;
        pLastItem->m_byPointsTrick = byPointsOnThisTrick;

        // update team points
        BYTE byTeamWinner = getTeamIndex(byPlayerWinner);
        m_arrTeamPoints[byTeamWinner] += byPointsOnThisTrick;
        // reset trick suit
        m_eSuit = UNDEF;
        m_byTricksleft--;
        // check if there is a team change on turn
        BYTE byTeamThatHavePlayedNow = getTeamIndex(m_PlayerIx);
        if (byTeamThatHavePlayedNow == byTeamWinner)
        {
            // in this case there is no change on intervall max-min
            m_bTeamOnTurnChange = FALSE;
            m_bIsMaximize = m_bIsMaximize;

        }
        else
        {
            // change in team turn
            m_bTeamOnTurnChange = TRUE;
            m_bIsMaximize = !m_bIsMaximize;
        }
        // next player is the trick winner
        m_PlayerIx = byPlayerWinner;
    }
    else
    {
        // next player is on turn 
        m_PlayerIx = getNextPlayerIndex(m_PlayerIx);
        m_bTeamOnTurnChange = TRUE;
        m_bIsMaximize = !m_bIsMaximize;
    }
}



////////////////////////////////////////
//       EvaluateState
/*! Evaluate the current state.
*/
int cStateAB::EvaluateState()
{
    int iLastHistItemIx = m_trickHist.size() - 1;
    ASSERT(iLastHistItemIx >= 0);
    // get the last trick item
    TrickHistoryItem* pHistItem = &m_trickHist[iLastHistItemIx];
    int iPoints = 0;

    if (pHistItem->m_Trick.size() == PLAYERCOUNT)
    {
        // evaluate only completed tricks

        // get the player index that have played first, it correspond to the maximize player
        TrickHistoryItem* pFirstItem = &(m_trickHist[0]);
        BYTE byTeamMaximize = getTeamIndex(pFirstItem->m_byPlayer_S);
        BYTE byTeamMinimize = !byTeamMaximize;

        // ritornando solo i punti l'algoritmo non funziona bene (avversario gioca assi terzi)
        // 

        if (m_bIsMaximize)
        {
            // maximize team
            iPoints = m_arrTeamPoints[byTeamMaximize];
        }
        else
        {
            // minimize team
            iPoints = m_arrTeamPoints[byTeamMinimize];
        }
    }
    else
    {
        // we make evaluation only at the end of the trick
        ASSERT(0);
    }

    return iPoints;
}


////////////////////////////////////////
//       EvaluateLastTrick
/*! Evaluate the last trick
*/
int cStateAB::EvaluateLastTrick()
{
    TrickHistoryItem* pLastItem = 0;
    int iNumTrick = m_trickHist.size();

    //ASSERT(iNumTrick == MAXNUMTRICKS - 1);

    pLastItem = &(m_trickHist[iNumTrick - 1]);

    BYTE byPlayerWinner = pLastItem->m_byPlayer_T;
    cCardItem* pWinCard = 0;
    // retrieves the last card
    pWinCard = m_HanPlayers[byPlayerWinner].GetLastPlayableCard();
    ASSERT(pWinCard);

    BYTE byPointsOnThisTrick = pWinCard->byPoints;
    // play the last trick
    for (int i = 1; i < PLAYERCOUNT; i++)
    {
        // the next player on table
        BYTE byPlayerCandidate = getPlayerIncremented(pLastItem->m_byPlayer_T, i);
        // the card that play
        cCardItem* pCandCard = m_HanPlayers[byPlayerCandidate].GetLastPlayableCard();
        ASSERT(pCandCard);

        // accumulate also trick points
        byPointsOnThisTrick += pCandCard->byPoints;
        if (pWinCard->card.eSuit == pCandCard->card.eSuit)
        {
            // cards could be comparated
            if (pCandCard->card.iRank > pWinCard->card.iRank)
            {
                // ok, new winning card
                byPlayerWinner = byPlayerCandidate;
                pWinCard = pCandCard;
            }
        }
    }

    // update team points
    BYTE byTeamWinner = getTeamIndex(byPlayerWinner);
    m_arrTeamPoints[byTeamWinner] += byPointsOnThisTrick;

    // add last hand points
    m_arrTeamPoints[byTeamWinner] += 3;

    BYTE byTeamStarter = getTeamIndex(pLastItem->m_byPlayer_T);
    if (byTeamStarter != byTeamWinner)
    {
        // the trick taker has changed
        m_bIsMaximize = !m_bIsMaximize;
    }


    // calculate return value
    TrickHistoryItem* pFirstItem = &(m_trickHist[0]);
    BYTE byTeamMaximize = getTeamIndex(pFirstItem->m_byPlayer_S);
    BYTE byTeamMinimize = !byTeamMaximize;

    int iPoints = 0;
    if (m_bIsMaximize)
    {
        // maximize team
        iPoints = m_arrTeamPoints[byTeamMaximize];
    }
    else
    {
        // minimize team
        iPoints = m_arrTeamPoints[byTeamMinimize];
    }

    return iPoints;

}

////////////////////////////////////////
//       TraceTrickHistory
/*! Trace the history
*/
void cStateAB::TraceTrickHistory(int iAlpha)
{
    TraceService* pTracer = TraceService::Instance();
    //TRACE("History:\n");
    if (pTracer->AddNewEntry(TR_ALPHABETA_CH, 5, EntryTraceDetail::TR_INFO, __FILE__, __LINE__))
        pTracer->AddCommentToLastEntry("cStateAB::History");
    for (UINT i = 0; i < m_trickHist.size(); i++)
    {
        //TRACE("Trick %d, alpha %d :", i, iAlpha);
        if (pTracer->AddNewEntry(TR_ALPHABETA_CH, 6, EntryTraceDetail::TR_INFO, __FILE__, __LINE__))
            pTracer->AddCommentToLastEntry("Trick %d, alpha %d :", i, iAlpha);

        TraceCardListDbg(m_trickHist[i].m_Trick);
    }
}


////////////////////////////////////////
//       GetBestLine
/*! Provides the best line
// \param CARDLIST& lstBest :
*/
void  cStateAB::GetBestLine(cBestLine& lstBest)
{
    lstBest.m_CardListBest.clear();
    lstBest.m_vctPlayerList.clear();

    for (UINT i = 0; i < m_trickHist.size(); i++)
    {
        int iPlayerIx = m_trickHist[i].m_byPlayer_S;
        for (UINT j = 0; j < m_trickHist[i].m_Trick.size(); j++)
        {
            lstBest.m_CardListBest.push_back(m_trickHist[i].m_Trick[j]);
            lstBest.m_vctPlayerList.push_back(iPlayerIx);
            iPlayerIx = getNextPlayerIndex(iPlayerIx);
        }
    }
}


////////////////////////////////////////
//       AddCards
/*! Add a cardlist to the player hand
// \param int iPlayerIx : player index
// \param CARDLIST& handSubmit : hand list to be submitted
*/
void  cStateAB::AddCards(int iPlayerIx, CARDLIST& handSubmit)
{
    ASSERT(iPlayerIx >= 0 && iPlayerIx < PLAYERCOUNT);
    m_HanPlayers[iPlayerIx].ResetHand();
    m_HanPlayers[iPlayerIx].AddCards(handSubmit);
}
