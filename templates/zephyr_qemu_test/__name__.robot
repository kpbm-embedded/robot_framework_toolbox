*** Settings ***
Documentation     @NAME@: a Zephyr image on qemu, tested over its console.
...               Run: robot-box robot @NAME@.robot -v EXAMPLE:shell -v BOARD:qemu_cortex_m3
...               (EXAMPLE = a 32_03_zephyr example; for your own source set SRC and BUILD instead).

Resource          zephyr.resource

Suite Setup       Boot Target
Suite Teardown    Stop All Consoles


*** Variables ***
${EXAMPLE}    shell
${BOARD}      qemu_cortex_m3
${SRC}        ${EMPTY}
${BUILD}      ${OUTPUT_DIR}/zephyr-build


*** Test Cases ***
Shell Prompt Comes Up
    Write Line    ${EMPTY}
    Wait For Prompt

Kernel Answers
    Zephyr Shell Should Answer    kernel version    Zephyr version

No Fatal Error
    Should Not See    FATAL ERROR    duration=1s


*** Keywords ***
Boot Target
    IF    "${SRC}" == ""
        Start Zephyr Example On Qemu    ${EXAMPLE}    ${BOARD}
    ELSE
        Build Zephyr Source    ${SRC}    ${BOARD}    ${BUILD}
        Start Zephyr Build On Qemu    ${BUILD}
    END
