# Copyright (C) Kumo inc. and its affiliates.
# Author: Jeff.li lijippy@163.com
# All rights reserved.
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
###########################################################################
# below are examples, after initialization, modify it to your own.
###########################################################################
###kmcmake_example


include(km_xxd)

# only dev set KM_XXD_CMAKE,
# normally will be auto set by find package procedure
#[[
set(KM_XXD_CMAKE ${PROJECT_SOURCE_DIR}/cmake/xxd.cmake)
kmcmake_cc_xxd(
    NAME        gen_assets   
    NAMESPACE   kumo::gen    
    OUTDIR      ${CMAKE_CURRENT_SOURCE_DIR}
    INCLUDEBASE ${PROJECT_SOURCE_DIR}
    ASSETDIR    ${CMAKE_CURRENT_SOURCE_DIR}
    FILES      
        abc/b.md
        abc/bdc/a.md
)


kmcmake_cc_library(
        NAMESPACE ${PROJECT_NAME}
        NAME swaegerui
        SOURCES
        ${gen_assets_SRCS}
        CXXOPTS
        ${KMCMAKE_CXX_OPTIONS}
        LINKS
        ${KMCMAKE_DEPS_LINK}
        PUBLIC
)

]]

kmcmake_cc_interface(
        NAMESPACE ${PROJECT_NAME}
        NAME version
        HEADERS
        version.h
        CXXOPTS
        ${KMCMAKE_CXX_OPTIONS}
        PUBLIC
)
