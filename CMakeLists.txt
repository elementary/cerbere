# Check http://elementaryos.org/docs/developer-guide/cmake for documentation

cmake_minimum_required (VERSION 2.6)
cmake_policy(VERSION 2.6)

project(cerbere)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/vala )

add_subdirectory (src)
add_subdirectory (data)


# GSettings schema

SET (SCHEMAS_NAME "org.elementary.cerbere.gschema.xml")
# Have an option to not install the schema into where GLib is

option (GSETTINGS_LOCALINSTALL "Install GSettings Schemas locally instead of to the GLib prefix" OFF)

if (GSETTINGS_LOCALINSTALL)
    SET (GSETTINGS_DIR "${CMAKE_INSTALL_PREFIX}/share/glib-2.0/schemas/")
else (GSETTINGS_LOCALINSTALL)
    execute_process (COMMAND ${PKG_CONFIG_EXECUTABLE} glib-2.0 --variable prefix OUTPUT_VARIABLE _glib_prefix OUTPUT_STRIP_TRAILING_WHITESPACE)
    set (GSETTINGS_DIR "${_glib_prefix}/share/glib-2.0/schemas/")
endif (GSETTINGS_LOCALINSTALL)
# Run the validator and error if it fails

execute_process (COMMAND ${PKG_CONFIG_EXECUTABLE} gio-2.0 --variable glib_compile_schemas  OUTPUT_VARIABLE _glib_comple_schemas OUTPUT_STRIP_TRAILING_WHITESPACE)
execute_process (COMMAND ${_glib_comple_schemas} --dry-run --schema-file=${CMAKE_CURRENT_SOURCE_DIR}/${SCHEMAS_NAME} ERROR_VARIABLE _schemas_invalid OUTPUT_STRIP_TRAILING_WHITESPACE)

if (_schemas_invalid)
    message (SEND_ERROR "Schema validation error: ${_schemas_invalid}")
endif (_schemas_invalid)

# Actually install and recomple schemas

message (STATUS "GSettings schemas will be installed into ${GSETTINGS_DIR}")

install (FILES ${SCHEMAS_NAME} DESTINATION ${GSETTINGS_DIR} OPTIONAL)
install (CODE "message (STATUS \"Compiling GSettings schemas\")")
install (CODE "execute_process (COMMAND ${_glib_comple_schemas} ${GSETTINGS_DIR})")
