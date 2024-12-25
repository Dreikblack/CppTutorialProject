//---------------------------------------------------------------------------------------------------------------------
//
// Include this file in your project to indicate the application should use a discrete card, if one is present.
// You can remove this file if your application is meant to run in low-performance / low-power mode.11
//
//---------------------------------------------------------------------------------------------------------------------

#ifdef _WIN32
#include <windows.h>

// This forces the use of a discrete card when switchable graphics are present:
// http://developer.download.nvidia.com/devzone/devcenter/gamegraphics/files/OptimusRenderingPolicies.pdf -  Page 3
extern "C"
{
	_declspec(dllexport) DWORD NvOptimusEnablement = 0x00000001;
	_declspec(dllexport) int AmdPowerXpressRequestHighPerformance = 1;
}

#endif