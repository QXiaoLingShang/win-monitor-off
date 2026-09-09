#include <windows.h>
#include <stdio.h>
#include <wchar.h>

int main(void)
{
    /*
       保持可执行文件与 monitor_off.ps1 的行为一致。
       旧的原生实现会发送 SC_MONITORPOWER；在仅支持 S0 的笔记本上，
       这可能进入 Modern Standby 并暂停注入式桌面 Hook。
       现在由脚本使用原生的显示器空闲关闭路径。
    */
    wchar_t module_path[32768];
    DWORD length = GetModuleFileNameW(NULL, module_path, ARRAYSIZE(module_path));
    if (length == 0 || length >= ARRAYSIZE(module_path)) {
        return 1;
    }

    wchar_t *slash = wcsrchr(module_path, L'\\');
    if (slash == NULL) {
        return 1;
    }
    slash[1] = L'\0';

    wchar_t command_line[32768];
    int written = swprintf_s(
        command_line,
        ARRAYSIZE(command_line),
        L"powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"%smonitor_off.ps1\"",
        module_path);
    if (written < 0) {
        return 1;
    }

    STARTUPINFOW startup = { 0 };
    startup.cb = sizeof(startup);
    PROCESS_INFORMATION process = { 0 };
    if (!CreateProcessW(
            NULL,
            command_line,
            NULL,
            NULL,
            FALSE,
            CREATE_UNICODE_ENVIRONMENT,
            NULL,
            module_path,
            &startup,
            &process)) {
        return 1;
    }

    WaitForSingleObject(process.hProcess, INFINITE);
    DWORD exit_code = 1;
    GetExitCodeProcess(process.hProcess, &exit_code);
    CloseHandle(process.hThread);
    CloseHandle(process.hProcess);
    return (int)exit_code;
}
