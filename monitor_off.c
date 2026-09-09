#include <windows.h>
#include <stdio.h>
#include <wchar.h>

static void print_last_error(const wchar_t *action)
{
    DWORD error = GetLastError();
    fwprintf(stderr, L"无法%s（错误码 %lu）。\n", action, (unsigned long)error);
}

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

    wchar_t script_path[32768];
    int script_written = swprintf_s(
        script_path,
        ARRAYSIZE(script_path),
        L"%smonitor_off.ps1",
        module_path);
    if (script_written < 0 || GetFileAttributesW(script_path) == INVALID_FILE_ATTRIBUTES) {
        fwprintf(stderr, L"找不到同目录下的 monitor_off.ps1，无法启动。\n");
        return 1;
    }

    wchar_t powershell_path[32768];
    DWORD powershell_length = SearchPathW(
        NULL,
        L"pwsh.exe",
        NULL,
        ARRAYSIZE(powershell_path),
        powershell_path,
        NULL);
    if (powershell_length == 0 || powershell_length >= ARRAYSIZE(powershell_path)) {
        powershell_length = SearchPathW(
            NULL,
            L"powershell.exe",
            NULL,
            ARRAYSIZE(powershell_path),
            powershell_path,
            NULL);
    }
    if (powershell_length == 0 || powershell_length >= ARRAYSIZE(powershell_path)) {
        fwprintf(stderr, L"找不到 PowerShell（pwsh.exe 或 powershell.exe）。\n");
        return 1;
    }

    wchar_t command_line[32768];
    int written = swprintf_s(
        command_line,
        ARRAYSIZE(command_line),
        L"\"%s\" -NoLogo -NoProfile -ExecutionPolicy Bypass -File \"%s\"",
        powershell_path,
        script_path);
    if (written < 0) {
        fwprintf(stderr, L"无法生成 PowerShell 启动参数。\n");
        return 1;
    }

    STARTUPINFOW startup = { 0 };
    startup.cb = sizeof(startup);
    PROCESS_INFORMATION process = { 0 };
    if (!CreateProcessW(
            powershell_path,
            command_line,
            NULL,
            NULL,
            FALSE,
            CREATE_UNICODE_ENVIRONMENT,
            NULL,
            module_path,
            &startup,
            &process)) {
        print_last_error(L"启动 PowerShell");
        return 1;
    }

    WaitForSingleObject(process.hProcess, INFINITE);
    DWORD exit_code = 1;
    GetExitCodeProcess(process.hProcess, &exit_code);
    CloseHandle(process.hThread);
    CloseHandle(process.hProcess);
    return (int)exit_code;
}
