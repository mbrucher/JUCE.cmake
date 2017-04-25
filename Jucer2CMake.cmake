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

set(xmlstarlet_command "xmlstarlet;elements;-v;${jucer_file}")
execute_process(
  COMMAND ${xmlstarlet_command}
  OUTPUT_VARIABLE jucer_file_content
  #RESULT_VARIABLE xmlstarlet_command_result
  )

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
  math(EXPR pos "${pos} + ${token_end_size}")
  string(SUBSTRING ${big_string} 0 ${pos} substring)
  set(${output_variable} "${substring}" PARENT_SCOPE)
endfunction(get_substring_inclusive)

function(get_xml_attributes xml_node output_variable_prefix output_variable_list)
  #example = JUCERPROJECT[@id='tTAKTK1s' and @name='HelloWorld' and @projectType='guiapp' and @juceFolder='../../../juce' and @jucerVersion='4.3.1' and @version='1.0.0' and @bundleIdentifier='com.roli.jucehelloworld' and @companyName='ROLI Ltd.' and @includeBinaryInAppConfig='1']
  # strip
  string(STRIP "${xml_node}" xml_node)
  # only get first line
  string(FIND "${xml_node}" "\n" pos)
  string(SUBSTRING ${xml_node} 0 ${pos} xml_node)
  string(STRIP "${xml_node}" xml_node)
  # if first line does not have any @, it means this node has no attribute and we can return

  string(FIND "${xml_node}" "@" pos)
  if(pos EQUAL -1)
    # no attribute for this node
    return()
  endif()

  # strip first [
  string(FIND "${xml_node}" "[" pos)
  math (EXPR pos "${pos} + 1")
  string(SUBSTRING ${xml_node} ${pos} -1 xml_node)
  # strip last ]
  string(FIND "${xml_node}" "]" pos)
  string(SUBSTRING ${xml_node} 0 ${pos}  xml_node)

  string(STRIP "${xml_node}" xml_node)
  # while not empty
  while(NOT xml_node STREQUAL "")
    string(FIND "${xml_node}" "and" pos)
    # if has only one attribute
    if(${pos} EQUAL -1)
      # extract all
      set(extracted_pair ${xml_node})
      set(xml_node "")
    else()
      # extract until AND
      string(SUBSTRING ${xml_node} 0 ${pos} extracted_pair)
      math (EXPR pos "${pos} + 3")
      string(SUBSTRING ${xml_node} ${pos} -1 xml_node)
    endif()
    # strip
    string(STRIP "${extracted_pair}" extracted_pair)
    # strip first @
    string(SUBSTRING ${extracted_pair} 1 -1 extracted_pair)
    # extract until =
    string(FIND "${extracted_pair}" "=" pos)
    # -> attribute name
    string(SUBSTRING ${extracted_pair} 0 ${pos} xml_var_name)
    # strip =
    math (EXPR pos "${pos} + 1")
    string(SUBSTRING ${extracted_pair} ${pos} -1 extracted_pair)
    # strip first single quote
    string(FIND "${extracted_pair}" "'" pos)
    math (EXPR pos "${pos} + 1")
    string(SUBSTRING ${extracted_pair} ${pos} -1 extracted_pair)
    # strip last single quote
    string(FIND "${extracted_pair}" "'" pos REVERSE)
    # -> attribute value
    string(SUBSTRING ${extracted_pair} 0 ${pos} xml_var_value)

    # set variable
    set(full_xml_var_name ${output_variable_prefix}${xml_var_name})
    set(${full_xml_var_name} ${xml_var_value} PARENT_SCOPE)
    # add variable to variable list
    list(APPEND variable_list ${full_xml_var_name})
    # strip to ease the while test condition
    string(STRIP "${xml_node}" xml_node)
  endwhile()
  # set global variable
  set(${output_variable_list} "${variable_list}" PARENT_SCOPE)
  return()
endfunction(get_xml_attributes)

get_xml_attributes(${jucer_file_content} "xml_JUCERPROJECT_" jucer_file_content_jucerProjectContent_attributes)

message("Loop_var begin")
foreach(Loop_var ${jucer_file_content_jucerProjectContent_attributes})
  message("> ${Loop_var}=${${Loop_var}}")
endforeach()
message("Loop_var end")


set(project_name_xml ${xml_JUCERPROJECT_name})

if(xml_JUCERPROJECT_projectType STREQUAL "guiapp")
  set(xml_JUCERPROJECT_projectType "GUI Application")
endif()


function(is_descendant xml_node_line_parent xml_node_line_descendant output_variable_bool)
  message(FATAL_ERROR "\n unimplemented is_descendant")
endfunction(is_descendant)

function(get_xpath_tag_name xml_xpath output_tag_name)
  message(FATAL_ERROR "\n unimplemented get_xpath_tag_name")
endfunction(get_xpath_tag_name)

function(get_xpath_depth xml_xpath output_depth)
  message(FATAL_ERROR "\n unimplemented get_xpath_depth")
endfunction(get_xpath_depth)

function(split_xml_line xml_line output_xpath output_attributes_string)
  message(FATAL_ERROR "\n unimplemented split_xml_line")
  
  # strip potential attributes
  string(SUBSTRING "${xml_node}" 0 ${pos} xml_node_line)
  string(FIND "${xml_node_line}" "[@" pos)
  if(NOT pos EQUAL -1)
    # has attribute for this node
    return()
  endif()

endfunction(split_xml_line)

