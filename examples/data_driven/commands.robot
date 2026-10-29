*** Settings ***
Documentation     Each row is a test: the command for the shell and a regular expression its reply must match.
...               Add a row, get a test. Keyword docs of ConsoleLibrary: ConsoleLibrary.html next to the log.

Library           ConsoleLibrary    timeout=5s

Suite Setup       Boot Fake Board
Suite Teardown    Stop All Consoles
Test Template     Reply Should Match


*** Test Cases ***    COMMAND    REPLY
Version    version    ^Zephyr version 4\\.\\d+\\.\\d+$
Hello Default    demo hello    ^hello world$
Hello Name    demo hello box    ^hello box$
Uptime    demo uptime    ^uptime \\d+ ms$
LED On    led on    ^led on$
LED State    led state    ^led is on$
LED Off    led off    ^led off$
Echo    echo a b c    ^a b c$
Unknown    nosuch    ^nosuch: command not found$


*** Keywords ***
Boot Fake Board
    Start Console    python    -u    %{ROBOTLIB}/fake_device.py    alias=board
    Wait For Prompt

Reply Should Match
    [Arguments]    ${command}    ${reply}
    ${out}=    Run Shell Command    ${command}
    Should Match Regexp    ${out}    ${reply}
