// NOLINTBEGIN
#pragma once

#include <stddef.h>
#include <stdint.h>

#if defined(_WIN32)
#ifdef UDP_STREAMING_LIB_EXPORTS
#define UDP_STREAMING_LIB_API __declspec(dllexport)
#else
#define UDP_STREAMING_LIB_API __declspec(dllimport)
#endif
#else
#define UDP_STREAMING_LIB_API
#endif

/**
 * @brief Return codes for
 * UDP_STREAMING_LIB_API API functions.
 */
typedef enum UdpStreaminLibResult {
    STREAMING_LIB_OK = 0,                   /**< Streaming started
                                               successfully. */
    STREAMING_LIB_ERROR_FILE_NOT_EXIST,     /**< Streaming file
                                               does not exist.
                                             */
    STREAMING_LIB_ERROR_WRONG_FILE_FORMAT,  /**< Can't parse
                                        header of streaming
                                        file.  Probably
                                        incorrect file type.
                                      */
    STREAMING_LIB_ERROR_WRONG_IP_ADDRESS,   /**< IP address
                                               can not be
                                               parsed. */
    STREAMING_LIB_ERROR_SOCKET_OPEN_FAILED, /**< Socket
                                               opening
                                               error. */
    STREAMING_LIB_ERROR_INTERNAL_ERROR      /**< Internal library
                                               error. */
} UdpStreaminLibResult;

/**
 * @brief Return code for streaming
 * completion callback.
 */
typedef enum UdpStreaminLibCallbackResult {
    STREAMING_COMPLETED = 0, /**< Streaming completed
                                successfully. */
    NETWORK_ERROR,           /**< Socket error
                                occured. */
    FILE_READING_ERROR       /**< File reading
                                error occured.
                              */
} UdpStreaminLibCallbackResult;

/**
 * @brief Callback function for
 * streaming completion callback.
 *
 * The callback is invoked when
 * streaming completes or when error
 * occured.
 *
 * The callback is executed in a
 * background thread.
 *
 * @param result    The streaming result
 * code.
 */
typedef void (*StreamingCallback)(UdpStreaminLibCallbackResult result);

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Start an asynchronous UDP
 * streaming of specified media file.
 *
 * Performs streaming in a background
 * thread and invokes the specified
 * callback function upon completion.
 * The result is passed through the
 * callback.
 *
 * @param filename  The path to input
 * media file. Only .ts, .wav and .mp4
 * files allowed.
 *
 * @param filenameLength  the length of
 * filename in characters.
 *
 * @param address multicast IP address
 *   A null-terminated string containing
 * either an IPv4 or IPv6 address,
 * without a port number. The library
 * automatically detects the address
 * type based on its format.
 *
 *   - **IPv4 format:** "192.168.1.10"
 *   - **IPv6 format:** "2001:db8::1" or
 * "::1"
 *
 *   Multicast addresses are also
 * supported:
 *
 *   - **IPv4 multicast range:**
 * 224.0.0.0 - 239.255.255.255
 * (224.0.0.0/4)
 *   - **IPv6 multicast range:**
 * FF00::/8 (all addresses beginning
 * with FF)
 *
 *   Example:
 *   @code
 *   ConnectToHost("ff02::1");       //
 * IPv6 multicast (link-local)
 * ConnectToHost("239.255.0.1");   //
 * IPv4 multicast
 *   @endcode
 *
 * @param addrLength the length of
 * address in characters.
 *
 * @param port multicast IP port
 *
 * @param callback completion callback
 * invoked when streaming completes or
 * when error occured. Optional, can be
 * set to NULL if not used.
 *
 * @param targetBitrate user bitrate in
 * bytes per sec. Optional, must be set
 * to 0 if not used. Normally bitrate
 * from media file header used.
 *
 * @return STREAMING_LIB_OK if the
 * streaming was started successfully,
 * or error code.
 *
 * @note This function does not block
 * the calling thread. The callback is
 * executed in a background thread.
 */
UDP_STREAMING_LIB_API
UdpStreaminLibResult startFileStreaming(
    char* filename,
    uint32_t filenameLength,
    char* address,
    uint32_t addrLength,
    uint16_t port,
    StreamingCallback callback = NULL,
    size_t targetBitrate = 0);

/**
 * @brief Stop an asynchronous UDP
 * streaming.
 *
 * @return amount of streamed bytes
 */
UDP_STREAMING_LIB_API size_t stopStreaming();

/**
 * @brief Return current streaming
 * bitrate
 */
UDP_STREAMING_LIB_API size_t getBitrate();

/**
 * @brief Return streaming file size
 */
UDP_STREAMING_LIB_API size_t getFileSize();

/**
 * @brief Return number of streamed
 * bytes
 */
UDP_STREAMING_LIB_API size_t getCurrentPosition();

#ifdef __cplusplus
}
#endif
// NOLINTEND
