/* win32_toolhelp.h — minimal Toolhelp32 prototypes for Vmem.
 *
 * The bundled tcc ships no tlhelp32.h, and V compiles with
 * -Werror=implicit-function-declaration (implicit decls would also truncate
 * HANDLE returns on x64). Signatures match the real <tlhelp32.h>; duplicate
 * identical prototypes are legal C if that header is included elsewhere.
 * Struct layouts live on the V side (vmem/sys/decl_windows.c.v mirrors) and
 * are passed as void pointers.
 */
#ifndef VMEM_WIN32_TOOLHELP_H
#define VMEM_WIN32_TOOLHELP_H

#include <windows.h>

WINBASEAPI HANDLE WINAPI CreateToolhelp32Snapshot(DWORD dwFlags, DWORD th32ProcessID);
WINBASEAPI BOOL WINAPI Process32FirstW(HANDLE hSnapshot, LPVOID lppe);
WINBASEAPI BOOL WINAPI Process32NextW(HANDLE hSnapshot, LPVOID lppe);
WINBASEAPI BOOL WINAPI Module32FirstW(HANDLE hSnapshot, LPVOID lppe);
WINBASEAPI BOOL WINAPI Module32NextW(HANDLE hSnapshot, LPVOID lppe);
WINBASEAPI BOOL WINAPI Thread32First(HANDLE hSnapshot, LPVOID lpte);
WINBASEAPI BOOL WINAPI Thread32Next(HANDLE hSnapshot, LPVOID lpte);

#endif /* VMEM_WIN32_TOOLHELP_H */
