# CMake equivalent of `xxd -i ${INPUT} ${OUTPUT}`
# Usage: cmake -DINPUT=examples/server/public/index.html -DOUTPUT=examples/server/index.html.hpp -P scripts/xxd.cmake

SET(INPUT "" CACHE STRING "Input File")
SET(OUTPUT "" CACHE STRING "Output File")
SET(OUTPUTH "" CACHE STRING "Output h File")
SET(VNAME "" CACHE STRING "varable name")
SET(NAMESPACE "" CACHE STRING "varable name")
SET(HPATH "" CACHE STRING "varable name")

get_filename_component(filename "${INPUT}" NAME)

file(READ "${INPUT}" hex_data HEX)
string(REGEX REPLACE "([0-9a-f][0-9a-f])" "0x\\1," hex_sequence "${hex_data}")

string(LENGTH ${hex_data} hex_len)
math(EXPR len "${hex_len} / 2")

##################
# ${OUTPUT}.h
file(WRITE "${OUTPUTH}" "/// do not modify it, gen by xxd.cmake\n\n")

file(APPEND "${OUTPUTH}" "#pragma once\n\n")
file(APPEND "${OUTPUTH}" "#include <string_view>\n\n")

file(APPEND "${OUTPUTH}" "namespace ${NAMESPACE} {\n\n")

file(APPEND "${OUTPUTH}" "    extern std::string_view ${VNAME};\n\n")

file(APPEND "${OUTPUTH}" "}  // namespace ${NAMESPACE}\n")

file(WRITE "${OUTPUT}" "/// do not modify it, gen by kxxd.cmake\n\n")

file(APPEND "${OUTPUT}" "#include <${HPATH}>\n")
file(APPEND "${OUTPUT}" "#include <string_view>\n\n")

file(APPEND "${OUTPUT}" "namespace ${NAMESPACE} {\n\n")

file(APPEND "${OUTPUT}" "    const unsigned char ${VNAME}_array[] = {${hex_sequence}};\n    unsigned int ${VNAME}_len = ${len};\n")
file(APPEND "${OUTPUT}" "    std::string_view ${VNAME} = std::string_view(reinterpret_cast<const char*>(${VNAME}_array), ${VNAME}_len);\n\n")
file(APPEND "${OUTPUT}" "}  // namespace ${NAMESPACE}\n")

