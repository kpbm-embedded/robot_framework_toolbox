*** Settings ***
Documentation    @NAME@: a Zephyr image in Renode (virtual time, deterministic).
...              Run: robot-box renode @NAME@.robot --variable ELF:<zephyr.elf> --variable RESC:<board.resc>
...              RESC: the board's support/*.resc in the Zephyr tree, or 32_06_renode: renode-box new board.

Resource         ${RENODEKEYWORDS}
Resource         ${ROBOTLIB}/renode_zephyr.resource

Test Setup       Start Zephyr In Renode    ${ELF}    ${RESC}    ${UART}


*** Variables ***
${UART}    sysbus.uart0


*** Test Cases ***
Prompt Comes Up
    Wait For Prompt On Uart    uart:~$

Command Answers
    Wait For Prompt On Uart    uart:~$
    Renode Shell Should Answer    kernel version    Zephyr version

Uptime Follows Virtual Time
    Wait For Prompt On Uart    uart:~$
    Execute Command    emulation RunFor "1"
    Write Line To Uart    kernel uptime
    ${l}=    Wait For Line On Uart    Uptime: (\\d+) ms    treatAsRegex=true
    Should Be True    int($l['Groups'][0]) >= 1000
