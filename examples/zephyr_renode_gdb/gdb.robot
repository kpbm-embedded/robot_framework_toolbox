*** Settings ***
Documentation    Debugging in Renode: the machine starts with a GDB server, gdb (Zephyr SDK) connects in batch
...              mode, stops at a ztest function, reads a variable and lets the image finish.

Resource         ${RENODEKEYWORDS}
Library          Process


*** Variables ***
${RESC}    ${ZEPHYR_BASE}/boards/renode/riscv32_virtual/support/riscv32_virtual.resc
${PORT}    3333


*** Test Cases ***
Gdb Stops At A Breakpoint And Reads State
    Execute Command    $elf=@${ELF}
    Execute Command    include @${RESC}
    Execute Command    machine StartGdbServer ${PORT}
    Create Terminal Tester    sysbus.uart0
    ${gdb}=    Start Process    ${GDB}    -q    -batch    -nx    ${ELF}
    ...    -ex    target remote :${PORT}
    ...    -ex    break fifo_put
    ...    -ex    monitor start
    ...    -ex    continue
    ...    -ex    bt 1
    ...    -ex    print f->count
    ...    -ex    delete
    ...    -ex    detach
    ...    stderr=STDOUT
    ${r}=    Wait For Process    ${gdb}    timeout=60s    on_timeout=kill
    Log    ${r.stdout}
    Should Match Regexp    ${r.stdout}    Breakpoint 1, fifo_put
    Should Match Regexp    ${r.stdout}    \\$1 = \\d+
    Execute Command    start
    Wait For Line On Uart    PROJECT EXECUTION SUCCESSFUL    timeout=60
