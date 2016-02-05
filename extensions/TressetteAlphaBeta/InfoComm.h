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

// InfoComm.h

#ifndef __INFO_COMM_H
#define __INFO_COMM_H

#include <vector>

#ifndef BOOL 
    typedef int BOOL;
#endif

#ifndef BYTE
    typedef unsigned char BYTE;
#endif

//! suit of cards
enum eSUIT
{
    BASTONI = 0,
    COPPE = 1,
    DENARI = 2,
    SPADE = 3,
    UNDEF = 4
};

//! local game type
enum eTypeLocal
{
    LT_NEUTRO = 0,
    LT_BREDA, 
    LT_CHITARELLA,
    LT_ROMANA
};

//! what the player can say
enum eSayPlayer
{
    NOTHING,
    VOLO,
    BUSSO_LAMIGLIORE,
    STRISCIO_NEHOTANTE,
    PUNTO_ANCORAUNA,
    VIA_DAQUESTOGIOCO,
    HO_ILTRE,
    HO_ILDUE,
    HO_ASSO,
    LISCIO_NEHOANCORAPIUBASSE,
    PIOMBO_A_UNPALO,
    VOGLIO_ILVENTICINQUE,
    HO_ILVENTICINQUE,
    PIOMBO,
    BUSSO_ILTRE,
    RIBUSSO_ILDUE,
    LAMIGLIORE,
    ALTRE_CARTE
};

//! enum of goodgame
enum eDeclGoodGame
{
    TRE_TRE,
    TRE_DUE,
    TRE_ASSI,
    QUATTRO_TRE,
    QUATTRO_DUE,
    QUATTRO_ASSI,
    NAPOLETANA,
};

//! giocata score state
enum eGiocataScoreState
{
   SC_NOSCORE
};



#define NUM_BYTE_NAME 32

//! information about card
typedef struct _CardInfo
{
    //! index of the card
   BYTE   byIndex;
   //! seed of the card
   eSUIT  eSuit;
   //! name of the card
   char   CardName[NUM_BYTE_NAME];
   //! rank card
   int    iRank;
}CARDINFO;



//! class I_MatchScore
/** Interface to access information about the current match score.
*/
class I_MatchScore
{
public:
    I_MatchScore(){}
    virtual BOOL    IsGiocatEnd() = 0;
    virtual BOOL    IsGiocataMonte() = 0;
    virtual BOOL    IsManoPatada() = 0;
    virtual BOOL    IsGiocataPatada() = 0;
    virtual BOOL    IsMatchEnd() = 0;
    virtual int     GetManoWinner() = 0;
    virtual int     GetGiocataWinner() = 0;
    virtual int     GetMatchWinner() = 0;
    virtual int     GetPointsPlayer(int iPlayerIx) = 0;
    virtual int     GetManoNum() = 0;
    virtual BOOL    IsGameAbandoned() = 0;
    
};

typedef struct stSayDetail 
{
    //! call text name
    char        lpcText[128];
    //! say enum val
    eSayPlayer  eSay; 

}SayDetail; 

typedef struct stSayPlayer 
{
    //! player index
    int         iPlayerIx;
    //! say enum val
    eSayPlayer  eSay; 

}SayPlayer;     

typedef struct stGoodGameDetail
{
    //! good game call
    eDeclGoodGame  eGGval;
    //! suit no available
    eSUIT          eSManca;

}GoodGameDetail;

enum
{
    // trace channels
    TR_CORE_CH        = 0,
    TR_ALG_DEF_CH     = 1,
    TR_ALPHABETA_CH   = 2
};

typedef std::vector<SayPlayer>               VCT_SAYPLAYER;
typedef std::vector<SayDetail>               VCT_SIGNALS;
typedef std::vector<CARDINFO>                VCT_CARDINFO;
typedef std::vector<GoodGameDetail>          VCT_GOODGAMEDETAIL;
typedef CARDINFO*                            PCARDINFO;
typedef std::vector<PCARDINFO>               VCT_PCARDINFO;
typedef std::vector<VCT_CARDINFO>            ARR_CARDINFO;
typedef std::vector<int>                     VCT_INT;
typedef std::vector<eSUIT>                   VCT_SUITE;

//! class I_CORE_Game
/**Interface implemented by core game engine. This set of function are available
// to player algorithm to communicate with the core engine
*/
class I_CORE_Game
{
public:
    I_CORE_Game(){}
    //! player say something
    virtual BOOL Player_saySomething(int iPlayerIx, eSayPlayer eSay ) = 0;
    //! player play a card
    virtual BOOL Player_playCard(int iPlayerIx, CARDINFO* pCardInfo) = 0;
    //! player abandon the game
    virtual void  AbandonGame(int iPlayerIx) = 0;
    //! declare good game
    virtual BOOL  DeclareGoodGame(int iPlayerIx, eDeclGoodGame eValgg,  eSUIT eValsuit) = 0;
};


// Interface tracer
class I_GuiTracer
{
public:
    I_GuiTracer(){}
    virtual void    TraceData(const BYTE *pbyData, int nDataLen, char* pTextComment)=0;
    virtual void    Trace(const char* szFmt, ...)=0;
};



#endif
