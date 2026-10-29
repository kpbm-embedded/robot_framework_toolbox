*** Settings ***
Documentation     @NAME@: a real board on a UART (USB CDC or a USB-serial adapter on the console pins).
...               Run: robot-box robot -v PORT:/dev/ttyACM0 @NAME@.robot   (-v BAUD:115200, -v RESET_CMD:...)
...               Optional RESET_CMD (e.g. ``probe-rs reset --chip STM32F411CEUx``) resets the board in setup
...               so the boot banner is seen.

Library           Process
Library           ConsoleLibrary    timeout=10s    char_delay=0.002

Suite Setup       Connect Board
Suite Teardown    Stop All Consoles


*** Variables ***
${PORT}         /dev/ttyACM0
${BAUD}         115200
${RESET_CMD}    ${EMPTY}


*** Test Cases ***
Boots Or Already Runs
    Write Line    ${EMPTY}
    Wait For Prompt

Version Is Printed
    ${out}=    Run Shell Command    kernel version
    Should Contain    ${out}    Zephyr version

Stays Up For Five Seconds
    Should Not See    FATAL ERROR    duration=5s


*** Keywords ***
Connect Board
    Open Serial Console    ${PORT}    ${BAUD}    alias=board
    IF    "${RESET_CMD}" != ""
        ${r}=    Run Process    ${RESET_CMD}    shell=True    timeout=60s    stderr=STDOUT
        Should Be Equal As Integers    ${r.rc}    0    reset failed: ${r.stdout}
        Wait For Line    Booting Zephyr OS    timeout=15s
    END
