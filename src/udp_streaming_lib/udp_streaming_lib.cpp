#include <filesystem>
#include <iostream>
#include <memory>
#include <string>
#include <functional>
#include <utility>

#include "networking/net_utils.hpp"
#include "networking/udp_multicast.hpp"
#include "udp_streaming_lib_export.h"

static SocketAddress make_address(const std::string& host, const std::string& port) {
    SocketAddress res;
    res.length = 0;

    if (net_init()) {
        res.errorCode = -1;
        return res;  // Network init error
    };

    struct addrinfo hints{};
    struct addrinfo* sysaddr = nullptr;

    std::memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_UNSPEC;      // IPv4 или IPv6
    hints.ai_socktype = SOCK_STREAM;  // TCP

    int err = getaddrinfo(host.c_str(), port.c_str(), &hints, &sysaddr);
    if (err != 0) {
        res.errorCode = err;
        return res;
    }

    SocketAddress out{};
    std::memcpy(&res.storage, sysaddr->ai_addr, sysaddr->ai_addrlen);
    res.length = static_cast<socklen_t>(sysaddr->ai_addrlen);

    freeaddrinfo(sysaddr);
    return res;
}

class Streamer : public IStreamingCallback {
   public:
    ~Streamer() {
        if (streamer_) {
            delete streamer_;
            streamer_ = nullptr;
        }
    }

    UdpStreamingLibResult startFileStreaming(
        std::string filename, std::string address, std::string port, StreamingCallback callback, size_t targetBitrate) {
        if (!std::filesystem::exists(filename)) {
            return STREAMING_LIB_ERROR_FILE_NOT_EXIST;
        }
        filename_ = filename;

        streamingAddress_ = make_address(address, port);
        if (streamingAddress_.length == 0) {
            return STREAMING_LIB_ERROR_WRONG_IP_ADDRESS;
        }

        callback_ = callback;
        targetBitrate_ = targetBitrate;

        streamer_ = new UdpMulticast(filename_, streamingAddress_, this, targetBitrate);

        return STREAMING_LIB_OK;
    }

    void onResult(UdpMulticastResult result) {
        if (callback_ == nullptr) {
            return;
        }
        switch (result) {
            case UdpMulticastResult::STREAMING_COMPLETED:
                callback_(STREAMING_COMPLETED);
                break;
            case UdpMulticastResult::NETWORK_ERROR:
                callback_(NETWORK_ERROR);
                break;
            case UdpMulticastResult::FILE_READING_ERROR:
                callback_(FILE_READING_ERROR);
                break;
            case UdpMulticastResult::WRONG_FILE_FORMAT:
                callback_(WRONG_FILE_FORMAT);
                break;
            case UdpMulticastResult::INTERNAL_ERROR:
                callback_(INTERNAL_ERROR);
                break;
            case UdpMulticastResult::SOCKET_OPENING_FAILED:
                callback_(SOCKET_OPENING_FAILED);
                break;
            default:
                callback_(INTERNAL_ERROR);
                break;
        }
    }

    template <typename F>
    inline UdpStreamingLibResult callIfContextValid(F&& func) const {
        if (streamer_ != nullptr)
            return std::invoke(std::forward<F>(func), streamer_);
        return STREAMING_LIB_ERROR_INVALID_CONTEXT;
    }

    size_t stopStreaming() {
        return callIfContextValid(streamer_->stopStreaming());
    }

    size_t getBitrate() {
        return callIfContextValid( streamer_->getBitrate());
    }

    size_t getFileSize() {
        return callIfContextValid(streamer_->getFileSize());
    }

    size_t getCurrentPosition() {
        return callIfContextValid(streamer_->getCurrentPosition());
    }

   private:
    UdpMulticast* streamer_;
    SocketAddress streamingAddress_{};
    std::string filename_;
    StreamingCallback callback_;
    size_t targetBitrate_;
};

std::string safeString(const char* data, size_t length) {
    if (data == nullptr || length == 0) {
        return std::string();  // return empty string if something wrong
    }
    return std::string(data, length);
}

#ifdef __cplusplus
extern "C" {
#endif

struct UdpStreamingLibContext {
    std::unique_ptr<Streamer> instance;
};

UDP_STREAMING_LIB_API UdpStreamingLibResult startFileStreaming(
    UdpStreamingLibContext* context,
    const char* filename,
    size_t filenameLength,
    const char* address,
    size_t addressLength,
    const char* port,
    size_t portLength,
    StreamingCallback callback,
    size_t targetBitrate) {
    if (context == nullptr) {
        return STREAMING_LIB_ERROR_INVALID_CONTEXT;
    }
    return context->instance->startFileStreaming(safeString(filename, filenameLength), safeString(address, addressLength), safeString(port, portLength), callback, targetBitrate);
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

#ifdef __cplusplus
}
#endif
