/** @file
 *
 *  Differentiated System Description Table Fields (DSDT)
 *
 *  Copyright (c) 2024, SOPHGO Inc. All rights reserved.
 *  Copyright (c) 2023, Academy of Intelligent Innovation, Shandong Universiy, China.P.R. All rights reserved.<BR>
 *
 *  SPDX-License-Identifier: BSD-2-Clause-Patent
 *
 **/

Scope(_SB)
{
  Device (I2C0) {
    Name(_HID, "SOPH0003")
    Name(_UID, 0)
    Method (_STA)
    {
      Return (0xF)
    }

    Name (_CRS, ResourceTemplate ()  {
      QWordMemory (
        ResourceConsumer,
        ,
        MinFixed,
        MaxFixed,
        NonCacheable,
        ReadWrite,
        0x0,
        0x7040005000,
        0x7040005FFF,
        0x0,
        0x1000
      )
      Interrupt(ResourceConsumer, Level, ActiveHigh, Exclusive,,,) { 31 }
    })
    Name(SSCN, Package() { 0x3E2, 0x47D, 0 })
    Name(FMCN, Package() { 0xA4, 0x13F, 0 })
  }

  Device (I2C1) {
    Name(_HID, "SOPH0003")
    Name(_UID, 1)
    Method (_STA)
    {
      Return (0xF)
    }

    Name (_CRS, ResourceTemplate ()  {
      QWordMemory (
        ResourceConsumer,
        ,
        MinFixed,
        MaxFixed,
        NonCacheable,
        ReadWrite,
        0x0,
        0x7040006000,
        0x7040006FFF,
        0x0,
        0x1000
      )
      Interrupt(ResourceConsumer, Level, ActiveHigh, Exclusive,,,) { 32 }
    })
    Name(SSCN, Package() { 0x3E2, 0x47D, 0 })
    Name(FMCN, Package() { 0xA4, 0x13F, 0 })
  }

  Device (I2C2) {
    Name(_HID, "SOPH0003")
    Name(_UID, 2)
    Method (_STA)
    {
      Return (0xF)
    }

    Name (_CRS, ResourceTemplate ()  {
      QWordMemory (
        ResourceConsumer,
        ,
        MinFixed,
        MaxFixed,
        NonCacheable,
        ReadWrite,
        0x0,
        0x7040007000,
        0x7040007FFF,
        0x0,
        0x1000
      )
      Interrupt(ResourceConsumer, Level, ActiveHigh, Exclusive,,,) { 33 }
    })
    Name(SSCN, Package() { 0x3E2, 0x47D, 0 })
    Name(FMCN, Package() { 0xA4, 0x13F, 0 })
  }

  Device (I2C3) {
    Name(_HID, "SOPH0003")
    Name(_UID, 3)
    Method (_STA)
    {
      Return (0xF)
    }

    Name (_CRS, ResourceTemplate ()  {
      QWordMemory (
        ResourceConsumer,
        ,
        MinFixed,
        MaxFixed,
        NonCacheable,
        ReadWrite,
        0x0,
        0x7040008000,
        0x7040008FFF,
        0x0,
        0x1000
      )
      Interrupt(ResourceConsumer, Level, ActiveHigh, Exclusive,,,) { 34 }
    })
    Name(SSCN, Package() { 0x3E2, 0x47D, 0 })
    Name(FMCN, Package() { 0xA4, 0x13F, 0 })
  }

  // SPI0
  Device (SPI0) {
    Name (_HID, "SOPH0004")
    Name (_UID, 0)
    Method (_STA)
    {
      Return (0xF)
    }

    Name (_CRS, ResourceTemplate () {
      QWordMemory (
        ResourceConsumer, PosDecode,
        MinFixed, MaxFixed,
        NonCacheable, ReadWrite,
        0x0,                       // Granularity
        0x7030004000,              // Min Base Address
        0x7030004FFF,              // Max Base Address
        0x0,                       // Translate
        0x0000001000               // Length
      )
      Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive) { 39 }
    })

    Name (_DSD, Package ()  // _DSD: Device-Specific Data
    {
      ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
      Package () {
        Package () { "num-cs", 2 },
      }
    })
  }

  Device (SPI1) {
    Name (_HID, "SOPH0004")
    Name (_UID, 1)

    Method (_STA)
    {
      Return (0xF)
    }

    Name (_CRS, ResourceTemplate () {
      QWordMemory (
        ResourceConsumer, PosDecode,
        MinFixed, MaxFixed,
        NonCacheable, ReadWrite,
        0x0,                       // Granularity
        0x7030005000,              // Min Base Address
        0x7030005FFF,              // Max Base Address
        0x0,                       // Translate
        0x0000001000               // Length
      )
      Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive) { 40 }
    })

    Name (_DSD, Package ()  // _DSD: Device-Specific Data
    {
      ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
      Package () {
        Package () { "num-cs", 2 },
      }
    })
  }

  // PWM
  Device (PWM0) {
    Name (_HID, "SOPH0007")
    Name (_UID, 0)

    Method (_STA)
    {
      Return (0xF)
    }

    Name(_DSD, Package () {
      ToUUID("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
      Package () {
        Package () {"base-clk", 100000000},
      }
    })

    Name (_CRS, ResourceTemplate () {   // _CRS: Current Resource Settings
      QWordMemory (
        ResourceConsumer, PosDecode,
        MinFixed, MaxFixed,
        NonCacheable, ReadWrite,
        0x0,                       // Granularity
        0x704000C000,              // Min Base Address
        0x704000CFFF,              // Max Base Address
        0x0,                       // Translate
        0x0000001000               // Length
      )
    })
  }

  // GPIO
  Device (GPI0) {
    Name(_HID, "SOPH0008")
    Name(_CID, "HISI0181")
    Name(_UID, 0)

    Method(_STA) {
      Return (0xF)
    }

    Name (_CRS, ResourceTemplate ()  {
      QWordMemory (
        ResourceConsumer,
        ,
        MinFixed,
        MaxFixed,
        NonCacheable,
        ReadWrite,
        0x0,
        0x7040009000,
        0x7040009FFF,
        0x0,
        0x1000
      )
      Interrupt(ResourceConsumer, Level, ActiveHigh, Exclusive,,,) { 26 }
    })

    Device (PRTA) {
      Name(_ADR, 0)
      Name(_UID, 0)
      Name(_DSD, Package () {
        ToUUID("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
        Package () {
          Package () {"bank-name", "port0a"},
          Package () {"reg", 0},
          Package () {"snps,nr-gpios", 32},
        }
      })
    }
  }

  Device (GPI1) {
    Name(_HID, "SOPH0008")
    Name(_CID, "HISI0181")
    Name(_UID, 1)

    Method(_STA) {
      Return (0xF)
    }

    Name (_CRS, ResourceTemplate ()  {
      QWordMemory (
        ResourceConsumer,
        ,
        MinFixed,
        MaxFixed,
        NonCacheable,
        ReadWrite,
        0x0,
        0x704000a000,
        0x704000aFFF,
        0x0,
        0x1000
      )
      Interrupt(ResourceConsumer, Level, ActiveHigh, Exclusive,,,) { 27 }
    })

    Device (PRTA) {
      Name(_ADR, 0)
      Name(_UID, 0)
      Name(_DSD, Package () {
        ToUUID("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
        Package () {
          Package () {"bank-name", "port0a"},
          Package () {"reg", 0},
          Package () {"snps,nr-gpios", 32},
        }
      })
    }
  }

  Device (GPI2) {
    Name(_HID, "SOPH0008")
    Name(_CID, "HISI0181")
    Name(_UID, 2)

    Method(_STA) {
      Return (0xF)
    }

    Name (_CRS, ResourceTemplate ()  {
      QWordMemory (
        ResourceConsumer,
        ,
        MinFixed,
        MaxFixed,
        NonCacheable,
        ReadWrite,
        0x0,
        0x704000b000,
        0x704000bFFF,
        0x0,
        0x1000
      )
      Interrupt(ResourceConsumer, Level, ActiveHigh, Exclusive,,,) { 28 }
    })

    Device (PRTA) {
      Name(_ADR, 0)
      Name(_UID, 0)
      Name(_DSD, Package () {
        ToUUID("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
        Package () {
          Package () {"bank-name", "port0a"},
          Package () {"reg", 0},
          Package () {"snps,nr-gpios", 32},
        }
      })
    }
  }

  Device (TPU0) {
    Name (_HID, "SOPH0009")
    Name (_UID, 0)
    Name (_CCA, 0)

    Method (_STA)
    {
      Return (0xF)
    }

    Name (_CRS, ResourceTemplate () {
      Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive) { 863 }
    })

    Name (_DSD, Package ()  // _DSD: Device-Specific Data
    {
      ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
      Package () {
        Package () { "chip_type", 0x1690 },
      }
    })
  }

  // system controller
  Device (SCTL) {
    Name(_HID, "SOPH0011")

    Name(_CRS, ResourceTemplate() {
      QWordMemory (
        ResourceConsumer,
        ,
        MinFixed,
        MaxFixed,
        NonCacheable,
        ReadWrite,
        0x0,
        0x7050000000,
        0x7050007FFF,
        0x0,
        0x8000
      )
    })
  }

  Device (PCTL) {
    Name(_HID, "SOPH0010")

    Name(_CRS, ResourceTemplate() {
	  QWordMemory (
        ResourceConsumer,
        ,
        MinFixed,
        MaxFixed,
        NonCacheable,
        ReadWrite,
        0x0,
        0x7050001000,
        0x7050007FFF,
        0x0,
        0x7000
	  )
    })

    Name (_DSD, Package () {
      ToUUID("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
      Package () {
        Package () { "subctrl-syscon", Package() { \_SB.SCTL } },
        Package () { "top_pinctl_offset", 0x1000 },
      }
    })
  }

  //
  // Report APEI Errors to GHES via SCI notification.
  // SCI notification requires one GED and one HED Device
  //     GED = Generic Event Device (ACPI0013)
  //     HED = Hardware Error Device (PNP0C33)
  //
  Device(GED2) {
    Name(_HID, "ACPI0013")
    Name(_UID, 2)
    Method(_STA) {
      Return (0xF)
    }
    Name(_CRS, ResourceTemplate () {
      Interrupt(ResourceConsumer, Level, ActiveHigh, Exclusive,,,) { 860 } // GHES
    })

    // MTLI 860 interrupt
    OperationRegion(INTR, SystemMemory, 0x6D500007F0, 4)
    Field(INTR, DWordAcc, NoLock, Preserve) {
      MTLI, 32
    }

    Method(_EVT, 1, Serialized) {
      Switch (ToInteger(Arg0)) {
        Case (860) {
          // Clear the interrupt
          Store (0, MTLI)
          Notify (HED0, 0x80)
        }
      }
    }
  }

  Device(HED0) {
    Name(_HID, EISAID("PNP0C33"))
    Name(_UID, Zero)
  }
}
