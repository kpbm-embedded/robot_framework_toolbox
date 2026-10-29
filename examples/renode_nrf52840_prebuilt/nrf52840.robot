*** Settings ***
Documentation    A binary you did not build (a vendor or CI artifact) tested in Renode: the platform comes
...              is 32_06_renode's nice!nano (nRF52840 + LED/button), the test uses Renode keywords.

Resource         ${RENODEKEYWORDS}

Test Setup       Boot


*** Test Cases ***
Shell Answers Its Demo Command
    Wait For Prompt On Uart    uart:~$    timeout=10
    Write Line To Uart    demo ping
    Wait For Line On Uart    pong

Machine State Can Be Read From The Test
    Wait For Prompt On Uart    uart:~$    timeout=10
    ${pc}=    Execute Command    sysbus.cpu PC
    Should Match Regexp    ${pc}    0x[0-9a-fA-F]+


*** Keywords ***
Boot
    Execute Command    mach create "nrf52840"
    Execute Command    machine LoadPlatformDescription @${REPL}
    Execute Command    sysbus LoadELF @${ELF}
    Create Terminal Tester    sysbus.uart0    defaultPauseEmulation=True
    Write Char Delay    0.01
