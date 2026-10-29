*** Settings ***
Documentation     32_03_zephyr's ``shell`` example on qemu: kernel and custom commands over the console.

Resource          zephyr.resource

Suite Setup       Start Zephyr Example On Qemu    shell    ${BOARD}
Suite Teardown    Stop All Consoles


*** Variables ***
${BOARD}    qemu_cortex_m3


*** Test Cases ***
Prompt Comes Up
    Write Line    ${EMPTY}
    Wait For Prompt

Kernel Version Is Printed
    Zephyr Shell Should Answer    kernel version    Zephyr version

Custom Command Group Works
    Zephyr Shell Should Answer    demo hello qemu    hello qemu

Uptime Advances
    ${a}=    Zephyr Shell Should Answer    demo uptime    uptime
    Sleep    0.3s
    ${b}=    Zephyr Shell Should Answer    demo uptime    uptime
    ${ta}=    Evaluate    int(re.search(r'uptime (\\d+)', $a).group(1))    modules=re
    ${tb}=    Evaluate    int(re.search(r'uptime (\\d+)', $b).group(1))    modules=re
    Should Be True    ${tb} > ${ta}

No Crash While Idle
    Should Not See    FATAL ERROR    duration=1s
