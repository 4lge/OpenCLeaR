set(ENVVARS_C "${OPENCL_LOADER_DIR}/loader/windows/icd_windows_envvars.c")
if(EXISTS "${ENVVARS_C}")
    file(READ "${ENVVARS_C}" CONTENTS)
    
    # 🎯 PRÄZISER FIX: Ersetzt ausschließlich die Definition in Zeile 43
    # Verhindert, dass GetCurrentProcess() oder Aufrufe in Bedingungen verändert werden.
    string(REPLACE "static bool khrIcd_IsHighIntegrityLevel()" "static bool khrIcd_IsHighIntegrityLevel(void)" MODIFIED_CONTENTS "${CONTENTS}")
    
    # Sicherstellung für ältere/andere Funktionen, falls vorhanden (aber nur am Zeilenanfang!)
    string(REGEX REPLACE "\nstatic BOOL khrIcdOsVendorsEnv32Bit\\(\\)" "\nstatic BOOL khrIcdOsVendorsEnv32Bit(void)" MODIFIED_CONTENTS "${MODIFIED_CONTENTS}")
    string(REGEX REPLACE "\nstatic BOOL khrIcdOsVendorsEnvRecurse\\(\\)" "\nstatic BOOL khrIcdOsVendorsEnvRecurse(void)" MODIFIED_CONTENTS "${MODIFIED_CONTENTS}")
    
    file(WRITE "${ENVVARS_C}" "${MODIFIED_CONTENTS}")
    message(STATUS "✅ [OpenCLeaR] Nur die echten Funktionsdefinitionen wurden modifiziert.")
endif()

