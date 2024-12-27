#----------------------------------------------------------------
# Generated CMake target import file for configuration "DEBUG".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "zenohpico::zenohpico_shared" for configuration "DEBUG"
set_property(TARGET zenohpico::zenohpico_shared APPEND PROPERTY IMPORTED_CONFIGURATIONS DEBUG)
set_target_properties(zenohpico::zenohpico_shared PROPERTIES
  IMPORTED_LOCATION_DEBUG "${_IMPORT_PREFIX}/lib/libzenohpico.so"
  IMPORTED_SONAME_DEBUG "libzenohpico.so"
  )

list(APPEND _cmake_import_check_targets zenohpico::zenohpico_shared )
list(APPEND _cmake_import_check_files_for_zenohpico::zenohpico_shared "${_IMPORT_PREFIX}/lib/libzenohpico.so" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
