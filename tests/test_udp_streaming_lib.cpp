#include <gtest/gtest.h>

#include <string_view>

#include "udp_streaming_lib_export.h"

namespace {
constexpr std::string_view TEST_FILE_NAME = "test.ts";
constexpr std::string_view NONEXISTENT_FILE_NAME = "nonexistent_file.ts";
constexpr std::string_view TEST_IP = "127.0.0.1";
constexpr std::string_view INVALID_IP = "invalid_ip";
constexpr std::string_view TEST_PORT = "5000";
}  // namespace

class UdpStreamingLibTest : public ::testing::Test {
protected:
    auto SetUp() -> void override {
        ctx = udpStreamingLibCreate();
        ASSERT_NE(ctx, nullptr) << "udpStreamingLibCreate() returned NULL";
    }

    auto TearDown() -> void override {
        if (ctx != nullptr) {
            udpStreamingLibDestroy(ctx);
            ctx = nullptr;
        }
    }

    [[nodiscard]] auto getCtx() const -> UdpStreamingLibContext* { return ctx; }

private:
    UdpStreamingLibContext* ctx = nullptr;
    /*
    std::atomic<UdpStreamingLibCallbackResult> callbackResult{};
    std::atomic<bool> callbackCalled{false};

    static void testCallback(UdpStreamingLibTest* self, UdpStreamingLibCallbackResult result) {
        self->callbackResult = result;
        self->callbackCalled = true;
    }
    */
};

// ---------- Tests ----------

TEST_F(UdpStreamingLibTest, CreateAndDestroyContext) {
    ASSERT_NE(getCtx(), nullptr);
}

TEST(UdpStreamingLibTest, InvalidContextReturnsError) {
    const auto RES = startFileStreaming(
        nullptr,
        TEST_FILE_NAME.data(),
        TEST_FILE_NAME.size(),
        TEST_IP.data(),
        TEST_IP.size(),
        TEST_PORT.data(),
        TEST_PORT.size(),
        nullptr,
        0);

    EXPECT_EQ(RES, STREAMING_LIB_ERROR_INVALID_CONTEXT);
}

TEST_F(UdpStreamingLibTest, FileExists) {
    const auto RES = startFileStreaming(
        getCtx(),
        TEST_FILE_NAME.data(),
        TEST_FILE_NAME.size(),
        TEST_IP.data(),
        TEST_IP.size(),
        TEST_PORT.data(),
        TEST_PORT.size(),
        nullptr,
        0);

    EXPECT_EQ(RES, STREAMING_LIB_OK);
}

TEST_F(UdpStreamingLibTest, FileDoesNotExist) {
    const auto RES = startFileStreaming(
        getCtx(),
        NONEXISTENT_FILE_NAME.data(),
        NONEXISTENT_FILE_NAME.size(),
        TEST_IP.data(),
        TEST_IP.size(),
        TEST_PORT.data(),
        TEST_PORT.size(),
        nullptr,
        0);

    EXPECT_EQ(RES, STREAMING_LIB_ERROR_FILE_NOT_EXIST);
}

TEST_F(UdpStreamingLibTest, InvalidIpAddress) {
    const auto RES = startFileStreaming(
        getCtx(),
        TEST_FILE_NAME.data(),
        TEST_FILE_NAME.size(),
        INVALID_IP.data(),
        INVALID_IP.size(),
        TEST_PORT.data(),
        TEST_PORT.size(),
        nullptr,
        0);

    EXPECT_EQ(RES, STREAMING_LIB_ERROR_WRONG_IP_ADDRESS);
}

/*
TEST_F(UdpStreamingLibTest, CallbackIsInvoked) {
    callbackCalled = false;

    UdpStreamingLibResult res = startFileStreaming(ctx, (char*)"test.ts", strlen("test.ts"), (char*)"239.255.0.1",
        strlen("239.255.0.1"), (char*)"5000", strlen("5000"), testCallback, 0);

    if (res == STREAMING_LIB_OK) {
        // Waiting a callback call
        for (int i = 0; i < 50 && !callbackCalled; ++i) std::this_thread::sleep_for(std::chrono::milliseconds(100));

        EXPECT_TRUE(callbackCalled.load()) << "Callback didn't called";
    } else {
        GTEST_SKIP() << "Streaming init error (code " << res << ")";
    }
}
*/
