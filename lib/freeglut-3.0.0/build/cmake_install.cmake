# Install script for directory: C:/Users/Mitch/Dropbox/Development/Env/C++/Projects/StarMadeLauncher/StarMadeLauncher/lib/freeglut-3.0.0

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "C:/Program Files (x86)/freeglut")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

if(NOT CMAKE_INSTALL_COMPONENT OR "${CMAKE_INSTALL_COMPONENT}" STREQUAL "Unspecified")
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY OPTIONAL FILES
    "C:/Users/Mitch/Dropbox/Development/Env/C++/Projects/StarMadeLauncher/StarMadeLauncher/lib/freeglut-3.0.0/build/lib/libfreeglut.dll.a"
    "C:/Users/Mitch/Dropbox/Development/Env/C++/Projects/StarMadeLauncher/StarMadeLauncher/lib/freeglut-3.0.0/build/lib/libfreeglut.lib"
    )
endif()

if(NOT CMAKE_INSTALL_COMPONENT OR "${CMAKE_INSTALL_COMPONENT}" STREQUAL "Unspecified")
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/bin" TYPE SHARED_LIBRARY FILES "C:/Users/Mitch/Dropbox/Development/Env/C++/Projects/StarMadeLauncher/StarMadeLauncher/lib/freeglut-3.0.0/build/bin/libfreeglut.dll")
  if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/libfreeglut.dll" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/libfreeglut.dll")
    if(CMAKE_INSTALL_DO_STRIP)
      execute_process(COMMAND "c:/MinGW/bin/strip.exe" "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/bin/libfreeglut.dll")
    endif()
  endif()
endif()

if(NOT CMAKE_INSTALL_COMPONENT OR "${CMAKE_INSTALL_COMPONENT}" STREQUAL "Unspecified")
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY FILES "C:/Users/Mitch/Dropbox/Development/Env/C++/Projects/StarMadeLauncher/StarMadeLauncher/lib/freeglut-3.0.0/build/lib/libfreeglut_static.a")
endif()

if(NOT CMAKE_INSTALL_COMPONENT OR "${CMAKE_INSTALL_COMPONENT}" STREQUAL "Unspecified")
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/GL" TYPE FILE FILES
    "C:/Users/Mitch/Dropbox/Development/Env/C++/Projects/StarMadeLauncher/StarMadeLauncher/lib/freeglut-3.0.0/include/GL/freeglut.h"
    "C:/Users/Mitch/Dropbox/Development/Env/C++/Projects/StarMadeLauncher/StarMadeLauncher/lib/freeglut-3.0.0/include/GL/freeglut_ext.h"
    "C:/Users/Mitch/Dropbox/Development/Env/C++/Projects/StarMadeLauncher/StarMadeLauncher/lib/freeglut-3.0.0/include/GL/freeglut_std.h"
    "C:/Users/Mitch/Dropbox/Development/Env/C++/Projects/StarMadeLauncher/StarMadeLauncher/lib/freeglut-3.0.0/include/GL/glut.h"
    )
endif()

if(NOT CMAKE_INSTALL_COMPONENT OR "${CMAKE_INSTALL_COMPONENT}" STREQUAL "Unspecified")
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/pkgconfig" TYPE FILE RENAME "freeglut.pc" FILES "C:/Users/Mitch/Dropbox/Development/Env/C++/Projects/StarMadeLauncher/StarMadeLauncher/lib/freeglut-3.0.0/build/freeglut.pc")
endif()

if(CMAKE_INSTALL_COMPONENT)
  set(CMAKE_INSTALL_MANIFEST "install_manifest_${CMAKE_INSTALL_COMPONENT}.txt")
else()
  set(CMAKE_INSTALL_MANIFEST "install_manifest.txt")
endif()

file(WRITE "C:/Users/Mitch/Dropbox/Development/Env/C++/Projects/StarMadeLauncher/StarMadeLauncher/lib/freeglut-3.0.0/build/${CMAKE_INSTALL_MANIFEST}" "")
foreach(file ${CMAKE_INSTALL_MANIFEST_FILES})
  file(APPEND "C:/Users/Mitch/Dropbox/Development/Env/C++/Projects/StarMadeLauncher/StarMadeLauncher/lib/freeglut-3.0.0/build/${CMAKE_INSTALL_MANIFEST}" "${file}\n")
endforeach()
