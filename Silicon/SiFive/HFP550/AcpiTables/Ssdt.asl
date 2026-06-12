#include "SG2044AcpiHeader.h"

DefinitionBlock ("SsdtTable.aml", "SSDT", 2, "SOPHGO", "2044    ",
  EFI_ACPI_RISCV_OEM_REVISION)
{
  External(\_SB.SPI0, DeviceObj)

  Scope(\_SB.SPI0) {
    Device (TPM) {
      Name (_HID, "SMO0768")
      Name (_UID, 0)
        Method (_STA)
        {
          Return (0xF)
        }
      Name (_CRS, ResourceTemplate () {
        SPISerialBus (
          0,                // Chip Select
          PolarityLow,      // CS Active Low
          FourWireMode,
          8,                // Bits per word
          ControllerInitiated,
          10000000,          // Connection speed in Hz
          ClockPolarityLow,
          ClockPhaseFirst,
          "\\_SB.SPI0",     // SPI Path
          0
        )
      })
    }
  }
}
