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

include("${CMAKE_CURRENT_LIST_DIR}/../path.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/../unittest.cmake")

message(STATUS "Running tests for path.cmake")


function(test_get_drive)

  message(STATUS "Running tests for path.cmake::get_drive")

  get_drive(out "c:/foo/bar")
  if(WIN32)
    assert_equal("c:" "${out}")
  else()
    assert_equal("", "${out}")
  endif()

  get_drive(out "/foo/bar")
  assert_equal("" "${out}")

endfunction()


function(test_get_relative_path)

  message(STATUS "Running tests for path.cmake::get_relative_path")

  get_relative_path(out "a")
  assert_equal("a" "${out}")

  get_filename_component(abs_a "a" ABSOLUTE)
  get_relative_path(out "${abs_a}")
  assert_equal("a" "${out}")

  get_relative_path(out "a/b")
  assert_equal("a/b" "${out}")

  get_relative_path(out "../a/b")
  assert_equal("../a/b" "${out}")

  get_filename_component(currentdir  "${CMAKE_CURRENT_SOURCE_DIR}" NAME)

  get_relative_path(out "a" "../b")
  assert_equal("../${currentdir}/a" "${out}")

  get_relative_path(out "a/b" "../c")
  assert_equal("../${currentdir}/a/b" "${out}")

  get_relative_path(out "a" "b/c")
  assert_equal("../../a" "${out}")

  get_relative_path(out "a" "a")
  assert_equal("." "${out}")

  get_relative_path(out "/foo/bar/bat" "/x/y/z")
  assert_equal("../../../foo/bar/bat" "${out}")

  get_relative_path(out "/foo/bar/bat" "/foo/bar")
  assert_equal("bat" "${out}")

  get_relative_path(out "/foo/bar/bat" "/")
  assert_equal("foo/bar/bat" "${out}")

  get_relative_path(out "/" "/foo/bar/bat")
  assert_equal("../../.." "${out}")

  get_relative_path(out "/foo/bar/bat" "/x")
  assert_equal("../foo/bar/bat" "${out}")

  get_relative_path(out "/x" "/foo/bar/bat")
  assert_equal("../../../x" "${out}")

  get_relative_path(out "/" "/")
  assert_equal("." "${out}")

  get_relative_path(out "/a" "/a")
  assert_equal("." "${out}")

  get_relative_path(out "/a/b" "/a/b")
  assert_equal("." "${out}")

endfunction()


test_get_drive()
test_get_relative_path()
