*** Settings ***
Documentation    Zephyr keywords: build an example or app with 32_03_zephyr (scripts/app) and run it on qemu
...              through ConsoleLibrary. The Zephyr ID comes from %{ZEPHYR_ID} (set by ./robot-box).

Library          OperatingSystem
Library          Process
Library          String
Library          ConsoleLibrary    timeout=20s


*** Variables ***
${ZEPHYR_APP}       %{ZEPHYR_ID}/scripts/app
${BUILD_TIMEOUT}    15 min


*** Keywords ***
Build Zephyr Example
    [Documentation]    Builds 32_03_zephyr example ``example`` for ``board``; returns the path of zephyr.elf.
    [Arguments]    ${example}    ${board}
    ${r}=    Run Process    ${ZEPHYR_APP}    example    ${example}    ${board}
    ...    timeout=${BUILD_TIMEOUT}    stderr=STDOUT
    Should Be Equal As Integers    ${r.rc}    0    build of ${example} for ${board} failed:\n${r.stdout}
    ${elf}=    Get Lines Matching Regexp    ${r.stdout}    .*/zephyr\\.elf$
    Should Not Be Empty    ${elf}    no zephyr.elf in the build output:\n${r.stdout}
    RETURN    ${elf.strip()}

Build Zephyr Source
    [Documentation]    Builds any Zephyr source folder ``src`` for ``board`` into ``build`` with west; returns zephyr.elf.
    [Arguments]    ${src}    ${board}    ${build}    @{extra}
    ${r}=    Run Process    bash    -c    . "$1" && shift && west build -p auto "$@"
    ...    _    %{ZEPHYR_ID}/toolchain/zephyr/env.sh    -b    ${board}    -d    ${build}    ${src}    @{extra}
    ...    timeout=${BUILD_TIMEOUT}    stderr=STDOUT
    Should Be Equal As Integers    ${r.rc}    0    west build of ${src} for ${board} failed:\n${r.stdout}
    File Should Exist    ${build}/zephyr/zephyr.elf
    RETURN    ${build}/zephyr/zephyr.elf

Start Zephyr Example On Qemu
    [Documentation]    Builds (if needed) and boots ``example`` on qemu ``board`` as console ``alias``;
    ...    waits for the boot banner.
    [Arguments]    ${example}    ${board}=qemu_cortex_m3    ${alias}=qemu
    Build Zephyr Example    ${example}    ${board}
    Start Console    ${ZEPHYR_APP}    run    ${example}    ${board}    alias=${alias}
    Wait For Line    Booting Zephyr OS    timeout=60s

Start Zephyr Build On Qemu
    [Documentation]    Boots an existing build folder on qemu (``west build -t run``) as console ``alias``.
    [Arguments]    ${build}    ${alias}=qemu
    Start Console    bash    -c    . "$1" && exec west build -d "$2" -t run
    ...    _    %{ZEPHYR_ID}/toolchain/zephyr/env.sh    ${build}    alias=${alias}
    Wait For Line    Booting Zephyr OS    timeout=60s

Zephyr Shell Should Answer
    [Documentation]    Runs ``command`` in the Zephyr shell of the current console; the reply must contain ``expected``.
    [Arguments]    ${command}    ${expected}
    ${out}=    Run Shell Command    ${command}
    Should Contain    ${out}    ${expected}
    RETURN    ${out}

Ztest Run Should Pass
    [Documentation]    Waits for the end of a ztest image on the current console and fails on any failed case.
    ...    Returns the summary line.
    [Arguments]    ${timeout}=120s
    ${line}=    Wait For Line    PROJECT EXECUTION (SUCCESSFUL|FAILED)    timeout=${timeout}    regex=True
    ${out}=    Console Output
    Should Not Contain    ${out}    FAIL -    msg=ztest reported failed cases
    Should Contain    ${line}    SUCCESSFUL
    RETURN    ${line}
