# PAQAJ

How to use:

```cmake

include(paqaj.cmake)

# Smallest version, will try to locate package
# in ${CMAKE_CURRENT_SOURCE_DIR}/ext folder and using
# find_package
paqaj_get(something)

# There's no mechanism regarding the produced target,
# so you'll have to follow library's manual to know
# how to use it
target_link_library(my_exe PUBLIC something::something)

# -------------------------------------------------------------------

# You can specify some package names alternatives for a
# better search. The subdirectory pattern matching
# accounts for prefixes and suffixes already (libsomething-1.2.3
# already works)
paqaj_get(something
    NAMES Something SomeThing some-thing
)

# -------------------------------------------------------------------

paqaj_get(something
    
    # Limit to versions 1.2.x.x to 2.x.x.x
    VERSION 1.2...2

    # Identified git repository
    FETCH_GIT_REPOSITORY https://github.com/foo/something
    
    # Default behavior is to look for package using find_package
    # and in subdirectories (default located in ext/ folder)
    NO_LOCAL
    NO_SUBDIR

    # Set some project options associated with this package
    OPTIONS
        SMTH_OPTION
        SMTH_VALUE="you souldn't"
)



```