*** Settings ***
Documentation    Linux target tests over the console: log in, run commands, check their output. On a real
...              board the same steps run over SSH (templates/ssh_linux_test) or a UART (serial_hw_test).
...              renode-test resets the emulation between tests, so one test boots once and checks all.

Resource         ${RENODEKEYWORDS}


*** Test Cases ***
Linux Boots, Logs In And Runs Commands
    Boot And Log In
    Linux Command Should Print    uname -m    ^armv7l
    Linux Command Should Print    mount    on / type
    Linux Command Should Print    ps    \\binit\\b
    Write Line To Uart    echo robot-box > /tmp/probe
    Linux Command Should Print    cat /tmp/probe    ^robot-box


*** Keywords ***
Boot And Log In
    Execute Command    $demos=@${DEMOS}
    Execute Command    include @${RESC}
    Create Terminal Tester    sysbus.uart0    defaultPauseEmulation=True
    Wait For Prompt On Uart    buildroot login:    timeout=90
    Write Line To Uart    root
    Wait For Prompt On Uart    \#${SPACE}

Linux Command Should Print
    [Arguments]    ${command}    ${expected}
    Write Line To Uart    ${command}
    Wait For Line On Uart    ${expected}    treatAsRegex=true
