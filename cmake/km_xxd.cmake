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

#------------------------------------------------------------------------------
# 函数名称: kmcmake_cc_xxd
# 功能描述: 批量将静态资源文件转换为C++可直接引用的代码文件（xxd.h/cc），
#           生成基于std::string_view的资源封装，并汇总生成资源列表（xxd_gen.h/cc），
#           最终导出生成的头文件/源文件列表，用于编译到目标库/可执行文件。
# 核心逻辑: 对每个资源文件生成十六进制数组+std::string_view封装，汇总所有资源为vector<pair>
#------------------------------------------------------------------------------
# 参数说明（按传入顺序/类别）:
#   [必选] NAME:         自定义名称，用于导出生成的文件列表变量（格式：${NAME}_HDRS/${NAME}_SRCS）
#   [必选] NAMESPACE:    C++命名空间，生成的代码会包裹在该命名空间下
#   [可选] OUTDIR:       生成的xxd.h/cc、xxd_gen.h/cc的输出目录
#                        默认值: CMAKE_CURRENT_SOURCE_DIR（调用函数的目录）
#   [可选] ASSETDIR:     资源文件（FILES）的基准目录，★FILES必须是相对于该目录的相对路径★
#                        默认值: CMAKE_CURRENT_SOURCE_DIR（调用函数的目录）
#   [可选] INCLUDEBASE:  生成#include <xxx.h>时的基准目录（用于计算头文件相对路径）
#                        默认值: PROJECT_SOURCE_DIR（项目根目录）
#   [必选] FILES:        待转换的资源文件列表，★必须是相对于ASSETDIR的相对路径★，支持多文件
#------------------------------------------------------------------------------
# 导出变量（调用函数后可直接使用）:
#   ${NAME}_HDRS:        生成的所有xxd.h、xxd_gen.h文件列表
#   ${NAME}_SRCS:        生成的所有xxd.cc、xxd_gen.cc文件列表
#------------------------------------------------------------------------------
# 关键注意事项:
#   1. FILES参数必须传入相对于ASSETDIR的相对路径，而非绝对路径/其他基准路径；
#   2. 生成的xxd.h/cc文件命名规则: ${OUTDIR}/${FILE_NAME}.xxd.h/cc（FILE_NAME为FILES中的原始名称）；
#   3. 生成的代码中，资源变量名由FILES路径替换 [./-] 为 _ 生成（如abc/b.md → abc_b_md）；
#   4. 汇总文件xxd_gen.h/cc会生成swaeger_files（vector<pair>），存储「原始文件名-资源变量」映射；
#------------------------------------------------------------------------------
# 应用示例（完整可直接复用）:
# include(km_xxd)  # 引入该cmake函数文件
# 
# # 调用xxd转换函数，生成资源代码
# kmcmake_cc_xxd(
#     NAME        gen_assets          # 自定义名称，导出gen_assets_HDRS/gen_assets_SRCS
#     NAMESPACE   kumo::gen           # 生成代码的命名空间
#     OUTDIR      ${CMAKE_CURRENT_SOURCE_DIR}  # 生成文件输出到当前目录
#     INCLUDEBASE ${PROJECT_SOURCE_DIR}        # #include基准目录为项目根
#     ASSETDIR    ${CMAKE_CURRENT_SOURCE_DIR}  # FILES基于当前目录（即abc/b.md在当前目录下）
#     FILES       # 待转换文件，★必须是相对于ASSETDIR的相对路径★
#         abc/b.md       # 对应ASSETDIR/abc/b.md
#         abc/bdc/a.md   # 对应ASSETDIR/abc/bdc/a.md
# )
# 
# # 将生成的资源代码编译为共享库（结合kmcmake_cc_library函数）
# kmcmake_cc_library(
#     NAMESPACE ${PROJECT_NAME}       # 库的命名空间（项目名）
#     NAME      swaegerui             # 库名称：libswaegerui.so
#     SOURCES   ${gen_assets_SRCS}    # 引入xxd生成的源文件
#     CXXOPTS   ${KMCMAKE_CXX_OPTIONS}# C++编译选项
#     LINKS     ${KMCMAKE_DEPS_LINK}  # 依赖库链接
#     PUBLIC                          # 库的可见性：PUBLIC
# )
#------------------------------------------------------------------------------
# 生成文件示例（参考）:
# 1. OUTDIR/abc/b.md.xxd.h: 声明kumo::gen::abc_b_md（std::string_view）
# 2. OUTDIR/abc/b.md.xxd.cc: 定义abc_b_md的十六进制数组+string_view
# 3. OUTDIR/xxd_gen.h: 声明kumo::gen::swaeger_files（资源列表）
# 4. OUTDIR/xxd_gen.cc: 定义swaeger_files，包含{"abc/b.md", abc_b_md}等映射
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Function Name: kmcmake_cc_xxd
# Description: Batch convert static asset files into C++ directly referable code files (xxd.h/cc),
#              generate std::string_view-based asset wrappers, and aggregate them into a resource list (xxd_gen.h/cc).
#              Finally, export the list of generated header/source files for compiling into target libraries/executables.
# Core Logic: Generate hexadecimal arrays + std::string_view wrappers for each asset file,
#             and aggregate all assets into a vector<pair> structure.
#------------------------------------------------------------------------------
# Parameter Explanations (by passing order/category):
#   [Required] NAME:         Custom name used to export generated file list variables (format: ${NAME}_HDRS/${NAME}_SRCS)
#   [Required] NAMESPACE:    C++ namespace that wraps the generated code
#   [Optional] OUTDIR:       Output directory for generated xxd.h/cc and xxd_gen.h/cc files
#                            Default: CMAKE_CURRENT_SOURCE_DIR (directory where the function is called)
#   [Optional] ASSETDIR:     Base directory for asset files (FILES), ★FILES must be relative paths to this directory★
#                            Default: CMAKE_CURRENT_SOURCE_DIR (directory where the function is called)
#   [Optional] INCLUDEBASE:  Base directory for generating #include <xxx.h> (used to calculate relative paths of headers)
#                            Default: PROJECT_SOURCE_DIR (project root directory)
#   [Required] FILES:        List of asset files to convert, ★must be relative paths to ASSETDIR★, supports multiple files
#------------------------------------------------------------------------------
# Exported Variables (usable directly after calling the function):
#   ${NAME}_HDRS:        List of all generated xxd.h and xxd_gen.h files
#   ${NAME}_SRCS:        List of all generated xxd.cc and xxd_gen.cc files
#------------------------------------------------------------------------------
# Key Notes:
#   1. FILES parameter must pass relative paths to ASSETDIR, not absolute paths or paths relative to other bases;
#   2. Naming rule for generated xxd.h/cc files: ${OUTDIR}/${FILE_NAME}.xxd.h/cc (FILE_NAME is the original name in FILES);
#   3. In generated code, asset variable names are created by replacing [./-] in FILES paths with _ (e.g., abc/b.md → abc_b_md);
#   4. Aggregate files xxd_gen.h/cc generate xxd_gen_files (vector<pair>), storing "original file name - asset variable" mappings;
#------------------------------------------------------------------------------
# Usage Example (complete and directly reusable):
# include(km_xxd)  # Include this cmake function file
# 
# # Call xxd conversion function to generate resource code
# kmcmake_cc_xxd(
#     NAME        gen_assets          # Custom name, exports gen_assets_HDRS/gen_assets_SRCS
#     NAMESPACE   kumo::gen           # Namespace for generated code
#     OUTDIR      ${CMAKE_CURRENT_SOURCE_DIR}  # Output generated files to current directory
#     INCLUDEBASE ${PROJECT_SOURCE_DIR}        # Base directory for #include is project root
#     ASSETDIR    ${CMAKE_CURRENT_SOURCE_DIR}  # FILES are based on current directory (i.e., abc/b.md is under current directory)
#     FILES       # Asset files to convert, ★must be relative paths to ASSETDIR★
#         abc/b.md       # Corresponds to ASSETDIR/abc/b.md
#         abc/bdc/a.md   # Corresponds to ASSETDIR/abc/bdc/a.md
# )
# 
# # Compile generated resource code into a shared library (combined with kmcmake_cc_library function)
# kmcmake_cc_library(
#     NAMESPACE ${PROJECT_NAME}       # Library namespace (project name)
#     NAME      swaegerui             # Library name: libswaegerui.so
#     SOURCES   ${gen_assets_SRCS}    # Include xxd-generated source files
#     CXXOPTS   ${KMCMAKE_CXX_OPTIONS}# C++ compilation options
#     LINKS     ${KMCMAKE_DEPS_LINK}  # Dependent library links
#     PUBLIC                          # Library visibility: PUBLIC
# )
#------------------------------------------------------------------------------
# Generated File Examples (for reference):
# 1. OUTDIR/abc/b.md.xxd.h: Declares kumo::gen::abc_b_md (std::string_view)
# 2. OUTDIR/abc/b.md.xxd.cc: Defines hexadecimal array + string_view for abc_b_md
# 3. OUTDIR/xxd_gen.h: Declares kumo::gen::xxd_gen_files (resource list)
# 4. OUTDIR/xxd_gen.cc: Defines xxd_gen_files, including mappings like {"abc/b.md", abc_b_md}
#------------------------------------------------------------------------------


