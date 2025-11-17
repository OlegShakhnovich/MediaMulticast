#pragma once

enum class UdpMulticastResult {
    STREAMING_COMPLETED = 0, /**< Streaming completed successfully. */
    NETWORK_ERROR,           /**< Socket error occured. */
    FILE_READING_ERROR,      /**< File reading error occured. */
    WRONG_FILE_FORMAT,       /**< Can't parse header of streaming file.
                                Probably incorrect file type. */
    INTERNAL_ERROR,          /**< Internal library error. */
    SOCKET_OPENING_FAILED    /**< Socket opening error. */
};

class IStreamingCallback {
   public:
    virtual ~IStreamingCallback() = default;

    virtual void onResult(UdpMulticastResult result) = 0;
};

class UdpMulticast {
   public:
    UdpMulticast(
        std::string filename_,
        SocketAddress streamingAddress_,
        IStreamingCallback* callback_,
        size_t targetBitrate_)
        : filename(filename_),
          streamingAddress(streamingAddress_),
          callback(callback_),
          targetBitrate(targetBitrate_) {
        net_init();
    }

    size_t stopStreaming() {
        // TODO
        return 0;
    }

    size_t getBitrate() const {
        // TODO
        return 0;
    }

    size_t getFileSize() const {
        // TODO
        return 0;
    }

    size_t getCurrentPosition() const {
        // TODO
        return 0;
    }

   private:
    std::string filename;
    SocketAddress streamingAddress;
    IStreamingCallback* callback;
    size_t targetBitrate;
};
