#pragma once

#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#pragma comment(lib, "Ws2_32.lib")
#else
#include <arpa/inet.h>
#include <netdb.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>
#endif

struct SocketAddress {
    sockaddr_storage storage{};
    socklen_t length{};
    int errorCode{0};
};

// Network init for Windows. Returns non zero in case init failed
inline auto netInit() -> int {
#ifdef _WIN32
    static bool initialized = false;
    if (!initialized) {
        initialized = true;
        WSADATA wsaData;
        // NOLINTBEGIN
        return WSAStartup(MAKEWORD(2, 2), &wsaData);
        // NOLINTEND
    }
#endif
    return 0;
}

// Network finalization for Windows (optional)
inline void netCleanup() {
#ifdef _WIN32
    WSACleanup();
#endif
}