function(kmcmake_cc_xxd)
    set(args
            NAME
            NAMESPACE
            OUTDIR
            ASSETDIR
            INCLUDEBASE
    )

    set(list_args
            FILES
    )

    cmake_parse_arguments(
            PARSE_ARGV 0
            KMCMAKE_CC_XXD
            "${options}"
            "${args}"
            "${list_args}"
    )
    
    set(VAR_NAMES)
    set(INCLUDE_FILES)

    if(NOT DEFINED KMCMAKE_CC_XXD_NAME OR KMCMAKE_CC_XXD_NAME STREQUAL "")
        message(FATAL_ERROR "NAME must be set!")
    endif()


    if(NOT DEFINED KMCMAKE_CC_XXD_NAMESPACE OR KMCMAKE_CC_XXD_NAMESPACE STREQUAL "")
        message(FATAL_ERROR "NAMESPACE must be set!")
    endif()

    if(NOT DEFINED KMCMAKE_CC_XXD_ASSETDIR OR KMCMAKE_CC_XXD_ASSETDIR STREQUAL "")
        message(WARNING "ASSETDIR not set, set to default CMAKE_CURRENT_SOURCE_DIR: ${CMAKE_CURRENT_SOURCE_DIR}")
        set(KMCMAKE_CC_XXD_ASSETDIR ${CMAKE_CURRENT_SOURCE_DIR})
    endif()

    if(NOT DEFINED KMCMAKE_CC_XXD_INCLUDEBASE OR KMCMAKE_CC_XXD_INCLUDEBASE STREQUAL "")
        message(WARNING "INCLUDEBASE not set, set to default PROJECT_SOURCE_DIR: ${PROJECT_SOURCE_DIR}")
        set(KMCMAKE_CC_XXD_INCLUDEBASE ${PROJECT_SOURCE_DIR})
    endif()


    if(NOT DEFINED KMCMAKE_CC_XXD_OUTDIR OR KMCMAKE_CC_XXD_OUTDIR STREQUAL "")
        message(WARNING "OUTDIR not set, set to default CMAKE_CURRENT_SOURCE_DIR: ${CMAKE_CURRENT_SOURCE_DIR}")
        set(KMCMAKE_CC_XXD_OUTDIR ${CMAKE_CURRENT_SOURCE_DIR})
    endif()

    foreach (P ${KMCMAKE_CC_XXD_FILES})
        get_filename_component(PROTO_ABS ${P} ABSOLUTE BASE_DIR ${KMCMAKE_CC_XXD_ASSETDIR})
    
        string(REGEX REPLACE "[./-]" "_" VAR_NAME "${P}")
        


        set(HDR ${KMCMAKE_CC_XXD_OUTDIR}/${P}.xxd.h)
        set(SRC ${KMCMAKE_CC_XXD_OUTDIR}/${P}.xxd.cc)
        message(STATUS "src: ${SRC}")

        file(RELATIVE_PATH FILE_REL "${KMCMAKE_CC_XXD_INCLUDEBASE}" "${HDR}")

        list(APPEND INCLUDE_FILES ${FILE_REL})

        list(APPEND VAR_NAMES "${VAR_NAME}")
        list(APPEND HDRS ${HDR})
        list(APPEND SRCS ${SRC})
        add_custom_command(
                DEPENDS "${PROTO_ABS}"
                OUTPUT "${SRC}"
                COMMAND "${CMAKE_COMMAND}" "-DHPATH=${FILE_REL}" "-DINPUT=${PROTO_ABS}" "-DOUTPUT=${SRC}" "-DNAMESPACE=${KMCMAKE_CC_XXD_NAMESPACE}" "-DOUTPUTH=${HDR}" "-DVNAME=${VAR_NAME}" -P "${KM_XXD_CMAKE}"
        )
    endforeach ()

    set(SWAEGER_FILES_H "${KMCMAKE_CC_XXD_OUTDIR}/xxd_gen.h")
    file(WRITE  ${SWAEGER_FILES_H} "/// do not modify it, gen by kumo kxxd.cmake\n\n")
    file(APPEND ${SWAEGER_FILES_H} "#pragma once\n")
    file(APPEND ${SWAEGER_FILES_H} "#include <string_view>\n")
    file(APPEND ${SWAEGER_FILES_H} "#include <utility>\n\n")
    file(APPEND ${SWAEGER_FILES_H} "#include <vector>\n\n")
    file(APPEND ${SWAEGER_FILES_H} "namespace ${KMCMAKE_CC_XXD_NAMESPACE} {\n\n")
    file(APPEND ${SWAEGER_FILES_H} "    extern std::vector<std::pair<std::string_view, std::string_view>> xxd_gen_files;\n\n")
    file(APPEND ${SWAEGER_FILES_H} "}  // namespace ${KMCMAKE_CC_XXD_NAMESPACE}\n")

    set(SWAEGER_FILES_CC "${KMCMAKE_CC_XXD_OUTDIR}/xxd_gen.cc")

    file(WRITE ${SWAEGER_FILES_CC} "/// do not modify it, gen by kumo kxxd.cmake\n\n")
    file(APPEND ${SWAEGER_FILES_CC} "#include \"xxd_gen.h\"\n")
    foreach(FILE ${INCLUDE_FILES})
        file(APPEND ${SWAEGER_FILES_CC} "#include <${FILE}>\n")
    endforeach()

    file(APPEND ${SWAEGER_FILES_CC} "\nnamespace ${KMCMAKE_CC_XXD_NAMESPACE} {\n\n")
    file(APPEND ${SWAEGER_FILES_CC} "    std::vector<std::pair<std::string_view, std::string_view>> xxd_gen_files = std::vector<std::pair<std::string_view, std::string_view>> {\n")
    foreach(VAR_ORG ${KMCMAKE_CC_XXD_FILES})
        string(REGEX REPLACE "[./-]" "_" VAR "${VAR_ORG}")
        file(APPEND ${SWAEGER_FILES_CC} "        {\"${VAR_ORG}\", ${VAR}},\n")
    endforeach()
    file(APPEND ${SWAEGER_FILES_CC} "    }; // std::vector<std::pair<std::string_view, std::string_view>> xxd_gen_files\n")
    file(APPEND ${SWAEGER_FILES_CC} "}  // namespace ${KMCMAKE_CC_XXD_NAMESPACE}\n")
    
    list(APPEND HDRS ${SWAEGER_FILES_H})
    list(APPEND SRCS ${SWAEGER_FILES_CC})
    set(${KMCMAKE_CC_XXD_NAME}_HDRS ${HDRS} PARENT_SCOPE)
    set(${KMCMAKE_CC_XXD_NAME}_SRCS ${SRCS} PARENT_SCOPE)
    message(STATUS "${${KMCMAKE_CC_XXD_NAME}_SRCS}")
endfunction()

