*** Settings ***
Documentation     @NAME@: hardware in the loop: build a 32_03_zephyr example, flash it (west flash: openocd,
...               jlink, ... per board), then test it over the UART.
...               Run: robot-box robot -v EXAMPLE:shell -v BOARD:blackpill_f411ce -v PORT:/dev/ttyUSB0 @NAME@.robot

Library           Process
Resource          zephyr.resource

Suite Setup       Build, Flash And Connect
Suite Teardown    Stop All Consoles


*** Variables ***
${EXAMPLE}    shell
${BOARD}      blackpill_f411ce
${PORT}       /dev/ttyUSB0
${BAUD}       115200


*** Test Cases ***
New Firmware Boots
    Wait For Line    Booting Zephyr OS    timeout=20s

Shell Works On The Board
    Write Line    ${EMPTY}
    Wait For Prompt
    Zephyr Shell Should Answer    kernel version    Zephyr version


*** Keywords ***
Build, Flash And Connect
    ${elf}=    Build Zephyr Example    ${EXAMPLE}    ${BOARD}
    ${build}=    Evaluate    os.path.dirname(os.path.dirname($elf))    modules=os
    Open Serial Console    ${PORT}    ${BAUD}    alias=board    # before flashing: the banner is not missed
    ${r}=    Run Process    bash    -c    . "$1" && west flash -d "$2"
    ...    _    %{ZEPHYR_ID}/toolchain/zephyr/env.sh    ${build}    timeout=5 min    stderr=STDOUT
    Should Be Equal As Integers    ${r.rc}    0    west flash failed:\n${r.stdout}
