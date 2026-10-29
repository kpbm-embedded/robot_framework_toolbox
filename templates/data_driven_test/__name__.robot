*** Settings ***
Documentation     @NAME@: one row per test: command and the regular expression its reply must match.
...               Run against the fake board: robot-box robot @NAME@.robot
...               against a board: robot-box robot -v PORT:/dev/ttyACM0 @NAME@.robot

Library           ConsoleLibrary    timeout=5s

Suite Setup       Open Target
Suite Teardown    Stop All Consoles
Test Template     Reply Should Match


*** Variables ***
${PORT}    ${EMPTY}


*** Test Cases ***    COMMAND    REPLY
Version    version    Zephyr version \\d+
Hello    demo hello    hello world


*** Keywords ***
Open Target
    IF    "${PORT}" == ""
        Start Console    python    -u    %{ROBOTLIB}/fake_device.py    alias=target
    ELSE
        Open Serial Console    ${PORT}    alias=target
        Write Line    ${EMPTY}
    END
    Wait For Prompt

Reply Should Match
    [Arguments]    ${command}    ${reply}
    ${out}=    Run Shell Command    ${command}
    Should Match Regexp    ${out}    ${reply}
