#pragma once

#include <cstring>
#include <string>

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
};

// Network init for Windows. Returns non zero in case init failed
inline int net_init() {
#ifdef _WIN32
    static bool initialized = false;
    if (!initialized) {
        initialized = true;
        WSADATA wsaData;
        return WSAStartup(MAKEWORD(2, 2), &wsaData);
    }
#endif
    return 0;
}

// Network finalization for Windows (optional)
inline void net_cleanup() {
#ifdef _WIN32
    WSACleanup();
#endif
}
