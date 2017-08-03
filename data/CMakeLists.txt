install (FILES cerbere.desktop DESTINATION share/applications)

# GSettings schema
include(GSettings)
add_schema("io.elementary.cerbere.gschema.xml")
