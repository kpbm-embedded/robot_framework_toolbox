*** Settings ***
Documentation    Zephyr in Renode, for suites run by ./robot-box renode (Renode's renode-test). Needs the
...              Renode keywords: put ``Resource ${RENODEKEYWORDS}`` before this file.


*** Keywords ***
Start Zephyr In Renode
    [Documentation]    Loads ``elf`` on the platform of ``resc`` (a Renode script that uses $elf) and opens a
    ...    terminal tester on ``uart``. The emulation is paused between waits (deterministic virtual time).
    [Arguments]    ${elf}    ${resc}    ${uart}=sysbus.uart0
    Execute Command    $elf=@${elf}
    Execute Command    include @${resc}
    Create Terminal Tester    ${uart}    defaultPauseEmulation=True
    Write Char Delay    0.01
    Wait For Line On Uart    Booting Zephyr OS    timeout=30

Renode Shell Should Answer
    [Documentation]    Writes ``command`` to the Zephyr shell over the UART and waits for ``expected``.
    [Arguments]    ${command}    ${expected}    ${timeout}=10
    Write Line To Uart    ${command}
    Wait For Line On Uart    ${expected}    timeout=${timeout}
