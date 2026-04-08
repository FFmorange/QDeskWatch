cmake_minimum_required(VERSION 3.16)

project(QDeskWatch VERSION 1.1.0 LANGUAGES CXX)

set(APP_BUILD_VERSION "${PROJECT_VERSION}" CACHE STRING "Application display/build version")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Core Network Widgets)

qt_standard_project_setup(REQUIRES 6.8)
include(GNUInstallDirs)

file(GLOB_RECURSE APP_SOURCES CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/*.h"
)

file(GLOB_RECURSE APP_RESOURCES CONFIGURE_DEPENDS
    RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}"
    "${CMAKE_CURRENT_SOURCE_DIR}/resources/*"
)

file(GLOB_RECURSE APP_QML_FILES CONFIGURE_DEPENDS
    RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}"
    "${CMAKE_CURRENT_SOURCE_DIR}/qml/*.qml"
    "${CMAKE_CURRENT_SOURCE_DIR}/qml/*.js"
)

set(APP_PLATFORM_SOURCES)

# 注册 PropertySingleton 为模块单例，并设置别名 PS
# QT_RESOURCE_ALIAS 决定模块内文件名，进而决定 QML 组件名
set_source_files_properties("qml/singletons/PropertySingleton.qml"
    PROPERTIES
        QT_RESOURCE_ALIAS    "PS.qml"
        QT_QML_SINGLETON_TYPE TRUE
)

# 注册 Theme 为模块单例
set_source_files_properties("qml/singletons/Theme.qml"
    PROPERTIES
        QT_QML_SINGLETON_TYPE TRUE
)

set_source_files_properties("qml/singletons/AppShell.qml"
    PROPERTIES
        QT_QML_SINGLETON_TYPE TRUE
)

if(WIN32)
    set(APP_ICON_ICO "${CMAKE_CURRENT_SOURCE_DIR}/resources/app-icon/qdeskwatch.ico")
    file(TO_NATIVE_PATH "${APP_ICON_ICO}" APP_ICON_ICO_NATIVE)
    string(REPLACE "\\" "\\\\" APP_ICON_ICO_RC "${APP_ICON_ICO_NATIVE}")

    configure_file(
        "${CMAKE_CURRENT_SOURCE_DIR}/packaging/windows/qdeskwatch.rc.in"
        "${CMAKE_CURRENT_BINARY_DIR}/qdeskwatch.rc"
        @ONLY
    )

    list(APPEND APP_PLATFORM_SOURCES
        "${CMAKE_CURRENT_BINARY_DIR}/qdeskwatch.rc"
    )
endif()

qt_add_executable(QDeskWatch
    main.cpp
    ${APP_SOURCES}
    ${APP_PLATFORM_SOURCES}
)

qt_add_qml_module(QDeskWatch
    URI QDeskWatch
    QML_FILES
        Main.qml
        ${APP_QML_FILES}
    RESOURCES
        ${APP_RESOURCES}
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(QDeskWatch PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.QDeskWatch
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_include_directories(QDeskWatch PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/src")

target_compile_definitions(QDeskWatch
    PRIVATE
        APP_NAME="${PROJECT_NAME}"
        APP_VERSION="${APP_BUILD_VERSION}"
        APP_QML_URI="${PROJECT_NAME}"
)

target_link_libraries(QDeskWatch
    PRIVATE Qt6::Quick Qt6::Core Qt6::Network Qt6::Widgets
)

if(WIN32)
    target_link_libraries(QDeskWatch PRIVATE dbghelp)
endif()

set(MARKET_PLUGIN_PRIVATE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/private-modules/market-plugin")
set(MARKET_PLUGIN_INSTALL_DIR "${CMAKE_INSTALL_BINDIR}/plugins/market")

if(EXISTS "${MARKET_PLUGIN_PRIVATE_DIR}/CMakeLists.txt")
    add_subdirectory("${MARKET_PLUGIN_PRIVATE_DIR}"
                     "${CMAKE_CURRENT_BINARY_DIR}/private-modules/market-plugin")
elseif(WIN32)
    set(MARKET_PLUGIN_PUBLIC_FILE
        "${CMAKE_CURRENT_SOURCE_DIR}/plugins/market/QDeskWatchMarket.dll")

    if(EXISTS "${MARKET_PLUGIN_PUBLIC_FILE}")
        add_custom_command(TARGET QDeskWatch POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E make_directory
                    "$<TARGET_FILE_DIR:QDeskWatch>/plugins/market"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                    "${MARKET_PLUGIN_PUBLIC_FILE}"
                    "$<TARGET_FILE_DIR:QDeskWatch>/plugins/market/QDeskWatchMarket.dll"
        )

        install(FILES "${MARKET_PLUGIN_PUBLIC_FILE}"
            DESTINATION "${MARKET_PLUGIN_INSTALL_DIR}"
        )
    endif()
endif()

install(TARGETS QDeskWatch
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

qt_generate_deploy_qml_app_script(
    TARGET QDeskWatch
    OUTPUT_SCRIPT qt_deploy_script
    MACOS_BUNDLE_POST_BUILD
    NO_UNSUPPORTED_PLATFORM_ERROR
    DEPLOY_USER_QML_MODULES_ON_UNSUPPORTED_PLATFORM
)
install(SCRIPT ${qt_deploy_script})
