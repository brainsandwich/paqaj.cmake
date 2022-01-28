cmake_minimum_required(VERSION 3.16.0)

# Get the list of ref names on a specific repo
# You might want to do some regex magic to remove
# the ref/*/ part of each item
#
# @param url: git repository
# @param reflist: output ref list (ref/heads/branch;ref/tags/tag;...)
function(git_get_refs url reflist)
    find_package(Git REQUIRED)
    execute_process(
        COMMAND ${GIT_EXECUTABLE} ls-remote ${url}
        OUTPUT_VARIABLE result
        ERROR_VARIABLE result
    )

    if (result)
        set(_reflist)
        string(REPLACE "\n" ";" lines ${result})
        foreach (line ${lines})
            string(REGEX MATCHALL "[^\ \t\r\n]+" args ${line})
            list(GET args 1 _ref)
            list(APPEND _reflist ${_ref})
        endforeach()
        set(${reflist} ${_reflist} PARENT_SCOPE)
    endif()
endfunction()

# Get the commit hash of a ref (branch, tag, ...) on specific repo
#
# @param url: git repository
# @param ref: ref on this repo
# @param commit: output commit value, not set if invalid 
function(git_get_commit url ref commit)
    find_package(Git REQUIRED)
    execute_process(
        COMMAND ${GIT_EXECUTABLE} ls-remote ${url} ${ref}
        OUTPUT_VARIABLE result
        ERROR_VARIABLE result
    )

    if (result)
        string(REGEX MATCHALL "[^\ \t\r\n]+" args ${result})
        list(GET args 0 _commit)
        set(${commit} ${_commit} PARENT_SCOPE)
    endif()
endfunction()

# Get on which tag the repository in dir is at.
# If the repo isn't *exactly* on a tag, return an empty value
#
# @param dir: git repo directory
# @param tag: output tag
function(git_get_current_tag dir tag)
    find_package(Git REQUIRED)
    execute_process(
        COMMAND ${GIT_EXECUTABLE} describe --exact-match --tags HEAD
        OUTPUT_VARIABLE result
        ERROR_VARIABLE result
        WORKING_DIRECTORY ${dir}
    )

    if (result)
        string(FIND ${result} "fatal: no tag exactly matches" _fatal_marker)
        if (NOT ${_fatal_marker} EQUAL -1)
            return()
        endif()

        string(STRIP ${result} result)
        set(${tag} ${result} PARENT_SCOPE)
    endif()
endfunction()

# Get the repository current commit id
#
# @param dir: git repo directory
# @param tag: output commit id
function(git_get_current_commit dir commit)
    find_package(Git REQUIRED)
    execute_process(
        COMMAND ${GIT_EXECUTABLE} rev-parse HEAD
        OUTPUT_VARIABLE result
        ERROR_VARIABLE result
        WORKING_DIRECTORY ${dir}
    )

    string(STRIP ${result} result)
    set(${commit} ${result} PARENT_SCOPE)
endfunction()

# Get the repository current branch
#
# @param dir: git repo directory
# @param tag: output branch name
function(git_get_current_branch dir branch)
    find_package(Git REQUIRED)
    execute_process(
        COMMAND ${GIT_EXECUTABLE} rev-parse --abbrev-ref HEAD
        OUTPUT_VARIABLE result
        ERROR_VARIABLE result
        WORKING_DIRECTORY ${dir}
    )

    string(STRIP ${result} result)
    set(${branch} ${result} PARENT_SCOPE)
endfunction()
