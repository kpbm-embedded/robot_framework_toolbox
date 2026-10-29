*** Settings ***
Documentation    Zephyr's shell on Renode's RISC-V 32 virtual board, with the board's own Renode script from
...              the Zephyr tree. Virtual time: the emulation runs only while a keyword waits.

Resource         ${RENODEKEYWORDS}
Resource         ${ROBOTLIB}/renode_zephyr.resource

Test Setup       Start Zephyr In Renode    ${ELF}    ${RESC}    sysbus.uart0


*** Variables ***
${RESC}    ${ZEPHYR_BASE}/boards/renode/riscv32_virtual/support/riscv32_virtual.resc


*** Test Cases ***
Shell Prompt Comes Up
    Wait For Prompt On Uart    uart:~$

Kernel Version Is Printed
    Wait For Prompt On Uart    uart:~$
    Renode Shell Should Answer    kernel version    Zephyr version

Custom Command Answers
    Wait For Prompt On Uart    uart:~$
    Renode Shell Should Answer    demo hello renode    hello renode

Uptime Follows Virtual Time
    Wait For Prompt On Uart    uart:~$
    Execute Command    emulation RunFor "2"
    Write Line To Uart    demo uptime
    ${l}=    Wait For Line On Uart    uptime (\\d+) ms    treatAsRegex=true
    ${ms}=    Evaluate    int($l['Groups'][0])    # Renode returns Line, Groups (the regex captures), Timestamp
    Should Be True    ${ms} >= 2000    uptime ${ms} ms after 2 s of virtual time
