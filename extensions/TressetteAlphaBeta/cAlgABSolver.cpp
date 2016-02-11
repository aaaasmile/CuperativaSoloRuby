// cAlgABSolver.cpp: implementation of the cAlgABSolver class.
//
//////////////////////////////////////////////////////////////////////

#include "StdAfx.h"
#include "cStateAB.h"
#include "cAlgABSolver.h"
#include "cCardItem.h"
#include "TraceService.h"

#ifndef _MSC_VER
#include <sys/time.h>
#endif


using namespace searchalpha;

static BYTE  getNextPlayerIndex(BYTE byPlIx) { byPlIx++; if (byPlIx >= searchalpha::PLAYERCOUNT) { byPlIx = 0; }return byPlIx; }

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

cAlgABSolver::cAlgABSolver()
{
    m_iVerboseLevel = 3;
    m_iSearchdHandDeph = 8;
    m_uiMaxCalcTime = 2000;
    m_pTracer = 0;
}

cAlgABSolver::~cAlgABSolver()
{

}


////////////////////////////////////////
//       InitDeck
/*! Initialize the deck
*/
void cAlgABSolver::InitDeck()
{
    m_pTracer = TraceService::Instance();

    for (int i = 0; i < DECKSIZE; i++)
    {
        m_Deck[i].SetCardIndex(i);
    }
}


////////////////////////////////////////
//       SetHands
/*! Set a player hands
// \param int  iPlayerIx : player index
// \param CARDINFO* arrCards : array of card indexes
// \param int iNumItem : number of item
*/
void cAlgABSolver::SetHands(int  iPlayerIx, int* arrCards, int iNumItem)
{
    CARDLIST handSubmit;
    for (int i = 0; i < iNumItem; i++)
    {
        ASSERT(arrCards[i] != NOT_VALID_INDEX);
        BOOL bCardFound = FALSE;
        for (int j = 0; !bCardFound && j < DECKSIZE; j++)
        {
            if (m_Deck[j].card.byIndex == arrCards[i])
            {
                bCardFound = TRUE;
                handSubmit.push_back(&m_Deck[j]);
            }
        }
        ASSERT(bCardFound); // do you have call InitDeck?
    }
    m_StateInitial.SetTrickLeft(iNumItem);
    m_StateInitial.AddCards(iPlayerIx, handSubmit);
}


////////////////////////////////////////
//       SetCurrTrickHistory
/*! Set the current trick history
// \param CARDINFO* arrCards : array of cards played in the current trick
// \param int iNumItem : number of items played
// \param int iPlIx_Start : player index that start the trick
*/
void cAlgABSolver::SetCurrTrickHistory(int iPlIx_Start, CARDINFO* arrCards, int iNumItem)
{
    ASSERT(arrCards);
    CARDLIST trickHist;
    for (int i = 0; i < iNumItem; i++)
    {
        BOOL bCardFound = FALSE;
        for (int j = 0; !bCardFound && j < DECKSIZE; j++)
        {
            if (m_Deck[j].card.byIndex == arrCards[i].byIndex)
            {
                bCardFound = TRUE;
                trickHist.push_back(&m_Deck[j]);
            }
        }
        ASSERT(bCardFound); // do you have call InitDeck?
    }
    m_StateInitial.AddTrickHist(iPlIx_Start, trickHist);

}


////////////////////////////////////////
//       PlayerNameToIndex
/*!
// \param LPCSTR lpstrName :
*/
int cAlgABSolver::PlayerNameToIndex(LPCSTR lpstrName)
{
    int iRetIx = 0;
    STRING strName = lpstrName;
    if (strName.compare("nord") == 0)
    {
        iRetIx = 0;
    }
    else if (strName.compare("est") == 0)
    {
        iRetIx = 1;
    }
    else if (strName.compare("sud") == 0)
    {
        iRetIx = 2;
    }
    else if (strName.compare("west") == 0)
    {
        iRetIx = 3;
    }
    else
    {
        ASSERT(0);
    }
    return iRetIx;
}


