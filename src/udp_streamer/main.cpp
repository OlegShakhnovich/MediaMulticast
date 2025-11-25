// NOLINTBEGIN(bugprone-exception-escape
#include "file_reader/file_reader.hpp"

#include <fstream>
#include <ios>
#include <string>

#include "../udp_streaming_lib/logger/logger.hpp"
#include "../udp_streaming_lib/logger/logger_macros.hpp"
#include "file_reader/file_reader.hpp"

auto main() -> int {
    FileReader::doSomething();

    Logger::instance().setLevel(LogLevel::DEBUG);

    std::ofstream ofs("app.log", std::ios::app);
    if (ofs) {
        Logger::instance().setSink([&ofs](std::string str) -> void {
            ofs << str;
            std::cout << str;
        });
    }
    int MB_ZERO = 1;
    logsys::debug("HI", " ", &MB_ZERO, " ", MB_ZERO, " ", true);
    LOG_VAR(MB_ZERO);
    return 0;
}

// NOLINTEND