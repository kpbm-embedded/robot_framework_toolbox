*** Settings ***
Documentation    @NAME@: debugging from a test. Renode starts a GDB server; gdb in batch mode stops at
...              ${BREAK}, prints ${EXPR}, and the test checks the result.
...              Run: robot-box renode @NAME@.robot --variable ELF:<zephyr.elf> --variable RESC:<board.resc>
...              --variable GDB:<arch-zephyr-elf-gdb from the Zephyr SDK>

Resource         ${RENODEKEYWORDS}
Library          Process


*** Variables ***
${PORT}     3333
${BREAK}    main
${EXPR}     $pc


*** Test Cases ***
Gdb Reaches The Breakpoint
    Execute Command    $elf=@${ELF}
    Execute Command    include @${RESC}
    Execute Command    machine StartGdbServer ${PORT}
    ${gdb}=    Start Process    ${GDB}    -q    -batch    -nx    ${ELF}
    ...    -ex    target remote :${PORT}
    ...    -ex    break ${BREAK}
    ...    -ex    monitor start
    ...    -ex    continue
    ...    -ex    bt
    ...    -ex    print ${EXPR}
    ...    -ex    detach
    ...    stderr=STDOUT
    ${r}=    Wait For Process    ${gdb}    timeout=60s    on_timeout=kill
    Log    ${r.stdout}
    Should Contain    ${r.stdout}    Breakpoint 1, ${BREAK}