////////////////////////////////////////
//       PlayerIndexToName
/*!
// \param BYTE byIndex :
*/
STRING cAlgABSolver::PlayerIndexToName(BYTE byIndex)
{
    STRING strName;
    switch (byIndex)
    {
    case 0:
        strName = "nord";
        break;
    case 1:
        strName = "est";
        break;
    case 2:
        strName = "sud";
        break;
    case 3:
        strName = "west";
        break;
    default:
        ASSERT(0);
    }
    return strName;
}

////////////////////////////////////////
//       SetInitialPlayer
/*! Set the player that begin the game
// \param int  iPlayerIx :
*/
void cAlgABSolver::SetInitialPlayer(int  iPlayerIx)
{
    ASSERT(iPlayerIx >= 0 && iPlayerIx < PLAYERCOUNT);
    m_StateInitial.SetInitialPlayer(iPlayerIx);
}

////////////////////////////////////////
//       Solve
/*! Solve the algorithm alpha beta for tressette
*/
void  cAlgABSolver::Solve()
{
    m_lstMainLine.Clear();
    m_iNumOfCalc = 0;
    // display in stdout all cards
    renderHandStdOut();

    // check if available moves is only one
    CARDLIST lstLegalMoves;
    m_StateInitial.GenerateLegalMoves(lstLegalMoves);
    m_lstMainLine.m_CardListBest = lstLegalMoves;
    if (lstLegalMoves.size() == 1)
    {
        // only one legal move, don't need alpha beta
        renderBestLine(m_lstMainLine);
        m_lstMainLine.m_vctPlayerList.push_back(m_StateInitial.GetInitialPlayer());
        //TRACE("\nBest line: ");
        if (m_pTracer->AddNewEntry(TR_ALPHABETA_CH, EntryTraceDetail::TR_INFO, __FILE__, __LINE__))
            m_pTracer->AddCommentToLastEntry("Best line:");
        cStateAB::TraceCardListDbg(m_lstMainLine.m_CardListBest);
        return;
    }


    // Implements the follow algorithm:
    // http://www.seanet.com/~brucemo/topics/alphabeta.htm
    cStateAB* pCurrState = new cStateAB(m_StateInitial);

    int iInitialDepth = m_iSearchdHandDeph;

    /*
    _CrtMemState s1, s2, s3;
    _CrtMemCheckpoint(&s1);
    */


    m_uiInitialTime = getTicks();

    // start the alpha beta algorithm
    alphaBeta(iInitialDepth, -99, 99, pCurrState);

    delete pCurrState;


    // _CrtMemDumpAllObjectsSince(  &s1 );
    // _CrtDumpMemoryLeaks(  );
 /*
     _CrtMemCheckpoint( &s2 );
     if ( _CrtMemDifference( &s3, &s1, &s2 ) )
       _CrtMemDumpStatistics( &s3 );
 */

 //vrb(0, "\nNum of states: %d\n",  m_iNumOfCalc);
    if (m_pTracer->AddNewEntry(TR_ALPHABETA_CH, EntryTraceDetail::TR_INFO, __FILE__, __LINE__))
        m_pTracer->AddCommentToLastEntry("Num of states: %d", m_iNumOfCalc);


    // display the result in the debugger
    //TRACE("\nBest line: ");
    if (m_pTracer->AddNewEntry(TR_ALPHABETA_CH, EntryTraceDetail::TR_INFO, __FILE__, __LINE__))
        m_pTracer->AddCommentToLastEntry("Best line:");
    cStateAB::TraceCardListDbg(m_lstMainLine.m_CardListBest);

    if (m_pTracer->AddNewEntry(TR_ALPHABETA_CH, EntryTraceDetail::TR_INFO, __FILE__, __LINE__))
        m_pTracer->AddCommentToLastEntry("---- SOLVE TERMINATED  ( player %d )  ---", m_StateInitial.GetInitialPlayer());

    // display the best line on stdout
    renderBestLine(m_lstMainLine);
}



