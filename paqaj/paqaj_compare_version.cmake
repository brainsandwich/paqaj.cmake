cmake_minimum_required(VERSION 3.16.0)

# Parse a version range in the form X[.Y[.Z[.W]]][...[<]X[.Y[.Z[.W]]]] (e.g. 1.2...<3.4.5.9982)
# 
# @param input: input version text 
# @param base: base/lower part of the range
# @param max: higher part of the range or -1 if there's none
# @param exclude_max: 1 if higher range part should be exclusive (symbol '<' in front)
function(paqaj_compare_version_parse_range input base max exclude_max)
    string(FIND ${input} "..." _range_pos)
    if (NOT ${_range_pos} EQUAL -1)
        string(FIND ${input} "<" _excl_pos)
        if (NOT ${_excl_pos} EQUAL -1)
            set(${exclude_max} 1 PARENT_SCOPE)
            math(EXPR _max_pos "${_excl_pos} + 1")
        else()
            math(EXPR _max_pos "${_range_pos} + 3")
        endif()

        string(SUBSTRING ${input} 0 ${_range_pos} _min)
        string(SUBSTRING ${input} ${_max_pos} -1 _max)
        set(${base} ${_min} PARENT_SCOPE)
        set(${max} ${_max} PARENT_SCOPE)
    else()
        set(${base} ${input} PARENT_SCOPE)
        set(${max} -1 PARENT_SCOPE)
    endif()

    set(${exclude_max} 0 PARENT_SCOPE)
endfunction()

# Compare versions numbers
#
# @param left: version range in the form X[.Y[.Z[.W]]][...[<]X[.Y[.Z[.W]]]] (e.g. 1.2...<3.4.5.9982)
# @param right: specific version in the form X[.Y[.Z[.W]]]
# @param result: 1 if specific version is equal or in range, 0 otherwise
function(paqaj_compare_version left right result)
    string(REGEX MATCH "[0-9](\.[0-9])*([^\ \t\r\n])*" _right_trimmed ${right})
    paqaj_compare_version_parse_range(${left} left_base left_max left_exclude_max)
    if ("EXACT" IN_LIST ARGN)
        if (${left_max} EQUAL -1)
            if (${left} VERSION_EQUAL ${_right_trimmed})
                set(${result} 1 PARENT_SCOPE)
            else()
                set(${result} 0 PARENT_SCOPE)
            endif()
            return()
        endif()
    endif()

    if (NOT (${left_base} VERSION_LESS_EQUAL ${_right_trimmed}))
        set(${result} 0 PARENT_SCOPE)
        return()
    endif()

    if (${left_max} VERSION_GREATER_EQUAL ${_right_trimmed})
        set(${result} 1 PARENT_SCOPE)
    else()
        set(${result} 0 PARENT_SCOPE)
        return()
    endif()
endfunction()