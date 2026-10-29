*** Settings ***
Documentation    @NAME@: a ztest image's results as a Robot test, on qemu or on a board.
...              qemu:  robot-box robot -v EXAMPLE:ztest-basic @NAME@.robot
...              board: robot-box robot -v PORT:/dev/ttyACM0 @NAME@.robot   (flash the ztest image first)

Resource         zephyr.resource

Test Teardown    Stop All Consoles


*** Variables ***
${EXAMPLE}    ztest-basic
${BOARD}      qemu_cortex_m3
${PORT}       ${EMPTY}


*** Test Cases ***
Ztest Suite Passes
    IF    "${PORT}" == ""
        Start Zephyr Example On Qemu    ${EXAMPLE}    ${BOARD}
    ELSE
        Open Serial Console    ${PORT}    115200
    END
    ${summary}=    Ztest Run Should Pass    timeout=300s
    Log    ${summary}
