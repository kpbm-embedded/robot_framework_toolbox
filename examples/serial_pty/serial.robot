*** Settings ***
Documentation     The same checks through two libraries on one serial port. Without ${PORT} given, the fake
...               device serves a pty (Suite Setup); with -v PORT:/dev/ttyACM0 the board answers instead.

Library           OperatingSystem
Library           Process
Library           SerialLibrary
Library           ConsoleLibrary    timeout=5s

Suite Setup       Start Fake Board
Suite Teardown    Stop Everything


*** Variables ***
${PORT}    ${OUTPUT_DIR}/ttyFAKE0
${BAUD}    115200
${FAKE}    ${TRUE}


*** Test Cases ***
SerialLibrary Reads The Answer Of A Command
    Add Port    ${PORT}    baudrate=${BAUD}    timeout=2
    Reset Input Buffer
    Write Data    version\n    encoding=ascii
    # the terminator is given in hex: 24 = '$', the end of the prompt
    ${out}=    Read Until    terminator=24    encoding=ascii
    Should Contain    ${out}    Zephyr version
    [Teardown]    Delete All Ports

ConsoleLibrary Runs Shell Commands On The Port
    Open Serial Console    ${PORT}    ${BAUD}    alias=board
    Write Line    ${EMPTY}
    Wait For Prompt
    ${out}=    Run Shell Command    demo hello uart
    Should Be Equal    ${out}    hello uart
    ${out}=    Run Shell Command    echo 0123456789abcdef
    Should Be Equal    ${out}    0123456789abcdef
    [Teardown]    Stop Console    board


*** Keywords ***
Start Fake Board
    IF    not ${FAKE}    RETURN
    Evaluate    os.unlink($PORT) if os.path.lexists($PORT) else None    modules=os    # a link left by a killed run
    Start Process    python    -u    %{ROBOTLIB}/fake_device.py    --pty    ${PORT}    alias=fake
    Wait Until Created    ${PORT}    timeout=10s

Stop Everything
    Stop All Consoles
    Terminate All Processes
