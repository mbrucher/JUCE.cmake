function(pop_front in n out)

  string(SUBSTRING "${in}" ${n} -1 in)
  set(${out} "${in}" PARENT_SCOPE)

endfunction()


function(skip_white_spaces in_xml out_xml)

  set(pos 0)
  string(LENGTH "${in_xml}" in_length)

  while(1)
    if(pos LESS in_length)
      string(SUBSTRING "${in_xml}" ${pos} 1 char)
      if(char MATCHES "[ \n\t]")
        math(EXPR pos "${pos} + 1")
      else()
        break()
      endif()
    else()
      break()
    endif()
  endwhile()

  pop_front("${in_xml}" ${pos} in_xml)

  set(${out_xml} "${in_xml}" PARENT_SCOPE)

endfunction()


function(parse_xml_header in_xml out_xml)

  string(SUBSTRING "${in_xml}" 0 5 open_header)

  if(open_header STREQUAL "<?xml")
    pop_front("${in_xml}" 5 in_xml)
    string(FIND "${in_xml}" "?>" close_header_pos)
    if(close_header_pos EQUAL -1)
      message(FATAL_ERROR "Malformed header")
    endif()
    math(EXPR close_header_end "${close_header_pos} + 2")
    pop_front("${in_xml}" ${close_header_end} in_xml)
  endif()

  set(${out_xml} "${in_xml}" PARENT_SCOPE)

endfunction()


function(read_identifier in_xml out_xml out_identifier)

  string(SUBSTRING "${in_xml}" 0 1 first_char)

  if(NOT first_char MATCHES "[A-Za-z]")
    message(FATAL_ERROR "Expected identifier token, got '${first_char}'")
  endif()

  set(pos 1)
  string(LENGTH "${in_xml}" in_length)

  while(1)
    if(pos LESS in_length)
      string(SUBSTRING "${in_xml}" ${pos} 1 char)
      if(char MATCHES "[-_:.A-Za-z0-9]")
        math(EXPR pos "${pos} + 1")
      else()
        break()
      endif()
    else()
      break()
    endif()
  endwhile()

  string(SUBSTRING "${in_xml}" 0 ${pos} identifier)
  pop_front("${in_xml}" ${pos} in_xml)

  set(${out_xml} "${in_xml}" PARENT_SCOPE)
  set(${out_identifier} "${identifier}" PARENT_SCOPE)

endfunction()


function(read_next_element in_xml out_xml out_elm_type out_elm_name out_elm_attrs)

  string(SUBSTRING "${in_xml}" 0 1 open_elm)
  if(NOT open_elm STREQUAL "<")
    message(FATAL_ERROR "Expected token: '<', got '${open_elm}'")
  endif()

  string(SUBSTRING "${in_xml}" 0 2 open_end_elm)
  if(open_end_elm STREQUAL "</")
    pop_front("${in_xml}" 2 in_xml)

    set(elm_type "XML_END_ELEMENT")
    read_identifier("${in_xml}" in_xml elm_name)
    skip_white_spaces("${in_xml}" in_xml)

    string(SUBSTRING "${in_xml}" 0 1 close_elm)
    if(NOT close_elm STREQUAL ">")
      message(FATAL_ERROR "Expected token: \">\"")
    endif()
    pop_front("${in_xml}" 1 in_xml)

  else()
    pop_front("${in_xml}" 1 in_xml)

    read_identifier("${in_xml}" in_xml elm_name)
    skip_white_spaces("${in_xml}" in_xml)

    while(1)
      string(SUBSTRING "${in_xml}" 0 2 close_empty_elm)
      if(close_empty_elm STREQUAL "/>")
        pop_front("${in_xml}" 2 in_xml)

        set(elm_type "XML_EMPTY_ELEMENT")
        break()
      endif()

      string(SUBSTRING "${in_xml}" 0 1 close_elm)
      if(close_elm STREQUAL ">")
        pop_front("${in_xml}" 1 in_xml)

        set(elm_type "XML_START_ELEMENT")
        break()
      endif()

      # TODO: deal with attributes
      string(FIND "${in_xml}" "/>" close_empty_pos)
      string(FIND "${in_xml}" ">" close_pos)
      if(close_empty_pos LESS close_pos)
        pop_front("${in_xml}" ${close_empty_pos} in_xml)
      else()
        pop_front("${in_xml}" ${close_pos} in_xml)
      endif()
    endwhile()
  endif()

  set(${out_xml} "${in_xml}" PARENT_SCOPE)
  set(${out_elm_type} "${elm_type}" PARENT_SCOPE)
  set(${out_elm_name} "${elm_name}" PARENT_SCOPE)
  set(${out_elm_attrs} "${elm_attrs}" PARENT_SCOPE)

endfunction()


function(main)
  file(READ "D:/dev/JUCE/examples/HelloWorld/HelloWorld.jucer" xml_content)

  parse_xml_header("${xml_content}" xml_content)
  skip_white_spaces("${xml_content}" xml_content)

  set(xpath "")
  set(depth 0)

  while(NOT xml_content STREQUAL "")
    read_next_element("${xml_content}" xml_content elm_type elm_name elm_attrs)

    if(elm_type STREQUAL "XML_START_ELEMENT" OR elm_type STREQUAL "XML_EMPTY_ELEMENT")
      if(depth GREATER 0)
        string(CONCAT xpath "${xpath}/${elm_name}")
      else()
        set(xpath "${elm_name}")
      endif()
      math(EXPR depth "${depth} + 1")

      if(NOT elm_attrs STREQUAL "")
        set(attrs "[]")
      endif()

      message(STATUS "${xpath}${attrs}")
    endif()

    if(elm_type STREQUAL "XML_END_ELEMENT" OR elm_type STREQUAL "XML_EMPTY_ELEMENT")
      math(EXPR depth "${depth} - 1")
      string(FIND "${xpath}" "/" last_slash_pos REVERSE)
      string(SUBSTRING "${xpath}" 0 ${last_slash_pos} xpath)
    endif()

    skip_white_spaces("${xml_content}" xml_content)
  endwhile()

endfunction()


main()
