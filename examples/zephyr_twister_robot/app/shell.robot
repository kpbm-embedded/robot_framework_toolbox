*** Settings ***
Documentation    Run by twister (harness: robot). ${KEYWORDS}, ${ELF}, ${RESC} and ${UART} come from twister;
...              ``Prepare Machine`` is in $ZEPHYR_BASE/tests/robot/common.robot.

Resource         ${KEYWORDS}


*** Test Cases ***
Should Answer Demo Command
    Prepare Machine
    Wait For Prompt On Uart    uart:~$
    Write Line To Uart    demo hello twister
    Wait For Line On Uart    hello twister
    Write Line To Uart    kernel version
    Wait For Line On Uart    Zephyr version
