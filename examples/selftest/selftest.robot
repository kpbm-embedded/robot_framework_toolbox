*** Settings ***
Documentation     ConsoleLibrary on a host process: the fake device in robotlib/ plays a Zephyr shell.

Library           ConsoleLibrary    timeout=5s

Suite Setup       Start Console    python    -u    ${ROBOTLIB}/fake_device.py    alias=dev
Suite Teardown    Stop All Consoles


*** Variables ***
${ROBOTLIB}    %{ROBOTLIB}


*** Test Cases ***
Boot Banner Is Seen
    ${line}=    Wait For Line    Booting Zephyr OS
    Should Contain    ${line}    v4.4.2
    Wait For Prompt

Shell Commands Answer
    ${out}=    Run Shell Command    demo hello robot
    Should Be Equal    ${out}    hello robot
    ${out}=    Run Shell Command    version
    Should Match Regexp    ${out}    ^Zephyr version \\d+\\.\\d+\\.\\d+$

State Is Kept Between Commands
    Run Shell Command    led on
    ${out}=    Run Shell Command    led state
    Should Be Equal    ${out}    led is on

A Missing Line Fails With The Last Output
    Run Keyword And Expect Error    *no line with 'never printed' within 0.5 s*
    ...    Wait For Line    never printed    timeout=0.5s

A Crash Banner Is Caught
    Write Line    crash
    Run Keyword And Expect Error    *FATAL ERROR*appeared*    Should Not See    FATAL ERROR    duration=2s

Unknown Commands Are Reported
    Wait For Prompt
    ${out}=    Run Shell Command    frobnicate
    Should Contain    ${out}    command not found
