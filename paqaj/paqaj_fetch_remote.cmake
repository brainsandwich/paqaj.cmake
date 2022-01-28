cmake_minimum_required(VERSION 3.16.0)

include(CMakeParseArguments)
include(${CMAKE_CURRENT_LIST_DIR}/paqaj_compare_version.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/paqaj_util.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/paqaj_settings.cmake)

# Prepare the hash and full FetchContent_Declare command
#
# @param pname: package name
# @param hash: output hash for this fetch
# @param command: output command to use in FetchContent_Declare
# @param version: output valid version (branch or tag, or nothing)
function(_paqaj_fetch_remote_prepare pname hash command version)
    set(_hash)
    set(_command)

    # Parse additional args
    set(prefix paqaj_${pname})
    _paqaj_get_args(_args_options _args_onevalued _args_multivalued)
    cmake_parse_arguments(${prefix} "${_args_options}" "${_args_onevalued}" "${_args_multivalued}" ${ARGN})

    # User wants to fetch from url
    # If no URL_HASH was provided, make out one with the
    # url itself ... goodenough
    if (${prefix}_FETCH_URL)
        set(_command "URL;${${prefix}_FETCH_URL}")
        if (${prefix}_FETCH_URL_HASH)
            set(_hash ${${prefix}_FETCH_URL_HASH})
            list(APPEND _command "URL_HASH;${${prefix}_FETCH_URL_HASH}")
        else()
            string(MD5 _hash ${${prefix}_FETCH_URL})
            paqaj_message("Note: You should specify a hash when fetching from URL ; using hashed url instead")
        endif()
        paqaj_message("Fetching package from url: '${${prefix}_FETCH_URL}'")
    
    # User wants to fetch from git repo
    elseif (${prefix}_FETCH_GIT_REPOSITORY)
        find_package(Git REQUIRED)

        set(_git_repo ${${prefix}_FETCH_GIT_REPOSITORY})
        set(_command "GIT_REPOSITORY;${_git_repo};GIT_SHALLOW")
        set(_paqaj_git_target "${_git_repo}")

        # Use tag for fetching
        if (${prefix}_FETCH_GIT_TAG)
            set(_git_tag ${prefix}_FETCH_GIT_TAG)
            git_get_commit(${_git_repo} ${_git_tag} _commit)
            if (NOT _commit)
                paqaj_message("Tag '${_git_tag}' not found on remote")
                return()
            endif()

            # Set command and hash
            set(${version} ${_git_tag} PARENT_SCOPE)
            set(_hash ${_commit})
            set(_paqaj_git_target "${_paqaj_git_target}#${${prefix}_FETCH_GIT_TAG}")
            list(APPEND _command "GIT_TAG;${prefix}_FETCH_GIT_TAG")
        
        # Use branch for fetching
        elseif (${prefix}_FETCH_GIT_BRANCH)
            set(_git_branch ${prefix}_FETCH_GIT_BRANCH)
            git_get_commit(${_git_repo} ${_git_branch} _commit)
            if (NOT _commit)
                paqaj_message("Branch '${_git_branch}' not found on remote")
                return()
            endif()
            
            # Set command and hash
            set(${version} ${_git_branch} PARENT_SCOPE)
            set(_hash ${_commit})
            set(_paqaj_git_target "${_paqaj_git_target}/${${prefix}_FETCH_GIT_BRANCH}")
            list(APPEND _command "GIT_BRANCH;${prefix}_FETCH_GIT_BRANCH")

        # Find out which tag to use, according to VERSION
        elseif(${prefix}_VERSION)
            set(_version ${${prefix}_VERSION})
            set(_valid_tag)

            # Get all refs on repo and keep only the tags
            git_get_refs(${_git_repo} tags)
            list(FILTER tags INCLUDE REGEX "refs/tags/")
            list(TRANSFORM tags REPLACE "refs/tags/" "")
            list(SORT tags COMPARE NATURAL ORDER DESCENDING)
            paqaj_message("Found these 'version' tags : ${tags}")

            # Find a suitable version amongst tags
            foreach(tag ${tags})
                paqaj_compare_version(${_version} ${tag} _is_version_valid)
                if (_is_version_valid)
                    set(_valid_tag ${tag})
                    break()
                endif()
            endforeach()

            # None was found
            if (NOT _valid_tag)
                paqaj_message("No suitable version found on remote")
                return()
            endif()
            
            # Get tag commit hash for caching
            set(${version} ${_valid_tag} PARENT_SCOPE)
            git_get_commit(${_git_repo} ${_valid_tag} _commit)
            set(_hash ${_commit})

            # Set command
            set(_paqaj_git_target "${_paqaj_git_target}#${_valid_tag}")
            list(APPEND _command "GIT_TAG;${_valid_tag}")

        # Use master/main branch for fetching
        else()
            git_get_commit(${_git_repo} HEAD _commit)
            set(${version} HEAD PARENT_SCOPE)
            set(_hash ${_commit})
        endif()

        paqaj_message("Fetching package from git repository: ${_paqaj_git_target}")
    
    # The user didn't provide with enough fetching info 
    else()
        paqaj_message("Missing FETCH_URL or FETCH_GIT_REPOSITORY")
        return()
    endif()

    # Set outputs
    set(${hash} ${_hash} PARENT_SCOPE)
    set(${command} ${_command} PARENT_SCOPE)
endfunction()

# Try to fetch package from remote (url or git_repo)
#
# @param pname : package name, hopefully in lower_case
# @param success : return variable for boolean
# @param version : output valid version
# Other function arguments are defined by _paqaj_get_args
function(paqaj_fetch_remote pname success version)
    set(prefix paqaj_${pname})
    _paqaj_get_args(_args_options _args_onevalued _args_multivalued)
    cmake_parse_arguments(${prefix} "${_args_options}" "${_args_onevalued}" "${_args_multivalued}" ${ARGN})

    set(${success} 1 PARENT_SCOPE)

    # Prepare the remote fetch command
    _paqaj_fetch_remote_prepare(${pname} _hash _command _version ${ARGN})
    if (NOT _command)
        set(${success} 0 PARENT_SCOPE)
        return()
    endif()

    # POPOLAT package, only if computed target
    # hash has changed since last retrieval 
    if (NOT paqaj_settings_dry_run)
        file(READ ${_paqaj_cache}/${pname}/hash ${pname}_fetch_hash)
        if (NOT ${pname}_fetch_hash EQUAL ${_hash})
            file(WRITE ${_paqaj_cache}/${pname}/hash ${_hash})
            include(FetchContent)
            FetchContent_Declare(${pname} ${_command})
            FetchContent_MakeAvailable(${pname})
        else()
            paqaj_message("Hash has not changed -> reusing same package")
            set(${success} 1 PARENT_SCOPE)

            if (_version)
                set(${version} ${_version} PARENT_SCOPE)
            else()
                set(${version} ${${pname}_VERSION} PARENT_SCOPE)
            endif()
            return()
        endif()
    endif()

    if (${pname}_POPULATED)
        paqaj_message("Package populated in '${${pname}_SOURCE_DIR}'")

        if (_version)
            set(${version} ${_version} PARENT_SCOPE)
        else()
            set(${version} ${${pname}_VERSION} PARENT_SCOPE)
        endif()
    else()
        paqaj_message("Couldn't populate package")
        set(${success} 0 PARENT_SCOPE)
    endif()
endfunction()