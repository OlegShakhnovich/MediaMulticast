#pragma once

#ifdef _WIN32
#ifdef UDP_STREAMING_LIB_EXPORTS
#define UDP_STREAMING_LIB_API __declspec(dllexport)
#else
#define UDP_STREAMING_LIB_API __declspec(dllimport)
#endif
#else
#define UDP_STREAMING_LIB_API
#endif
