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

// MySearchAlpha.cpp : Defines the entry point for the console application.
//

#define _CRTDBG_MAP_ALLOC


#include "stdafx.h"
#include "win_type_global.h"
#include "cAlgABSolver.h"
//#include "cSettings.h"

#include <cstdlib>
#include <crtdbg.h>




void readHandFromOptions(CARDINFO* currHand);



////////////////////////////////////////
//       main
/*! 
// \param int argc : 
// \param char* argv[] : 
*/
int main(int argc, char* argv[])
{
    //_CrtSetBreakAlloc(7222); // per i primi 158 allocazioni si tratta del costruttore static
                               // per intercettare questi breaks bisogna mettere un breakpoint in void * __cdecl _heap_alloc_dbg(
                               // file dbgheap.c

    //_CrtSetBreakAlloc(3628);
    //_CrtSetDbgFlag ( _CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF );

    // path of the exe
    // it appear that ::GetCommandLine() provides a path enclosed by ""
    STRING strCmdLine = ::GetCommandLine();
    STRING strDirName = ".";
    STRING strIniFileName;
    // isolate directory
    int indexCh1a = strCmdLine.rfind( '\\' );
    if (indexCh1a != std::string::npos )
    {
        strDirName = strCmdLine.substr(0,  indexCh1a);
        indexCh1a = strDirName.find_first_of( '"' );
        if (indexCh1a != std::string::npos)
        {
            int iLenDir = strDirName.length(); 
            strDirName = strDirName.substr(indexCh1a+1,  iLenDir - indexCh1a-1);
        }
    }
    

    //printf("command line is:\n%s\n", strCmdLine.c_str());

    // options ini file
    strIniFileName = strDirName + "\\" + "options.ini";
    //STRING strIniFileName2 = "D:\\eVision\\tressette\\src\\MySearchAlpha\\Debug\\options.ini";
    //TRACE("%s\n%s\n", strIniFileName.c_str() , strIniFileName2.c_str() );
    //FILE* fp = fopen(strIniFileName.c_str(), "r" );

    // load options
    SpaceSearchSettings::GetProfile(strIniFileName.c_str() );
    //SpaceSearchSettings::GetProfile("Software\\BredaSoft\\MySearchAlpha");
    //SpaceSearchSettings::WriteProfile("Software\\BredaSoft\\MySearchAlpha");
    //SpaceSearchSettings::WriteProfile("D:\\eVision\\tressette\\src\\MySearchAlpha\\Debug\\test.ini");
    {
    cAlgABSolver  ABSolver;

    ABSolver.InitDeck(); 

    CARDINFO currHand[searchalpha::DECKSIZE];
    
    // full the hand using settings
    readHandFromOptions(currHand);

    // nord
    ABSolver.SetHands(0,  &currHand[0], 10);
    // est
    ABSolver.SetHands(1,  &currHand[10], 10);
    // sud
    ABSolver.SetHands(2,  &currHand[20], 10);
    // west
    ABSolver.SetHands(3,  &currHand[30], 10);

    // set the beginner
    int iInitialPlayer = cAlgABSolver::PlayerNameToIndex(g_Options.All.inizia.c_str());
    ABSolver.SetInitialPlayer( iInitialPlayer ); 

    // solve the alg
    ABSolver.Solve(); 
    

    }
     

    printf("\nCalculation end\n");
    getchar();
	return 0;
}



////////////////////////////////////////
//       readHandFromOptions
/*! 
// \param CARDINFO& currHand : 
*/
void readHandFromOptions(CARDINFO* currHand)
{
    int iNumCardInsert = 0;
    while( iNumCardInsert < searchalpha::DECKSIZE)
    {
        
       // nord
       for (int j = 0; j < g_Options.nord.bastoni.length(); j++)
       {
            currHand[iNumCardInsert++].byIndex = cCardItem::LetterToIndex(g_Options.nord.bastoni[j]);
       }
       for (j = 0; j < g_Options.nord.coppe.length(); j++)
       {
            currHand[iNumCardInsert++].byIndex = 10 + cCardItem::LetterToIndex(g_Options.nord.coppe[j]);
       }    
       for (j = 0; j < g_Options.nord.denari.length(); j++)
       {
            currHand[iNumCardInsert++].byIndex = 20 + cCardItem::LetterToIndex(g_Options.nord.denari[j]);
       }
       for (j = 0; j < g_Options.nord.spade.length(); j++)
       {
            currHand[iNumCardInsert++].byIndex = 30 + cCardItem::LetterToIndex(g_Options.nord.spade[j]);
       }
       ASSERT(iNumCardInsert == 10);

       // est
       for ( j = 0; j < g_Options.est.bastoni.length(); j++)
       {
            currHand[iNumCardInsert++].byIndex = cCardItem::LetterToIndex(g_Options.est.bastoni[j]);
       }
       for (j = 0; j < g_Options.est.coppe.length(); j++)
       {
            currHand[iNumCardInsert++].byIndex = 10 + cCardItem::LetterToIndex(g_Options.est.coppe[j]);
       }    
       for (j = 0; j < g_Options.est.denari.length(); j++)
       {
            currHand[iNumCardInsert++].byIndex = 20 + cCardItem::LetterToIndex(g_Options.est.denari[j]);
       }
       for (j = 0; j < g_Options.est.spade.length(); j++)
       {
            currHand[iNumCardInsert++].byIndex = 30 + cCardItem::LetterToIndex(g_Options.est.spade[j]);
       }
       ASSERT(iNumCardInsert == 20);

       // sud
       for ( j = 0; j < g_Options.sud.bastoni.length(); j++)
       {
            currHand[iNumCardInsert++].byIndex = cCardItem::LetterToIndex(g_Options.sud.bastoni[j]);
       }
       for (j = 0; j < g_Options.sud.coppe.length(); j++)
       {
            currHand[iNumCardInsert++].byIndex = 10 + cCardItem::LetterToIndex(g_Options.sud.coppe[j]);
       }    
       for (j = 0; j < g_Options.sud.denari.length(); j++)
       {
            currHand[iNumCardInsert++].byIndex = 20 + cCardItem::LetterToIndex(g_Options.sud.denari[j]);
       }
       for (j = 0; j < g_Options.sud.spade.length(); j++)
       {
            currHand[iNumCardInsert++].byIndex = 30 + cCardItem::LetterToIndex(g_Options.sud.spade[j]);
       }
       ASSERT(iNumCardInsert == 30);

       // west
       for ( j = 0; j < g_Options.west.bastoni.length(); j++)
       {
            currHand[iNumCardInsert++].byIndex = cCardItem::LetterToIndex(g_Options.west.bastoni[j]);
       }
       for (j = 0; j < g_Options.west.coppe.length(); j++)
       {
            currHand[iNumCardInsert++].byIndex = 10 + cCardItem::LetterToIndex(g_Options.west.coppe[j]);
       }    
       for (j = 0; j < g_Options.west.denari.length(); j++)
       {
            currHand[iNumCardInsert++].byIndex = 20 + cCardItem::LetterToIndex(g_Options.west.denari[j]);
       }
       for (j = 0; j < g_Options.west.spade.length(); j++)
       {
            currHand[iNumCardInsert++].byIndex = 30 + cCardItem::LetterToIndex(g_Options.west.spade[j]);
       }
       ASSERT(iNumCardInsert == 40);
        
    }
}

