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

function(get_substring big_string token_begin token_end output_variable)
  string(FIND ${big_string} ${token_begin} get_substring_token_begin_pos)
  string(SUBSTRING ${big_string} ${get_substring_token_begin_pos} -1 medium_string)
  string(FIND ${medium_string} ${token_end} get_substring_token_end_pos)
  string(SUBSTRING ${medium_string} 0 ${get_substring_token_end_pos} little_string)
  string(LENGTH ${token_begin} token_begin_size)
  string(SUBSTRING ${little_string} ${token_begin_size} -1 little_string_stripped)
  set(${output_variable} "${little_string_stripped}" PARENT_SCOPE)
endfunction(get_substring)





get_substring(${jucer_file_content} "<JUCERPROJECT" ">" jucer_file_content_jucerProjectContent)


#-------------- extract all content of 

function(get_xml_attributes xml_node output_variable_prefix output_variable_list)
  # strip xml_node
  string(STRIP ${xml_node} xml_node)
  # while xml_node not empty
  while(NOT("${xml_node}" STREQUAL ""))
    # lookup first equal sign
    string(FIND ${xml_node} "=" equal_sign_pos)
    # extract from beginning to first equal sign pos
    string(SUBSTRING ${xml_node} 0 ${equal_sign_pos} xml_var_name)
    # remove used text in case the node name contains quotes
    math (EXPR equal_sign_pos "${equal_sign_pos} + 1")
    string(SUBSTRING ${xml_node} ${equal_sign_pos} -1 xml_node)
    # lookup first quote
    string(FIND ${xml_node} "\"" first_quote_pos)
    # remove all text until the first quote so we can find the second quote
    math (EXPR first_quote_pos "${first_quote_pos} + 1") 
    string(SUBSTRING ${xml_node} ${first_quote_pos} -1 xml_node)
    # lookup second quote
    string(FIND ${xml_node} "\"" second_quote_pos)
    # extract from first to second quote pos
    string(SUBSTRING ${xml_node} 0 ${second_quote_pos} xml_var_value)
    # remove all text until the second quote
    math (EXPR second_quote_pos "${second_quote_pos} + 1")
    string(SUBSTRING ${xml_node} ${second_quote_pos} -1 xml_node)
    # strip xml_node
    string(STRIP ${xml_node} xml_node)

    # set variable
    set(full_xml_var_name ${output_variable_prefix}${xml_var_name})
    set(${full_xml_var_name} ${xml_var_value})
    # add variable to variable list
    list(APPEND variable_list ${full_xml_var_name}

  endwhile()
  set(${output_variable_list} "${variable_list}" PARENT_SCOPE)
endfunction(get_xml_attributes)

get_xml_attributes(jucer_file_content_jucerProjectContent "xml_JUCERPROJECT_" jucer_file_content_jucerProjectContent_attributes)

message("Loop_var begin")
foreach(loop_var ${jucer_file_content_jucerProjectContent_attributes})
  message("> ${Loop_var}=${${Loop_var}}")
endforeach()
message("Loop_var end")


get_substring(${jucer_file_content_jucerProjectContent} "name=\"" "\" projectType" project_name_xml)

set(project_name "PROJECT_NAME \"${project_name_xml}\"")
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
