/** @file
  The description of power button.

  Copyright (C) 2024, SOPHGO Technologies Inc., Ltd. All rights reserved.<BR>

  SPDX-License-Identifier: BSD-2-Clause-Patent

**/

Scope(_SB)
{
  // Power Button Device description
  Device (PWRB) {
    Name (_HID, EISAID("PNP0C0C"))
    Name (_UID, Zero)
    Method (_STA, 0x0, NotSerialized) {
      Return (0x0B)
    }
  }

  // Generic Event Device (ACPI0013)
  Device (GED0) {
    Name (_HID, "ACPI0013")
    Name (_UID, Zero)
    Method(_STA) {
      Return (0xF)
    }

    Name (_CRS, ResourceTemplate () {
     Interrupt (ResourceConsumer, Edge, ActiveHigh, Shared,,,) { 28 }
    })

    // SWPORTA_DDR
    OperationRegion(PDDR, SystemMemory, 0x704000B004, 4)
    Field(PDDR, DWordAcc, NoLock, Preserve) {
      SWPO, 32
    }

    // INTEN
    OperationRegion(INTE, SystemMemory, 0x704000B030, 4)
    Field(INTE, DWordAcc, NoLock, Preserve) {
      INTN, 32
    }

    // INTMASK
    OperationRegion(INTM, SystemMemory, 0x704000B034, 4)
    Field(INTM, DWordAcc, NoLock, Preserve) {
      MASK, 32
    }

    // INTTYPE_LEVEL
    OperationRegion(INTL, SystemMemory, 0x704000B038, 4)
    Field(INTL, DWordAcc, NoLock, Preserve) {
      LEVL, 32
    }

    // INT_POLARITY
    OperationRegion(INTP, SystemMemory, 0x704000B03C, 4)
    Field(INTP, DWordAcc, NoLock, Preserve) {
      POLA, 32
    }

    // INTSTATUS
    OperationRegion(INTS, SystemMemory, 0x704000B040, 4)
    Field(INTS, DWordAcc, NoLock, Preserve) {
      STAS, 32
    }

    // RAW_INTSTATUS
    OperationRegion(INTR, SystemMemory, 0x704000B044, 4)
    Field(INTR, DWordAcc, NoLock, Preserve) {
      RAWS, 32
    }

    // PORTA_EOI
    OperationRegion(PEOI, SystemMemory, 0x704000B04C, 4)
    Field(PEOI, DWordAcc, NoLock, Preserve) {
      PORT, 32
    }

    // PIN70(GPIO2 BIT7)
    Method(_INI, 0, NotSerialized) {
      // Set Input direction (shutdown)
      Store (SWPO, Local0)
      And (Local0, 0xFFFFFFBF, Local0)
      Store (Local0, SWPO)

      // Set low active
      Store (POLA, Local0)
      And (Local0, 0xFFFFFFBF, Local0)
      Store (Local0, POLA)

      // Set edge sensitive
      Store (LEVL, Local0)
      Or (Local0, 0x40, Local0)
      Store (Local0, LEVL)

      // Enable interrupt
      Store (INTN, Local0)
      Or (Local0, 0x40, Local0)
      Store (Local0, INTN)

      // Unmask the interrupt
      Store (MASK, Local0)
      And (Local0, 0xFFFFFFBF, Local0)
      Store (Local0, MASK)
    }

    Method(_EVT, 1, Serialized) {
      Switch (ToInteger(Arg0)) {
        Case (28) {
          // Active low
          if (And (STAS, 0x40)) {
            // Clear the interrupt.
            Store (PORT, Local0)
            Or (Local0, 0x40, Local0)
            Store (Local0, PORT)

            // Notify OSPM the power button is pressed
            Notify (\_SB.PWRB, 0x80)
          }
        }
      }
    }
  }

  // Reset Button Device description
  Device (RSTB) {
    Name (_HID, "SOPH0013")
    Name (_UID, One)
    Method (_STA, 0x0, NotSerialized) {
      Return (0x0B)
    }
  }

  // GED1 for Reset Button (PIN5)
  Device (GED1) {
    Name (_HID, "ACPI0013")
    Name (_UID, One)
    Method(_STA) {
      Return (0xF)
    }

    Name (_CRS, ResourceTemplate () {
      Interrupt (ResourceConsumer, Edge, ActiveHigh, Shared,,,) { 26 }
    })

    // PIN5 - SWPORTA_DDR
    OperationRegion(PDDR, SystemMemory, 0x7040009004, 4)
    Field(PDDR, DWordAcc, NoLock, Preserve) {
      SWPO, 32
    }

    // PIN5 - INTEN
    OperationRegion(INTE, SystemMemory, 0x7040009030, 4)
    Field(INTE, DWordAcc, NoLock, Preserve) {
      INTN, 32
    }

    // PIN5 - INTMASK
    OperationRegion(INTM, SystemMemory, 0x7040009034, 4)
    Field(INTM, DWordAcc, NoLock, Preserve) {
      MASK, 32
    }

    // PIN5 - INTTYPE_LEVEL
    OperationRegion(INTL, SystemMemory, 0x7040009038, 4)
    Field(INTL, DWordAcc, NoLock, Preserve) {
      LEVL, 32
    }

    // PIN5 - INT_POLARITY
    OperationRegion(INTP, SystemMemory, 0x704000903C, 4)
    Field(INTP, DWordAcc, NoLock, Preserve) {
      POLA, 32
    }

    // PIN5 - INTSTATUS
    OperationRegion(INTS, SystemMemory, 0x7040009040, 4)
    Field(INTS, DWordAcc, NoLock, Preserve) {
      STAS, 32
    }

    // PIN5 - RAW_INTSTATUS
    OperationRegion(INTR, SystemMemory, 0x7040009044, 4)
    Field(INTR, DWordAcc, NoLock, Preserve) {
      RAWS, 32
    }

    // PIN5 - PORTA_EOI
    OperationRegion(PEOI, SystemMemory, 0x704000904C, 4)
    Field(PEOI, DWordAcc, NoLock, Preserve) {
      PORT, 32
    }

    Method(_INI, 0, NotSerialized) {
      // Set PIN5 (GPIO0 BIT5) as input mode (Reset Button)
      Store (SWPO, Local0)
      And (Local0, 0xFFFFFFDF, Local0)  // Clear bit 5
      Store (Local0, SWPO)

      // Set PIN5 Active Low
      Store (POLA, Local0)
      And (Local0, 0xFFFFFFDF, Local0)
      Store (Local0, POLA)

      // Set PIN5 Edge Sensitive
      Store (LEVL, Local0)
      Or (Local0, 0x20, Local0)
      Store (Local0, LEVL)

      // Enable interrupt
      Store (INTN, Local0)
      Or (Local0, 0x20, Local0)
      Store (Local0, INTN)

      // Unmask the interrupt
      Store (MASK, Local0)
      And (Local0, 0xFFFFFFDF, Local0)
      Store (Local0, MASK)
    }

    Method(_EVT, 1, Serialized) {
      Switch (ToInteger(Arg0)) {
        Case (26) {
          // Check if the Reset Button is pressed (PIN5 low)
          if (And (STAS, 0x20)) {
            // Clear the interrupt
            Store (PORT, Local0)
            Or (Local0, 0x20, Local0)
            Store (Local0, PORT)

            // Notify OSPM the Reset Button is pressed
            Notify (\_SB.RSTB, 0x80)
          }
        }
      }
    }
  }
}
