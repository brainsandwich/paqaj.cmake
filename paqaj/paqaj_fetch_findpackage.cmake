cmake_minimum_required(VERSION 3.16.0)

include(CMakeParseArguments)
include(${CMAKE_CURRENT_LIST_DIR}/paqaj_compare_version.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/paqaj_util.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/paqaj_settings.cmake)

function(paqaj_fetch_findpackage_ name version mode components)
    find_package(${name} ${version} ${mode} COMPONENTS ${components} QUIET)
endfunction()

# Try to fetch prebuilt package locally using find_package
#
# @param pname : package name, hopefully in lower_case
# @param success : return variable for boolean
# @param version : output valid version found
# Other function arguments are defined by _paqaj_get_args
function(paqaj_fetch_findpackage pname success version)
    set(prefix paqaj_${pname})
    _paqaj_get_args(_args_options _args_onevalued _args_multivalued)
    cmake_parse_arguments(${prefix} "${_args_options}" "${_args_onevalued}" "${_args_multivalued}" ${ARGN})
    
    set(_names ${pname})
    if (${prefix}_NAMES)
        list(APPEND _names "${${prefix}_NAMES}")
    endif()

    # Try for each possible package name
    foreach (_package_name ${_names})
        paqaj_message("Trying to find package using name [${_package_name}]")

        # Build find_package arguments
        set(_find_args ${_package_name})
        if (${prefix}_VERSION)
            list(APPEND _find_args ${${prefix}_VERSION})
        endif()

        if (NOT ${${prefix}_FIND_MODE})
            set(${prefix}_FIND_MODE CONFIG)
        endif()
        list(APPEND _find_args ${${prefix}_FIND_MODE})
        
        set(_components_arg)
        if (${prefix}_FIND_COMPONENTS)
            # list(APPEND _find_args COMPONENTS ${${prefix}_FIND_COMPONENTS})
            set(_components_arg COMPONENTS ${${prefix}_FIND_COMPONENTS})
        endif()
        list(APPEND _find_args QUIET)

        if (NOT paqaj_settings_dry_run)
            find_package(${_find_args} ${_components_arg})
            if (${_package_name}_FOUND)
                paqaj_message("Found suitable local package")
                set(${version} ${${_package_name}_VERSION} PARENT_SCOPE)
                set(${success} 1 PARENT_SCOPE)
                return()
            else()
                # Try other versions considered
                if (${_package_name}_CONSIDERED_VERSIONS)
                    # paqaj_message("Considered package versions: ${${_package_name}_CONSIDERED_VERSIONS}, trying them")
                    foreach (ver ${${_package_name}_CONSIDERED_VERSIONS})
                        paqaj_compare_version(${${prefix}_VERSION} ${ver} _version_valid)
                        if (_version_valid)
                            find_package(${_package_name} ${ver} ${${prefix}_FIND_MODE} ${_components_arg})
                            if (${_package_name}_FOUND)
                                paqaj_message("Found suitable local package (version ${ver})")
                                set(${version} ${${_package_name}_VERSION} PARENT_SCOPE)
                                set(${success} 1 PARENT_SCOPE)
                                return()
                            endif()
                        endif()
                    endforeach()
                endif()

            endif()
        endif()

    endforeach()

    paqaj_message("No suitable local package found")
    set(${success} 0 PARENT_SCOPE)

endfunction()