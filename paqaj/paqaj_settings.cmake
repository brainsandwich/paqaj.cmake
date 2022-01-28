# Message prefix
set(_paqaj_indent)
set(_paqaj_cache ${CMAKE_CURRENT_BINARY_DIR}/paqaj_cache)

# Global paqaj settings
set(paqaj_settings_dry_run OFF)
set(paqaj_settings_quiet OFF)
set(paqaj_settings_fetch_remote ON)
set(paqaj_settings_fetch_subdir ON)
set(paqaj_settings_fetch_findpackage ON)
set(paqaj_settings_subdir_prefix ${CMAKE_CURRENT_SOURCE_DIR}/ext)