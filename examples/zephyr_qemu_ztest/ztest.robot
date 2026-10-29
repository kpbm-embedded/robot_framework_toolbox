*** Settings ***
Documentation    A ztest image is a test of its own; Robot boots it and turns its summary into a test result,
...              so ztest suites sit in the same report as shell and hardware tests.

Resource         zephyr.resource

Test Teardown    Stop All Consoles
Test Template    Ztest Image Should Pass


*** Variables ***
${BOARD}    qemu_cortex_m3


*** Test Cases ***    EXAMPLE    CASES
FIFO Suite    ztest-basic    test_order_is_kept
FFF Fakes Suite    ztest-fff    test_retries_after_error


*** Keywords ***
Ztest Image Should Pass
    [Arguments]    ${example}    ${a_case}
    Start Zephyr Example On Qemu    ${example}    ${BOARD}
    Ztest Run Should Pass
    ${out}=    Console Output
    Should Contain    ${out}    PASS - ${a_case}
