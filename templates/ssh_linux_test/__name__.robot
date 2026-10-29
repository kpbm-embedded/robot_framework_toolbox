*** Settings ***
Documentation     @NAME@: an embedded Linux board (Yocto, buildroot, Raspberry Pi OS) over SSH.
...               Run: robot-box robot -v HOST:192.168.1.50 -v USER:root -v KEY:<your key file> @NAME@.robot
...               No password in files: use a key (KEY) or -v PASSWORD:... on the command line.

Library           OperatingSystem
Library           SSHLibrary    timeout=30s

Suite Setup       Connect
Suite Teardown    Close All Connections


*** Variables ***
${HOST}        192.168.1.50
${USER}        root
${KEY}         ${EMPTY}
${PASSWORD}    ${EMPTY}
${SERVICE}     sshd


*** Test Cases ***
Kernel And Architecture
    ${out}=    Execute Command    uname -srm
    Log    ${out}
    Should Not Be Empty    ${out}

Root Filesystem Has Space
    ${pct}=    Execute Command    df --output=pcent / | tail -1 | tr -dc 0-9
    Should Be True    ${pct} < 90    root filesystem ${pct}% full

Service Is Running
    ${out}    ${rc}=    Execute Command    systemctl is-active ${SERVICE} || pidof ${SERVICE}    return_rc=True
    Should Be Equal As Integers    ${rc}    0    ${SERVICE} is not running: ${out}

File Round Trip
    Create File    ${OUTPUT_DIR}/probe.txt    robot-box
    Put File    ${OUTPUT_DIR}/probe.txt    /tmp/probe.txt
    ${out}=    Execute Command    cat /tmp/probe.txt && rm /tmp/probe.txt
    Should Be Equal    ${out}    robot-box


*** Keywords ***
Connect
    Open Connection    ${HOST}
    IF    "${KEY}" != ""
        Login With Public Key    ${USER}    ${KEY}
    ELSE
        Login    ${USER}    ${PASSWORD}
    END
