#include <cstring>
#include <filesystem>
#include <memory>
#include <string>

#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#pragma comment(lib, "Ws2_32.lib")
#else
#include <netdb.h>
#include <sys/socket.h>
#include <sys/types.h>
#endif

#include "networking/net_utils.hpp"
#include "networking/udp_multicast.hpp"
#include "udp_streaming_lib_export.h"

namespace {
auto makeAddress(const std::string& host, const std::string& port) -> SocketAddress {
    SocketAddress res;
    res.length = 0;

    if (net_init()) {
        res.errorCode = -1;
        return res;  // Network init error
    };

    struct addrinfo hints {};
    struct addrinfo* sysaddr = nullptr;

    std::memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_UNSPEC;      // IPv4 или IPv6
    hints.ai_socktype = SOCK_STREAM;  // TCP

    const int ERR = getaddrinfo(host.c_str(), port.c_str(), &hints, &sysaddr);
    if (ERR != 0) {
        res.errorCode = ERR;
        return res;
    }

    std::memcpy(&res.storage, sysaddr->ai_addr, sysaddr->ai_addrlen);
    res.length = static_cast<socklen_t>(sysaddr->ai_addrlen);

    freeaddrinfo(sysaddr);
    return res;
}

auto safeString(const char* data, size_t length) -> std::string {
    if (data == nullptr || length == 0) {
        return {};  // return empty string if something wrong
    }
    return {data, length};
}
}  // namespace

class Streamer : public IStreamingCallback {
   public:
    Streamer(const Streamer&) = delete;
    Streamer(Streamer&&) = delete;
    auto operator=(const Streamer&) -> Streamer& = delete;
    auto operator=(Streamer&&) -> Streamer& = delete;
    ~Streamer() override = default;

    auto startFileStreaming(
        const std::string& filename_,
        const std::string& address_,
        const std::string& port_,
        StreamingCallback callback_,
        size_t targetBitrate_)
        -> UdpStreamingLibResult {
        if (!std::filesystem::exists(filename_)) {
            return STREAMING_LIB_ERROR_FILE_NOT_EXIST;
        }
        filename = filename_;

        streamingAddress = makeAddress(address_, port_);
        if (streamingAddress.length == 0) {
            return STREAMING_LIB_ERROR_WRONG_IP_ADDRESS;
        }

        callback = callback_;
        targetBitrate = targetBitrate_;

        streamer = std::make_unique<UdpMulticast>(filename, streamingAddress, this, targetBitrate);

        return STREAMING_LIB_OK;
    }

    void onResult(UdpMulticastResult result) override {
        if (callback == nullptr) {
            return;
        }
        switch (result) {
            case UdpMulticastResult::STREAMING_COMPLETED:
                callback(STREAMING_COMPLETED);
                break;
            case UdpMulticastResult::NETWORK_ERROR:
                callback(NETWORK_ERROR);
                break;
            case UdpMulticastResult::FILE_READING_ERROR:
                callback(FILE_READING_ERROR);
                break;
            case UdpMulticastResult::WRONG_FILE_FORMAT:
                callback(WRONG_FILE_FORMAT);
                break;
            case UdpMulticastResult::INTERNAL_ERROR:
                callback(INTERNAL_ERROR);
                break;
            case UdpMulticastResult::SOCKET_OPENING_FAILED:
                callback(SOCKET_OPENING_FAILED);
                break;
            default:
                callback(INTERNAL_ERROR);
                break;
        }
    }

    template <typename F>
    [[nodiscard]] auto callIfContextValid(F func) const -> size_t {
        if (streamer) {
            return func(streamer.get());
        }
        return STREAMING_LIB_ERROR_INVALID_CONTEXT;
    }

    [[nodiscard]] auto stopStreaming() const -> size_t {
        return callIfContextValid([](UdpMulticast* streamer) -> size_t { return streamer->stopStreaming(); });
    }

    [[nodiscard]] auto getBitrate() const -> size_t {
        return callIfContextValid([](UdpMulticast* streamer) -> size_t { return streamer->getBitrate(); });
    }

    [[nodiscard]] auto getFileSize() const -> size_t {
        return callIfContextValid([](UdpMulticast* streamer) -> size_t { return streamer->getFileSize(); });
    }

    [[nodiscard]] auto getCurrentPosition() const -> size_t {
        return callIfContextValid([](UdpMulticast* streamer) -> size_t { return streamer->getCurrentPosition(); });
    }

   private:
    std::unique_ptr<UdpMulticast> streamer;
    SocketAddress streamingAddress{};
    std::string filename;
    StreamingCallback callback;
    size_t targetBitrate;
};

// NOLINTBEGIN
#ifdef __cplusplus
extern "C" {
#endif

struct UdpStreamingLibContext {
    std::unique_ptr<Streamer> instance;
};

UDP_STREAMING_LIB_API auto startFileStreaming(
    UdpStreamingLibContext* context,
    const char* filename,
    size_t filenameLength,
    const char* address,
    size_t addressLength,
    const char* port,
    size_t portLength,
    StreamingCallback callback,
    size_t targetBitrate)
    -> UdpStreamingLibResult {
    if (context == nullptr) {
        return STREAMING_LIB_ERROR_INVALID_CONTEXT;
    }
    return context->instance->startFileStreaming(
        safeString(filename, filenameLength),
        safeString(address, addressLength),
        safeString(port, portLength),
        callback,
        targetBitrate);
}

UDP_STREAMING_LIB_API size_t stopStreaming(UdpStreamingLibContext* context) {
    if (context == nullptr) {
        return STREAMING_LIB_ERROR_INVALID_CONTEXT;
    }
    return context->instance->stopStreaming();
}

UDP_STREAMING_LIB_API size_t getBitrate(UdpStreamingLibContext* context) {
    if (context == nullptr) {
        return STREAMING_LIB_ERROR_INVALID_CONTEXT;
    }
    return context->instance->getBitrate();
}

UDP_STREAMING_LIB_API size_t getFileSize(UdpStreamingLibContext* context) {
    if (context == nullptr) {
        return STREAMING_LIB_ERROR_INVALID_CONTEXT;
    }
    return context->instance->getFileSize();
}

UDP_STREAMING_LIB_API size_t getCurrentPosition(UdpStreamingLibContext* context) {
    if (context == nullptr) {
        return STREAMING_LIB_ERROR_INVALID_CONTEXT;
    }
    return context->instance->getCurrentPosition();
}

// NOLINTEND
#ifdef __cplusplus
}
#endif
