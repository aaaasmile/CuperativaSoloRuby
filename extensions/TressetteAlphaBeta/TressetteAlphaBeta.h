// The following ifdef block is the standard way of creating macros which make exporting 
// from a DLL simpler. All files within this DLL are compiled with the TRESSETTEALPHABETA_EXPORTS
// symbol defined on the command line. this symbol should not be defined on any project
// that uses this DLL. This way any other project whose source files include this file see 
// TRESSETTEALPHABETA_API functions as being imported from a DLL, whereas this DLL sees symbols
// defined with this macro as being exported.
#ifdef TRESSETTEALPHABETA_EXPORTS
#define TRESSETTEALPHABETA_API __declspec(dllexport)
#else
#define TRESSETTEALPHABETA_API __declspec(dllimport)
#endif

// This class is exported from the TressetteAlphaBeta.dll
class TRESSETTEALPHABETA_API CTressetteAlphaBeta {
public:
	CTressetteAlphaBeta(void);
	// TODO: add your methods here.
};

extern TRESSETTEALPHABETA_API int nTressetteAlphaBeta;

TRESSETTEALPHABETA_API int fnTressetteAlphaBeta(void);
