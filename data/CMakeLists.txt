install (FILES cerbere.desktop DESTINATION share/applications)

# GSettings schema
include(GSettings)
add_schema("org.pantheon.cerbere.gschema.xml")
