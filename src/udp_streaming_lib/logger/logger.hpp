#pragma once

#include <array>
#include <atomic>
#include <chrono>
#include <cstdint>
#include <ctime>
#include <functional>
#include <iomanip>
#include <iostream>
#include <mutex>
#include <sstream>
#include <string>
#include <string_view>
#include <utility>

enum class LogLevel : uint8_t {
    TRACE = 0,
    DEBUG,
    INFO,
    WARN,
    ERROR,
    FATAL,
    OFF
};

class Logger {
   public:
    using Sink = std::function<void(std::string)>;

    Logger() noexcept
        : sink([](std::string msg) noexcept -> void {
              std::cout << std::forward<decltype(msg)>(msg);
          }) {}

    void setLevel(LogLevel level) noexcept {
        logLevel.store(level, std::memory_order_relaxed);
    }

    void setSink(Sink newSink) {
        const std::scoped_lock LOCK(mutex);
        sink = std::move(newSink);
    }

    template <typename... Args>
    void log(
        LogLevel lvl,
        std::string_view file,
        uint32_t line,
        Args&&... args) {
        const auto CURRENT_LEVEL = logLevel.load(std::memory_order_relaxed);
        if ((CURRENT_LEVEL == LogLevel::OFF) || (lvl < CURRENT_LEVEL)) {
            return;
        }

        thread_local std::ostringstream threadOss;
        threadOss.str({});
        threadOss.clear();

        threadOss << formatPrefix(lvl, file, line);
        (threadOss << ... << std::forward<Args>(args));
        threadOss << '\n';

        auto out = threadOss.str();

        Sink currentSink;
        {
            const std::scoped_lock LOCK(mutex);
            currentSink = sink;
        }
        currentSink(std::move(out));
    }

    template <LogLevel Lvl, typename... Args>
    void logMsg(Args&&... args) {
        log(Lvl, "", 0U, std::forward<Args>(args)...);
    }

    static auto instance() noexcept -> Logger& {
        static Logger inst;
        return inst;
    }

   private:
    std::atomic<LogLevel> logLevel{LogLevel::INFO};
    Sink sink;
    std::mutex mutex;

    static auto levelName(LogLevel level) noexcept -> std::string_view {
        static constexpr auto NAMES = std::to_array<std::string_view>(
            {"TRACE", "DEBUG", "INFO", "WARN", "ERROR", "FATAL", "OFF"});
        const auto IDNX = static_cast<size_t>(level);
        return NAMES.at(IDNX);
    }

    static auto timestamp() -> std::string {
        using namespace std::chrono;
        const auto NOW = system_clock::now();
        const auto SECONDS = duration_cast<std::chrono::seconds>(NOW.time_since_epoch()).count();
        const auto MSEC = duration_cast<milliseconds>(NOW.time_since_epoch()) % 1000;

        thread_local std::time_t lastSeconds = 0;
        thread_local std::string lastSecondsStr;
        thread_local std::ostringstream oss;

        if (static_cast<std::time_t>(SECONDS) != lastSeconds) {
            const auto TIME = static_cast<std::time_t>(SECONDS);
            std::tm localTm{};
#if defined(_WIN32) || defined(_WIN64)
            localtime_s(&localTm, &TIME);
#else
            localtime_r(&TIME, &localTm);
#endif
            oss.str({});
            oss.clear();
            oss << std::put_time(&localTm, "%Y-%m-%d %H:%M:%S");
            lastSecondsStr = oss.str();
            lastSeconds = static_cast<std::time_t>(SECONDS);
        }

        oss.str({});
        oss.clear();
        oss << lastSecondsStr << '.' << std::setw(3) << std::setfill('0')
            << MSEC.count();
        return oss.str();
    }

    static auto formatPrefix(
        LogLevel lvl,
        std::string_view file,
        uint32_t line) -> std::string {
        std::ostringstream oss;
        oss << timestamp() << " [" << levelName(lvl) << "] ";
        if (!file.empty()) {
            oss << file << ":" << line << ' ';
        }
        return oss.str();
    }
};