////////////////////////////////////////
//       GetBestCardToPlay
/*! Provides the best card to play
// \param CARDINFO* pCardInfo :
*/
void  cAlgABSolver::GetBestCardToPlay(int iPlayerIx, CARDINFO* pCardInfo)
{
    ASSERT(pCardInfo);
    int iCount = 0;
    if (m_lstMainLine.m_CardListBest.size() > 0 &&
        m_lstMainLine.m_vctPlayerList.size() > 0)
    {

        // the best line begin with card played by the first player
        int iPlayer_S = m_lstMainLine.m_vctPlayerList[0];
        int iPlayerNext = iPlayer_S;
        iCount = 0;
        while (iPlayerNext != iPlayerIx && iCount < searchalpha::PLAYERCOUNT)
        {
            iCount++;
            iPlayerNext = getNextPlayerIndex(iPlayerNext);
        }
        if ((UINT)iCount >= m_lstMainLine.m_CardListBest.size())
        {
            // something is wrong
            ASSERT(0);
            // just not to crash
            m_StateInitial.GenerateLegalMoves(m_lstMainLine.m_CardListBest);
            iCount = 0;
        }

        //cCardItem* pCard = m_lstMainLine.m_CardListBest[iCount];
        //*pCardInfo = pCard->card ;

    }
    else if (m_lstMainLine.m_CardListBest.size() > 0)
    {
        iCount = 0;
    }
    else
    {
        ASSERT(0);
        // just not to crash
        m_StateInitial.GenerateLegalMoves(m_lstMainLine.m_CardListBest);
        iCount = 0;
    }
    cCardItem* pCard = m_lstMainLine.m_CardListBest[iCount];
    *pCardInfo = pCard->card;
}

////////////////////////////////////////
//       alphaBeta
/*! Perform alpha beta algorithm
// \param int depth :
// \param int alpha :
// \param int beta :
*/
int cAlgABSolver::alphaBeta(int depth, int alpha, int beta, cStateAB* pCurrState)

{

    Uint32 uiNowTime = getTicks();
    if (uiNowTime - m_uiInitialTime > m_uiMaxCalcTime)
    {
        // time calculation elapsed
        // return something neutral
        pCurrState->SetTimeout();
        return 0;
    }

    m_iNumOfCalc++;
    /*
    if ( m_iNumOfCalc % 1000 == 0)
    {
        // stampa un resoconto intermedio
        alphaBeta_progress();
    }
    */

    if (pCurrState->GetTrickLeft() == 1)
    {
        return pCurrState->EvaluateLastTrick();
    }
    if (depth == 0)
    {
        return pCurrState->EvaluateState();
    }


    CARDLIST lstLegalMoves;
    pCurrState->GenerateLegalMoves(lstLegalMoves);

    for (UINT i = 0; i < lstLegalMoves.size(); i++)
    {

        cStateAB* pNextState = new cStateAB(pCurrState);
        pNextState->MakeMove(lstLegalMoves[i]);

        int val;

        if (pNextState->IsTeamOnTurnChanged())
        {
            // this is the usual turn-out. The team that have to move has changed, this a swap between min and max 
            val = -alphaBeta(depth - 1, -beta, -alpha, pNextState);
        }
        else
        {
            // this happen if the last player in trick, or his partner,  take the trick.
            // In such case there is no swap between minimize and maximize, we repeat the alg call in the same intervall
            val = alphaBeta(depth - 1, alpha, beta, pNextState);
        }

        if (pNextState->GetTimeout())
        {
            //timeout
            pCurrState->SetTimeout();
            delete pNextState;
            return 0;
        }

        if (val >= beta)
        {
            //pNextState->TraceTrickHistory(beta);
            delete pNextState;
            return beta;
        }

        if (val > alpha)
        {
            // save the main line
            alpha = val;
            cBestLine tmpBestList;
            pNextState->TraceTrickHistory(alpha);
            pNextState->GetBestLine(tmpBestList);
            if (tmpBestList.m_CardListBest[0]->card.byIndex != m_lstMainLine.m_CardListBest[0]->card.byIndex)
            {
                // main line is changed
                if (m_pTracer->AddNewEntry(TR_ALPHABETA_CH, EntryTraceDetail::TR_INFO, __FILE__, __LINE__))
                    m_pTracer->AddCommentToLastEntry("Main line is changed");

                //if (tmpBestList.m_CardListBest.size() >= m_lstMainLine.m_CardListBest.size() )
                {
                    m_lstMainLine = tmpBestList;
                }
            }
            renderBestLine(tmpBestList);

        }

        delete pNextState;
        pNextState = 0;
    }

    return alpha;
}



