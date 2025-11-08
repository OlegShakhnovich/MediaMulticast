#include <filesystem>
#include <iostream>
#include <memory>
#include <string>

#include "networking/net_utils.hpp"
#include "networking/udp_multicast.hpp"
#include "udp_streaming_lib_export.h"

// return 0 on succeess and non zero error code on error
int make_address(const std::string& host, const std::string& port, SocketAddress* addr) {
    if (net_init()) {
        return -1;  // Network init error
    };

    struct addrinfo hints{};
    struct addrinfo* res = nullptr;

    std::memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_UNSPEC;      // IPv4 или IPv6
    hints.ai_socktype = SOCK_STREAM;  // TCP

    int err = getaddrinfo(host.c_str(), port.c_str(), &hints, &res);
    if (err != 0) {
        return err;
    }

    SocketAddress out{};
    std::memcpy(&addr->storage, res->ai_addr, res->ai_addrlen);
    addr->length = static_cast<socklen_t>(res->ai_addrlen);

    freeaddrinfo(res);
    return 0;
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

        int res = make_address(address, port, &streamingAddress_);
        if (res) {
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
        }
    }

    size_t stopStreaming() {
        if (streamer_) {
            return streamer_->stopStreaming();
        }
        return STREAMING_LIB_ERROR_INVALID_CONTEXT;
    }

    size_t getBitrate() {
        if (streamer_) {
            return streamer_->getBitrate();
        }
        return STREAMING_LIB_ERROR_INVALID_CONTEXT;
    }

    size_t getFileSize() {
        if (streamer_) {
            return streamer_->getFileSize();
        }
        return STREAMING_LIB_ERROR_INVALID_CONTEXT;
    }

    size_t getCurrentPosition() {
        if (streamer_) {
            return streamer_->getCurrentPosition();
        }
        return STREAMING_LIB_ERROR_INVALID_CONTEXT;
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

UDP_STREAMING_LIB_API UdpStreamingLibResult startFileStreaming(UdpStreamingLibContext* context, char* filename, size_t filenameLength, char* address, size_t addressLength, char* port, size_t portLength, StreamingCallback callback, size_t targetBitrate) {
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