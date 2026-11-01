set(ADAPTER_H "${OPENCL_LOADER_DIR}/loader/windows/adapter.h")
if(EXISTS "${ADAPTER_H}")
    file(READ "${ADAPTER_H}" ORIGINAL_CONTENT)
    
    # Packt die Pragmas absolut sicher vor und hinter den Inhalt (ignoriert CRLF/LF komplett)
    set(HEADER_PRAGMA "#if defined(__GNUC__) || defined(__clang__)\n#pragma GCC diagnostic push\n#pragma GCC diagnostic ignored \"-Wpedantic\"\n#endif\n\n")
    set(FOOTER_PRAGMA "\n\n#if defined(__GNUC__) || defined(__clang__)\n#pragma GCC diagnostic pop\n#endif\n")
    
    file(WRITE "${ADAPTER_H}" "${HEADER_PRAGMA}${ORIGINAL_CONTENT}${FOOTER_PRAGMA}")
    message(STATUS "✅ [OpenCLeaR] Pragmas via CMake in adapter.h injiziert.")
endif()

