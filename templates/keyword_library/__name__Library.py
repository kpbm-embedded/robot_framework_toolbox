"""@NAME@Library: your own keywords in Python. Every public method is a keyword (``read_register`` ->
``Read Register``). Docs: robot-box libdoc @NAME@Library.py @NAME@Library.html"""
from robot.api import logger
from robot.api.deco import keyword, library


@library(scope="SUITE")
class @NAME@Library:
    """Keywords for one device; replace the bodies with your protocol (UART frames, I2C via a bridge, CAN, ...)."""

    def __init__(self, device="sim"):
        self._device = device
        self._registers = {0x00: 0x42}   # a fake register map: the "sim" device

    @keyword
    def read_register(self, address):
        """Returns the value of register ``address`` (int or ``0x..`` text)."""
        addr = int(str(address), 0)
        value = self._registers.get(addr, 0)
        logger.info(f"{self._device}: reg 0x{addr:02x} = 0x{value:02x}")
        return value

    @keyword
    def write_register(self, address, value):
        """Writes ``value`` to register ``address``."""
        self._registers[int(str(address), 0)] = int(str(value), 0)

    @keyword
    def register_should_be(self, address, expected):
        """Fails unless register ``address`` holds ``expected``."""
        got = self.read_register(address)
        if got != int(str(expected), 0):
            raise AssertionError(f"register {address}: 0x{got:02x} != {expected}")
