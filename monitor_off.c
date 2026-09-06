#include <windows.h>

int main(void)
{
    /* 功能: 让显示器立刻黑屏关闭同时保证后台运行。 */
    /* HWND_BROADCAST  -> 广播给所有顶层窗口
       WM_SYSCOMMAND   -> 发送系统菜单命令
       SC_MONITORPOWER -> 电源管理命令
       2               -> 关闭显示器 (-1=打开, 1=低功耗) 
    */
    SendMessage(HWND_BROADCAST, WM_SYSCOMMAND, SC_MONITORPOWER, 2);
    return 0;
}