function(split_next_line big_string output_head_line output_tail)
  if(big_string STREQUAL "")
    return()
  endif()
  string(FIND "${big_string}" "\n" pos)
  string(SUBSTRING ${big_string} 0 ${pos} output_head_line)
  if(pos EQUAL -1)
    return()
  endif()
  math (EXPR pos "${pos} + 1")
  string(SUBSTRING ${big_string} ${pos} output_tail)
endfunction(split_next_line)

function(get_xml_children xml_node node_tag_regex output_variable_prefix output_variable_list)
  split_next_line(xml_node xml_node_line xml_node)
  if(xml_node STREQUAL "")
    # no child for this node
    return()
  endif()

  # save the current depth
  split_xml_line(xml_node_line xpath attributes)
  get_xpath_depth(${xpath} xml_node_depth)
  set(original_xml_node_depth ${xml_node_depth})
  math (EXPR xml_new_child_node_depth "${xml_node_depth} + 1")

  set(counter 0)
  # while xml node not empty
  while(NOT xml_node STREQUAL "")
    # extract next line
    split_next_line(xml_node xml_node_line xml_node)
    split_xml_line(xml_node_line xpath attributes)
    get_xpath_depth(${xpath} xml_node_depth)
    
    if(xml_node_depth LESS original_xml_node_depth)
      message(AUTHOR_WARNING "get_xml_children: passed xml_node may be misformed because xml_node depth is not the lowest possible")
      break()
    endif()

    if(xml_node_depth EQUAL original_xml_node_depth)
      message(AUTHOR_WARNING "get_xml_children: passed xml_node may be misformed because it has siblings (same depth nodes)")
      break()
    endif()

    if(xml_node_depth EQUAL xml_new_child_node_depth)
      if(NOT counter EQUAL 0)
        # save the current child
        # set variable
        set(full_xml_var_name ${output_variable_prefix}${counter})
        set(${full_xml_var_name} ${xml_current_child_value} PARENT_SCOPE)
        # add variable to variable list
        list(APPEND variable_list ${full_xml_var_name})
        # reset current child
        set(${xml_current_child_value} "")
      endif()
      math (EXPR counter "${counter} + 1")
    endif()

    string(CONCAT xml_current_child_value ${xml_current_child_value} xml_node_line "\n")
  endwhile()

  # set global variable
  set(${output_variable_list} "${variable_list}" PARENT_SCOPE)
  return()
endfunction(get_xml_children)

get_xml_children(${jucer_file_content} "" "jucer_xml_lvl1_" jucer_xml_lvl0_children)

message("Loop_var begin ---------------------------------")
foreach(Loop_var ${jucer_xml_lvl0_children})
  message("> ${Loop_var}=${${Loop_var}}")
endforeach()
message("Loop_var end")



message(FATAL_ERROR "\nbreakpoint get_xml_children ????")
# extract GROUP NODE
string(FIND ${jucer_file_content} "<MAINGROUP" pos)
string(SUBSTRING ${jucer_file_content} ${pos} -1 tempXml)
string(FIND ${tempXml} ">" pos)
math (EXPR pos "${pos} + 1")
string(SUBSTRING ${tempXml} ${pos} -1 tempXml)
string(FIND ${tempXml} "</MAINGROUP>" pos)
string(SUBSTRING ${tempXml} 0 ${pos} tempXml)
set(xml_group_node ${tempXml})

function(get_xml_children xml_node output_variable_prefix output_variable_list)
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
    # add variable to variable list
    list(APPEND variable_list ${full_xml_var_name})
    
    #delete section
    string(SUBSTRING ${xml_node} ${pos2} -1 xml_node)
    string(STRIP "${xml_node}" xml_node)
    #inc counter
    math (EXPR counter "${counter} + 1")
  endwhile()
  set(${output_variable_list} "${variable_list}" PARENT_SCOPE)
endfunction(get_xml_children)


get_xml_attributes(${xml_group_node} "xml_group_node_attributes_" xml_group_node_attributes)
get_xml_children(${xml_group_node} "xml_filenode_" xml_group_files_nodes)

message("Loop_var begin -------- XML GROUP FILES NODES -----------------")

foreach(Loop_var ${xml_group_node_attributes})
  # dereference double pointer to get n
  set(xml_file_node ${${Loop_var}})
  message("> ${xml_file_node}")
endforeach()

string(CONCAT jucer_project_files_var ${jucer_project_files_var} "jucer_project_files(\"HelloWorld/Source\"\n")
message(FATAL_ERROR "breakpoint: TODO from here, generates HelloWorld/Source dynamicaly")

foreach(Loop_var ${xml_group_files_nodes})
  # dereference double pointer to get n
  set(xml_file_node ${${Loop_var}})
  #message("> ${xml_file_node}")
  get_xml_attributes(${xml_file_node} "xml_file_node_" xml_file_node_attributes)
  message("> file path=${xml_file_node_file}")
  string(CONCAT jucer_project_files_var ${jucer_project_files_var} "  \"\${${jucer_file_name_var}_DIR}/${xml_file_node_file}\"\n")
endforeach()
message("Loop_var end")

string(CONCAT jucer_project_files_var ${jucer_project_files_var} ")\n")


configure_file(
  "${CMAKE_CURRENT_LIST_DIR}/cmake/templates/Jucer2CMake.CMakeLists.txt"
  "CMakeLists.txt"
  @ONLY
)

message("Generated CMakeLists.txt")
