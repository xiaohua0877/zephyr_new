# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.13.1)

include($ENV{ZEPHYR_BASE}/cmake/app/boilerplate.cmake NO_POLICY_SCOPE)
project(hello_world)

##target_sources(app PRIVATE src/hello_main.c)

##FILE(GLOB app_sources src/*.c)
##target_sources(app PRIVATE ${app_sources})

FILE(GLOB app_sources src/logger/*.c)
FILE(GLOB alarm_sources src/alarm/*.c)
FILE(GLOB bmi160_sources src/bmi160/*.c)
FILE(GLOB shell_sources src/shell/*.c)
target_sources(
    app PRIVATE 
    src/hello_main.c
    src/led_main.c
)
zephyr_library_sources_ifdef(CONFIG_SAMPLES_LOGGER_MAIN     ${app_sources})
zephyr_library_sources_ifdef(CONFIG_SAMPLES_ALARM_MAIN     ${alarm_sources})
zephyr_library_sources_ifdef(CONFIG_SAMPLES_BMI160_MAIN     ${bmi160_sources})
zephyr_library_sources_ifdef(CONFIG_SAMPLES_FS_MAIN          src/fs/fs_main.c)
zephyr_library_sources_ifdef(CONFIG_SYNCHRONIZATION_FS_MAIN          src/synchronization/sync_main.c)