////////////////////////////////////////
//       alphaBeta_progress
/*! Display the search progress
*/
void  cAlgABSolver::alphaBeta_progress()
{
#ifndef _MSC_VER
    gettimeofday(&_start, NULL);
#endif
}

int cAlgABSolver::getTicks()
{
#ifdef _MSC_VER
    return ::GetTickCount();
#else
    Uint32 ticks;
    struct timeval now;
    gettimeofday(&now, NULL);
    ticks = (now.tv_sec - _start.tv_sec) * 1000 + (now.tv_usec - _start.tv_usec) / 1000;
    return(ticks);
#endif
}


////////////////////////////////////////
//       vrb
/*!
// \param int n :
// \param char* strPar :
// \param ... :
*/
void cAlgABSolver::vrb(int n, char* strPar, ...)
{
    char buff[512];
    if (m_iVerboseLevel > n)
    {
        va_list argptr;
        va_start(argptr, strPar);
        vsprintf(buff, strPar, argptr);
        va_end(argptr);
        fprintf(stdout, buff);
    }
}

////////////////////////////////////////
//       renderHandStdOut
/*! Render the state
*/
void cAlgABSolver::renderHandStdOut()
{
    STRING strPlayer = PlayerIndexToName(m_StateInitial.GetInitialPlayer());
    STRING strState = m_StateInitial.State_repr();
    //vrb(0, "lead: %s, ",  strPlayer.c_str());
    //vrb(0, "estimated %d tricks left to play\n", m_StateInitial.GetTrickLeft());
    //vrb(1, "\n%s\n", m_StateInitial.State_repr().c_str());
    if (m_pTracer->AddNewEntry(TR_ALPHABETA_CH, EntryTraceDetail::TR_INFO, __FILE__, __LINE__))
    {
        m_pTracer->AddCommentToLastEntry("lead: %s, estimated %d tricks left to play\n\n%s\n",
            strPlayer.c_str(), m_StateInitial.GetTrickLeft(), strState.c_str());
    }
}


////////////////////////////////////////
//       renderBestLine
/*! Display the current best line
// \param CARDLIST& lstMainLine :
*/
void cAlgABSolver::renderBestLine(cBestLine& lstMainLine)
{
    CHAR buff[512];
    UINT i;
    for (i = 0; i < lstMainLine.m_CardListBest.size(); i++)
    {
        cCardItem* pCard = lstMainLine.m_CardListBest[i];
        sprintf(&buff[3 * i], "%c%c ", pCard->chCardLetter, pCard->chSuitLetter);
    }
    CHAR bufFin[512];
    sprintf(bufFin, "\r%d :", m_iNumOfCalc);
    strcat(bufFin, buff);
    for (i = strlen(bufFin); i < 80; i++)
    {
        bufFin[i] = ' ';
    }
    bufFin[i++] = '\n';
    bufFin[i] = '\0';
    //fprintf(stdout, bufFin); 
    if (m_pTracer->AddNewEntry(TR_ALPHABETA_CH, EntryTraceDetail::TR_INFO, __FILE__, __LINE__))
        m_pTracer->AddCommentToLastEntry("%s", bufFin);
}


