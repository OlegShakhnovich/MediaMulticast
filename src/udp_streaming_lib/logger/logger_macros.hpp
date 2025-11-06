#pragma once

#include <source_location>
#include <sstream>
#include <string_view>
#include <utility>

#include "logger.hpp"

namespace logsys {

// variable logger: builds "name = value" and logs with location
template <LogLevel Lvl, typename T>
inline void logVar(
    std::string_view name,
    T&& value,
    const std::source_location& loc = std::source_location::current()) {
    thread_local std::ostringstream oss;
    oss.str({});
    oss.clear();
    oss << name << " = " << std::forward<T>(value);
    Logger::instance().log(Lvl, loc.file_name(), loc.line(), oss.str());
}

template <typename... Args>
inline void trace(Args&&... args) {
    Logger::instance().logMsg<LogLevel::TRACE>(std::forward<Args>(args)...);
}

template <typename... Args>
inline void debug(Args&&... args) {
    Logger::instance().logMsg<LogLevel::DEBUG>(std::forward<Args>(args)...);
}

template <typename... Args>
inline void info(Args&&... args) {
    Logger::instance().logMsg<LogLevel::INFO>(std::forward<Args>(args)...);
}

template <typename... Args>
inline void warn(Args&&... args) {
    Logger::instance().logMsg<LogLevel::WARN>(std::forward<Args>(args)...);
}

template <typename... Args>
inline void error(Args&&... args) {
    Logger::instance().logMsg<LogLevel::ERROR>(std::forward<Args>(args)...);
}

template <typename... Args>
inline void fatal(Args&&... args) {
    Logger::instance().logMsg<LogLevel::FATAL>(std::forward<Args>(args)...);
}

}  // namespace logsys

// macro: log variable name automatically
#define LOG_VAR(var) ::logsys::logVar<LogLevel::DEBUG>(#var, (var))
