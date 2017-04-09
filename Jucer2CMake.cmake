# Copyright (c) 2017 Alain Martin
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

include("${CMAKE_CURRENT_LIST_DIR}/cmake/path.cmake")


if(NOT DEFINED jucer_file)
  message(
    "usage: cmake -Djucer_file=<.jucer-file> -P ${CMAKE_SCRIPT_MODE_FILE}"
  )
  return()
endif()

file(READ "${jucer_file}" jucer_file_content)

message("Generating CMakeLists.txt...")

get_filename_component(abs_current_dir "." ABSOLUTE)
get_drive(current_dir_drive "${abs_current_dir}")

get_filename_component(abs_cmake_dir "${CMAKE_CURRENT_LIST_DIR}/cmake" ABSOLUTE)
get_drive(cmake_dir_drive "${abs_cmake_dir}")
if(current_dir_drive STREQUAL cmake_dir_drive)
  get_relative_path(rel_cmake_dir "${abs_cmake_dir}" "${abs_current_dir}")
  set(cmake_dir "\${CMAKE_CURRENT_LIST_DIR}/${rel_cmake_dir}")
else()
  set(cmake_dir "${abs_cmake_dir}")
endif()

get_filename_component(abs_jucer_file "${jucer_file}" ABSOLUTE)
get_drive(jucer_file_drive "${abs_jucer_file}")
if(current_dir_drive STREQUAL jucer_file_drive)
  get_relative_path(rel_jucer_file "${abs_jucer_file}" "${abs_current_dir}")
  set(jucer_file "\${CMAKE_CURRENT_LIST_DIR}/${rel_jucer_file}")
endif()

get_filename_component(jucer_file_name "${jucer_file}" NAME)
string(REGEX REPLACE "[^A-Za-z0-9_]" "_" jucer_file_name_var "${jucer_file_name}")

set(project_name "PROJECT_NAME \"HelloWorld\"")
set(project_version "PROJECT_VERSION \"1.0.0\"")
set(company_name "COMPANY_NAME \"ROLI Ltd.\"")
set(company_website "# COMPANY_WEBSITE")
set(company_email "# COMPANY_EMAIL")
set(project_type "PROJECT_TYPE \"GUI Application\"")
set(bundle_identifier "BUNDLE_IDENTIFIER \"com.roli.jucehelloworld\"")
set(binarydatacpp_size_limit "BINARYDATACPP_SIZE_LIMIT \"Default\"")
set(binarydata_namespace "# BINARYDATA_NAMESPACE")
set(preprocessor_definitions "# PREPROCESSOR_DEFINITIONS")
set(project_id "PROJECT_ID \"tTAKTK1s\"")

configure_file(
  "${CMAKE_CURRENT_LIST_DIR}/cmake/templates/Jucer2CMake.CMakeLists.txt"
  "CMakeLists.txt"
  @ONLY
)

message("Generated CMakeLists.txt")
