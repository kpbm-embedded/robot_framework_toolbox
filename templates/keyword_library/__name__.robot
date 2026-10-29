*** Settings ***
Documentation    @NAME@: tests that use @NAME@Library.py (next to this file).
...              Run: robot-box robot @NAME@.robot

Library          ${CURDIR}/@NAME@Library.py    device=sim


*** Test Cases ***
Reset Value Is Known
    Register Should Be    0x00    0x42

Written Value Reads Back
    Write Register    0x10    0xA5
    Register Should Be    0x10    0xA5
