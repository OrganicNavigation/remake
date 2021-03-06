############################################################################
#    Copyright (C) 2013 by Ralf Kaestner                                   #
#    ralf.kaestner@gmail.com                                               #
#                                                                          #
#    This program is free software; you can redistribute it and#or modify  #
#    it under the terms of the GNU General Public License as published by  #
#    the Free Software Foundation; either version 2 of the License, or     #
#    (at your option) any later version.                                   #
#                                                                          #
#    This program is distributed in the hope that it will be useful,       #
#    but WITHOUT ANY WARRANTY; without even the implied warranty of        #
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
#    GNU General Public License for more details.                          #
#                                                                          #
#    You should have received a copy of the GNU General Public License     #
#    along with this program; if not, write to the                         #
#    Free Software Foundation, Inc.,                                       #
#    59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             #
############################################################################

include(ReMakeComponent)
include(ReMakeProject)

include(ReMakePrivate)

### \brief ReMake Subversion macros
#   The ReMake Subversion module provides useful tools for Subversion-based
#   projects.

if(NOT DEFINED REMAKE_SVN_CMAKE)
  remake_set(REMAKE_SVN_CMAKE ON)

  remake_set(REMAKE_SVN_DIR ReMakeSVN)
  remake_find_package(Subversion QUIET OPTIONAL)
endif(NOT DEFINED REMAKE_SVN_CMAKE)

### \brief Retrieve the Subversion head revision.
#   This macro retrieves the Subversion head revision of the working directory.
#   The macro defines an output variable with the name provided and assigns the
#   revision number or 0 for non-versioned directories.
#   \required[value] variable The name of a variable to be assigned the
#     revision number.
macro(remake_svn_revision svn_var)
  remake_project_get(SUBVERSION_REVISION OUTPUT svn_revision)
  if(NOT DEFINED svn_revision)
    remake_set(svn_revision 0)
  endif(NOT DEFINED svn_revision)

  remake_project_set(SUBVERSION_REVISION ${svn_revision} CACHE STRING
    "Subversion revision of project sources.")

  if(SUBVERSION_FOUND)
    if(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/.svn)
      execute_process(COMMAND ${Subversion_SVN_EXECUTABLE} info
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        RESULT_VARIABLE svn_result
        OUTPUT_VARIABLE svn_info ERROR_QUIET)

      if(${svn_result} EQUAL 0)
        string(REGEX REPLACE ".*Revision: ([0-9]*).*" "\\1"
          svn_revision ${svn_info})

        if(svn_revision)
          remake_project_set(SUBVERSION_REVISION ${svn_revision}
            CACHE STRING "Subversion revision of project sources." FORCE)
        endif(svn_revision)
      endif(${svn_result} EQUAL 0)
    endif(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/.svn)
  endif(SUBVERSION_FOUND)

  remake_project_get(SUBVERSION_REVISION OUTPUT ${svn_var})
endmacro(remake_svn_revision)

### \brief Define Subversion log build rules.
#   This macro defines build rules for storing Subversion log messages of
#   the working directory into a file. Called in the top-level source
#   directory, it may be used to dump a project's changelog during build.
#   \required[value] filename The name of the file to write the Subversion
#     log messages to, relative to ${CMAKE_CURRENT_BINARY_DIR}.
#   \optional[value] COMPONENT:component The optional name of the install
#     component that is passed to remake_component_add_command(). See
#     ReMakeComponent for details.
#   \optional[var] TARGET:target The optional name of a top-level target
#     to add the build commands to, defaults to svn_log.
#   \optional[var] OUTPUT:variable The optional name of a variable to be
#     assigned the absolute-path output filename.
macro(remake_svn_log svn_file)
  remake_arguments(PREFIX svn_ VAR COMPONENT VAR TARGET VAR OUTPUT ${ARGN})
  remake_set(svn_target SELF DEFAULT svn_log)

  if(svn_output)
    remake_set(${svn_output})
  endif(svn_output)
  remake_project_get(SUBVERSION_REVISION OUTPUT svn_revision)

  if(svn_revision)
    if(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/.svn)
      if(NOT IS_ABSOLUTE ${svn_file})
        remake_set(svn_absolute ${CMAKE_CURRENT_BINARY_DIR}/${svn_file})
      else(NOT IS_ABSOLUTE ${svn_file})
        remake_set(svn_absolute ${svn_file})
      endif(NOT IS_ABSOLUTE ${svn_file})

      remake_file_mkdir(${REMAKE_SVN_DIR})
      remake_file(svn_head ${REMAKE_SVN_DIR}/head)
      add_custom_command(
        OUTPUT ${svn_head}
        COMMAND ${Subversion_SVN_EXECUTABLE} info | grep ^Revision |
          grep -o [0-9]* > ${svn_head} VERBATIM
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/.svn/entries
        COMMENT "Retrieving Subversion head revision")
      remake_component_add_command(
        OUTPUT ${svn_absolute} AS ${svn_target}
        COMMAND ${Subversion_SVN_EXECUTABLE} log > ${svn_absolute}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        DEPENDS ${svn_head}
        COMMENT "Retrieving Subversion log messages"
        ${COMPONENT})

      if(svn_output)
        remake_set(${svn_output} ${svn_absolute})
      endif(svn_output)
    endif(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/.svn)
  endif(svn_revision)
endmacro(remake_svn_log)
