#include <gtest/gtest.h>

#include "test_udp_streaming_lib.hpp"
#include "udp_streaming_lib_export.h"

static std::atomic<UdpStreamingLibCallbackResult> callbackResult; //NOLINT(cppcoreguidelines-avoid-non-const-global-variables)
static std::atomic<bool> callbackCalled{false};  //NOLINT(cppcoreguidelines-avoid-non-const-global-variables) 

void testCallback(UdpStreamingLibCallbackResult result) {
    callbackResult = result;
    callbackCalled = true;
}

class UdpStreamingLibTest : public ::testing::Test {
   protected:
    UdpStreamingLibContext* ctx = nullptr; //NOLINT(cppcoreguidelines-non-private-member-variables-in-classes,misc-non-private-member-variables-in-classes)

    void SetUp() override { // NOLINT(readability-identifier-naming)
        ctx = udpStreamingLibCreate();
        ASSERT_NE(ctx, nullptr) << "udpStreamingLibCreate() returns NULL";
    }

    void TearDown() override { // NOLINT(readability-identifier-naming)
        if (ctx != nullptr) {
            udpStreamingLibDestroy(ctx);
            ctx = nullptr;
        }
    }
};

// ---------- Tests ----------
TEST_F(UdpStreamingLibTest, CreateAndDestroyContext) { //NOLINT
    ASSERT_NE(ctx, nullptr);
}

TEST(UdpStreamingLibTest, InvalidContextReturnsError) { //NOLINT
    UdpStreamingLibResult res =
        startFileStreaming(nullptr, "test.ts", 7, "127.0.0.1", 9, "1234", 4, nullptr, 0); //NOLINT
    EXPECT_EQ(res, STREAMING_LIB_ERROR_INVALID_CONTEXT);
}

TEST_F(UdpStreamingLibTest, FileDoesNotExist) { //NOLINT
    UdpStreamingLibResult res = startFileStreaming(ctx, "nonexistent_file.ts", strlen("nonexistent_file.ts"), "127.0.0.1", strlen("127.0.0.1"), "5000", strlen("5000"), nullptr, 0); //NOLINT(cppcoreguidelines-init-variables)
    EXPECT_EQ(res, STREAMING_LIB_ERROR_FILE_NOT_EXIST);
}

TEST_F(UdpStreamingLibTest, InvalidIpAddress) { //NOLINT
    UdpStreamingLibResult res = startFileStreaming(ctx, "test.ts", strlen("test.ts"), "invalid_ip", strlen("invalid_ip"), "5000", strlen("5000"), nullptr, 0); //NOLINT(cppcoreguidelines-init-variables)
    EXPECT_EQ(res, STREAMING_LIB_ERROR_WRONG_IP_ADDRESS);
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
