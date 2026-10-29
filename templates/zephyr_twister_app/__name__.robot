*** Settings ***
Documentation    @NAME@: run by twister (harness: robot); KEYWORDS, ELF, RESC and UART come from twister.

Resource         ${KEYWORDS}


*** Test Cases ***
Should Answer Ping
    Prepare Machine
    Wait For Prompt On Uart    uart:~$
    Write Line To Uart    ping
    Wait For Line On Uart    pong
