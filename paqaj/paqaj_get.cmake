cmake_minimum_required(VERSION 3.16.0)

include(CMakeParseArguments)
include(${CMAKE_CURRENT_LIST_DIR}/paqaj_settings.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/paqaj_util.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/paqaj_fetch_findpackage.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/paqaj_fetch_subdir.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/paqaj_fetch_remote.cmake)


# Retrieve a package
# 
# Controlled by paqaj_settings_* variables
# Looks for packages first using find_package, then
# a subdirectory in paqaj_settings_subdir_prefix, and finally
# tries to fetch content via URL or GIT_REPOSITORY
#
# @param pname : package name, hopefully in lower_case
# Other function arguments are defined by _paqaj_get_args
function(paqaj_get pname)

    # Functions args
    set(prefix paqaj_${pname})
    _paqaj_get_args(_args_options _args_onevalued _args_multivalued)
    cmake_parse_arguments(${prefix} "${_args_options}" "${_args_onevalued}" "${_args_multivalued}" ${ARGN})

    set(paqaj_${pname}_found 1 PARENT_SCOPE)
    if (${prefix}_VERSION)
        message(CHECK_START "Getting package ${pname} [${${prefix}_VERSION}]")
    else()
        message(CHECK_START "Getting package ${pname}")
    endif()
    set(_paqaj_indent "[${pname}] ")

    # Set package options
    if (${prefix}_OPTIONS)
        paqaj_set_options(${${prefix}_OPTIONS})
    endif()

    # Try to fetch via find_package
    if (paqaj_settings_fetch_findpackage)
        paqaj_fetch_findpackage(${pname} _fetch_success _version ${ARGN})
        if (_fetch_success)
            message(CHECK_PASS "found (local package, version '${_version}')")
            return()
        endif()
    endif()

    # Try to fetch via add_subdirectory
    if (paqaj_settings_fetch_subdir)
        paqaj_fetch_subdir(${pname} _fetch_success _version ${ARGN})
        if (_fetch_success)
            message(CHECK_PASS "found (subdirectory, version '${_version}')")
            return()
        endif()
    endif()

    # Try to fetch via FetchContent
    if (paqaj_settings_fetch_remote)
        paqaj_fetch_remote(${pname} _fetch_success _version ${ARGN})
        if (_fetch_success)
            message(CHECK_PASS "found (remote source, version '${_version}')")
            return()
        endif()
    endif()

    # No luck finding the package
    set(paqaj_${pname}_found 0 PARENT_SCOPE)
    if (${prefix}_REQUIRED)
        message(CHECK_FAIL "not found")
        paqaj_error("Package not found and marked as REQUIRED")
    elseif (NOT ${prefix}_QUIET)
        message(CHECK_FAIL "not found")
    endif()
endfunction()