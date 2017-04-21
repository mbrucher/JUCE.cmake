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

function(get_substring_inclusive big_string token_begin token_end output_variable)
  string(FIND ${big_string} ${token_begin} pos)
  string(SUBSTRING ${big_string} ${pos} -1 big_string)
  string(FIND ${big_string} ${token_end} pos)
  string(LENGTH ${token_end} token_end_size)
  message(${token_end_size})
  math(EXPR pos "${pos} + ${token_end_size}")
  string(SUBSTRING ${big_string} 0 ${pos} substring)
  set(${output_variable} "${substring}" PARENT_SCOPE)
endfunction(get_substring_inclusive)

get_substring_inclusive(${jucer_file_content} "<JUCERPROJECT" ">" jucer_file_content_jucerProjectContent)

#-------------- extract all content of 

function(get_xml_attributes xml_node output_variable_prefix output_variable_list)
  #assuming this node has no attribute...

  # strip first <
  string(FIND ${xml_node} "<" pos)
  math (EXPR pos "${pos} + 1")
  string(SUBSTRING ${xml_node} ${pos} -1 xml_node)
  string(STRIP "${xml_node}" xml_node)
  # strip node tag name
  # from https://www.w3schools.com/xml/xml_elements.asp , Element names cannot contain spaces
  string(FIND ${xml_node} " " pos)
  string(SUBSTRING ${xml_node} ${pos} -1 xml_node)
  # strip last >
  string(FIND ${xml_node} ">" pos REVERSE)
  string(SUBSTRING ${xml_node} 0 ${pos} xml_node)

  #-------------------------------------------
  message("get_xml_attributes begin")
  # strip xml_node
  string(STRIP "${xml_node}" xml_node)
  # while xml_node not empty
  while(NOT xml_node STREQUAL "")
    message ("xml_node=${xml_node}")
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
    string(STRIP "${xml_node}" xml_node)

    # set variable
    set(full_xml_var_name ${output_variable_prefix}${xml_var_name})
    set(${full_xml_var_name} ${xml_var_value} PARENT_SCOPE)
    # add variable to variable list
    list(APPEND variable_list ${full_xml_var_name})
    message("> ${full_xml_var_name}=${xml_var_value}")

  endwhile()
  set(${output_variable_list} "${variable_list}" PARENT_SCOPE)
  message("get_xml_attributes end")
endfunction(get_xml_attributes)

get_xml_attributes(${jucer_file_content_jucerProjectContent} "xml_JUCERPROJECT_" jucer_file_content_jucerProjectContent_attributes)

message("Loop_var begin")
foreach(Loop_var ${jucer_file_content_jucerProjectContent_attributes})
  message("> ${Loop_var}=${${Loop_var}}")
endforeach()
message("Loop_var end")

get_substring(${jucer_file_content_jucerProjectContent} "name=\"" "\" projectType" project_name_xml)

if(xml_JUCERPROJECT_projectType STREQUAL "guiapp")
  set(xml_JUCERPROJECT_projectType "GUI Application")
endif()


# extract GROUP NODE
string(FIND ${jucer_file_content} "<MAINGROUP" pos)
string(SUBSTRING ${jucer_file_content} ${pos} -1 tempXml)
string(FIND ${tempXml} ">" pos)
math (EXPR pos "${pos} + 1")
string(SUBSTRING ${tempXml} ${pos} -1 tempXml)
string(FIND ${tempXml} "</MAINGROUP>" pos)
string(SUBSTRING ${tempXml} 0 ${pos} tempXml)
set(xml_group_node ${tempXml})
message("XML xml_group_node = ${xml_group_node}")

function(get_xml_children xml_node output_variable_prefix output_variable_list)
  message("get_xml_children begin")
  #delete this node information (top), <GROUP etc>
  string(STRIP "${xml_node}" xml_node)
  string(FIND ${xml_node} ">" pos)
  math (EXPR pos "${pos} + 1")
  string(SUBSTRING ${xml_node} ${pos} -1 xml_node)
  #delete this node information bottom, </GROUP>
  string(STRIP "${xml_node}" xml_node)
  string(FIND ${xml_node} "<" pos REVERSE)
  string(SUBSTRING ${xml_node} 0 ${pos} xml_node)
  #while not empty
  message("cleared xml_node=${xml_node}")
  set(counter 0)
  while(NOT xml_node STREQUAL "")
    #lookup first <
    string(FIND ${xml_node} "<" pos1)
    #lookup first />
    string(FIND ${xml_node} ">" pos2)
    math(EXPR pos2 "${pos2} +1")
    #extract substring
    string(SUBSTRING ${xml_node} ${pos1} ${pos2} xml_child_node)
    #set external variable
    set(full_xml_var_name ${output_variable_prefix}${counter})
    set(${full_xml_var_name} "${xml_child_node}" PARENT_SCOPE)
    message("> ${full_xml_var_name}=${xml_child_node}")
    # add variable to variable list
    list(APPEND variable_list ${full_xml_var_name})
    
    #delete section
    string(SUBSTRING ${xml_node} ${pos2} -1 xml_node)
    string(STRIP "${xml_node}" xml_node)
    #inc counter
    math (EXPR counter "${counter} + 1")
  endwhile()
  set(${output_variable_list} "${variable_list}" PARENT_SCOPE)
  message("get_xml_children end")
endfunction(get_xml_children)



get_xml_children(${xml_group_node} "xml_filenode_" xml_group_files_nodes)

message("Loop_var begin -------- XML GROUP FILES NODES -----------------")
foreach(Loop_var ${xml_group_files_nodes})
  message("> ${Loop_var}=${${Loop_var}}")
endforeach()
message("Loop_var end")

# for each FILE




configure_file(
  "${CMAKE_CURRENT_LIST_DIR}/cmake/templates/Jucer2CMake.CMakeLists.txt"
  "CMakeLists.txt"
  @ONLY
)

message("Generated CMakeLists.txt")
