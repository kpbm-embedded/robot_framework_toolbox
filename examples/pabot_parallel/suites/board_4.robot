*** Settings ***
Documentation     Board 4 of 4: pabot runs each suite in its own process (own consoles, own board).

Library           ConsoleLibrary    timeout=5s

Suite Setup       Start Console    python    -u    %{ROBOTLIB}/fake_device.py    alias=board4
Suite Teardown    Stop All Consoles


*** Test Cases ***
Board 4 Boots
    Wait For Line    Booting Zephyr OS
    Wait For Prompt

Board 4 Answers
    ${out}=    Run Shell Command    demo hello board4
    Should Be Equal    ${out}    hello board4

Board 4 Takes Its Time
    Sleep    1s    # four suites of ~1 s each finish in ~1 s together
    ${out}=    Run Shell Command    led on
    Should Be Equal    ${out}    led on
