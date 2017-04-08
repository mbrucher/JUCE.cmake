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

if(POLICY CMP0011)
  # Included scripts do automatic cmake_policy PUSH and POP.
  cmake_policy(SET CMP0011 NEW)
endif()


function(get_drive out_var path)

  if(WIN32)
    string(SUBSTRING "${path}" 1 1 drive_colon)

    if(drive_colon STREQUAL ":")
      string(SUBSTRING "${path}" 0 2 drive)
    endif()
  else()
    set(drive "")
  endif()

  set(${out_var} "${drive}" PARENT_SCOPE)

endfunction()


function(get_relative_path out_var path)

  if(ARGC GREATER 2)
    set(start "${ARGV2}")
  else()
    set(start ".")
  endif()

  if(path STREQUAL "")
    message(FATAL_ERROR "no path specified")
  endif()

  get_filename_component(abs_start "${start}" ABSOLUTE)
  get_filename_component(abs_path "${path}" ABSOLUTE)

  string(FIND "${abs_start}" ";" semicolon_index)
  if(NOT semicolon_index EQUAL -1)
    message(FATAL_ERROR "Cannot handle semicolons in start: ${abs_start}")
  endif()

  string(FIND "${abs_path}" ";" semicolon_index)
  if(NOT semicolon_index EQUAL -1)
    message(FATAL_ERROR "Cannot handle semicolons in path: ${abs_path}")
  endif()

  if(WIN32)
    get_drive(start_drive "${abs_start}")
    get_drive(path_drive "${abs_path}")
    if(NOT start_drive STREQUAL path_drive)
      message(FATAL_ERROR
        "path is on drive ${path_drive}, but start is on drive ${start_drive}"
      )
    endif()
  endif()

  if(POLICY CMP0007)
    # list command no longer ignores empty elements.
    cmake_policy(SET CMP0007 NEW)
  endif()
  string(REPLACE "/" ";" start_list "${abs_start}")
  list(REMOVE_ITEM start_list "")
  string(REPLACE "/" ";" path_list "${abs_path}")
  list(REMOVE_ITEM path_list "")

  list(LENGTH start_list start_list_length)
  list(LENGTH path_list path_list_length)
  set(min_length ${start_list_length})
  if(path_list_length LESS min_length)
    set(min_length ${path_list_length})
  endif()

  set(common_length 0)
  while(common_length LESS min_length)
    list(GET start_list ${common_length} start_item)
    list(GET path_list ${common_length} path_item)
    if(NOT start_item STREQUAL path_item)
      break()
    endif()
    math(EXPR common_length "${common_length} + 1")
  endwhile()

  if(common_length LESS start_list_length)
    math(EXPR up_length "${start_list_length} - ${common_length} - 1")
    foreach(up RANGE ${up_length})
      list(APPEND rel_list "..")
    endforeach()
  endif()

  if(common_length LESS path_list_length)
    math(EXPR down_length "${path_list_length} - 1")
    foreach(down RANGE ${common_length} ${down_length})
      list(GET path_list ${down} path_item)
      list(APPEND rel_list "${path_item}")
    endforeach()
  endif()

  list(LENGTH rel_list rel_list_length)
  if(rel_list_length EQUAL 0)
    set(rel ".")
  else()
    string(REPLACE ";" "/" rel "${rel_list}")
  endif()

  set(${out_var} "${rel}" PARENT_SCOPE)

endfunction()
