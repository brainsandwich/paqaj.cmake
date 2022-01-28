cmake_minimum_required(VERSION 3.16.0)

include(CMakeParseArguments)
include(${CMAKE_CURRENT_LIST_DIR}/paqaj_util.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/paqaj_settings.cmake)

# Try to fetch package from local subdirectory that
# will be added to build process
#
# @param pname : package name, hopefully in lower_case
# @param success : return variable for boolean
# @param version : output valid version
# Other function arguments are defined by _paqaj_get_args
function(paqaj_fetch_subdir pname success version)
    set(prefix paqaj_${pname})
    _paqaj_get_args(_args_options _args_onevalued _args_multivalued)
    cmake_parse_arguments(${prefix} "${_args_options}" "${_args_onevalued}" "${_args_multivalued}" ${ARGN})
    
    set(_names ${pname})
    if (${prefix}_NAMES)
        list(APPEND _names "${${prefix}_NAMES}")
    endif()

    # Try for each possible package name
    foreach (_package_name ${_names})
        paqaj_message("Trying to find subdirectory using name [${_package_name}]")

        file(GLOB ${_package_name}_DIRS ${paqaj_settings_subdir_prefix}/*${_package_name}*)
        list(REVERSE ${_package_name}_DIRS)

        # If any add_subdirectory has a CMakeLists.txt,
        # use it
        foreach(dir ${${_package_name}_DIRS})
            if (EXISTS ${dir}/CMakeLists.txt)
                paqaj_message("Found suitable source directory: '${dir}'")
                if (NOT paqaj_settings_dry_run)
                    add_subdirectory(${dir} ${CMAKE_CURRENT_BINARY_DIR}/${_package_name})
                endif()

                _paqaj_extract_subdir_info(${dir} _version)
                set(${version} ${_version} PARENT_SCOPE)
                set(${success} 1 PARENT_SCOPE)
                return()
            endif()
        endforeach()
    endforeach()

    paqaj_message("No suitable source directory found")
    set(${success} 0 PARENT_SCOPE)
endfunction()