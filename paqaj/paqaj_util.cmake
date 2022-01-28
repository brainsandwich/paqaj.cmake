cmake_minimum_required(VERSION 3.16.0)

include(${CMAKE_CURRENT_LIST_DIR}/git_get.cmake)

# Send a message, using indentation prefix, and 
# if paqaj_settings_quiet is set to false / not set
#
# @param msg: message to display
function(paqaj_message msg)
    if (NOT paqaj_settings_quiet)
        message(VERBOSE "${_paqaj_indent}${msg}")
    endif()
endfunction()

# Unconditionally send a fatal error (stopping script)
#
# @param msg: message to display
function(paqaj_error msg)
    message(FATAL_ERROR "${_paqaj_indent}${msg}")
endfunction()

# Set a bunch of options
#
# @param options : list of options in the form <OPT> or <OPT=VALUE>
function(paqaj_set_options options)
    foreach(opt ${options})
        string(FIND ${opt} "=" equal_sign_pos)
        if (${equal_sign_pos} EQUAL -1)
            set(${opt} ON)
        else()
            math(EXPR value_pos "${equal_sign_pos} + 1")
            string(SUBSTRING ${opt} ${value_pos} -1 option_value)
            string(SUBSTRING ${opt} 0 ${equal_sign_pos} option_key)
            set(${option_key} ${option_value})
        endif()
    endforeach()
endfunction()

# Get paqaj_get_* function keywords
#
# @param options: toggleable options
# @param onevalued: options containing only one value
# @param multivalued: options containing a list of values
function(_paqaj_get_args options onevalued multivalued)
    set(${options}
        REQUIRED
        NO_SUBDIR
        NO_LOCAL
            PARENT_SCOPE
    )
    set(${onevalued}
        VERSION

        FETCH_GIT_REPOSITORY
        FETCH_GIT_TAG
        FETCH_GIT_BRANCH

        FETCH_URL
        FETCH_URL_HASH

        FIND_MODE
            PARENT_SCOPE
    )
    set(${multivalued}
        OPTIONS
        NAMES
        FIND_COMPONENTS
            PARENT_SCOPE
    )
endfunction()

# Extract directory project info (only version for now)
# Tries first with git, then cmake project(...) calls in ${dir}/CMakeLists.txt
#
# @param dir: project directory
# @param version: output version found
function(_paqaj_extract_subdir_info dir version)
    # Try extract version info from closest git tag
    if (EXISTS ${dir}/.git)
        git_get_current_tag(${dir} _tag)
        if (_tag)
            set(${version} ${_tag} PARENT_SCOPE)
            return()
        endif()

        git_get_current_branch(${dir} _branch)
        if (_branch)
            set(${version} ${_branch} PARENT_SCOPE)
            return()
        endif()

    # Else try to extract project(<package> VERSION) info
    elseif (EXISTS ${dir}/CMakeLists.txt)
        file(STRINGS ${dir}/CMakeLists.txt _project_calls REGEX "[\ \t]*project\\(")
        foreach (pcal ${_project_calls})
            string(REGEX MATCH "VERSION[\ \t]+([^\ \t\)]+)" _version_string ${pcal})
            if (_version_string)
                set(${version} ${CMAKE_MATCH_1} PARENT_SCOPE)
                return()
            endif()
        endforeach()
    endif()

endfunction()