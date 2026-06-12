/** @file
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
  // DesignWare UART
  Device(URT0) {
    Name(_HID, "SOPH0002")              // _HID: Hardware ID
    Name(_UID, 0)
    Name(_DSD, Package () {
      ToUUID("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
      Package () {
        Package () { "clock-frequency", 500000000 },
        Package () { "reg-shift", 2 },
        Package () { "reg-io-width", 4 },
      }
    })
    Name (_CRS, ResourceTemplate () {   // _CRS: Current Resource Settings
      QWordMemory ( // 64-bit memory
            ResourceConsumer, PosDecode,
            MinFixed, MaxFixed,
            NonCacheable, ReadWrite,
            0x0,                       // Granularity
            0x7030001000,              // Min Base Address
            0x7030001FFF,              // Max Base Address
            0x00000000,                // Translate
            0x00001000                 // Length
          )
      Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive) { 42 }
    })
    Method (_STA) {
      Return (0xF)
    }
  }

  Device(URT1) {
    Name(_HID, "SOPH0002")
    Name(_UID, 1)
    Name(_DSD, Package () {
      ToUUID("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
      Package () {
        Package () { "clock-frequency", 500000000 },
        Package () { "reg-shift", 2 },
        Package () { "reg-io-width", 4 },
        Package () { "current-speed", 9600 },
      }
    })
    Name (_CRS, ResourceTemplate () {
      QWordMemory (
            ResourceConsumer, PosDecode,
            MinFixed, MaxFixed,
            NonCacheable, ReadWrite,
            0x0,
            0x7030003000,
            0x7030003FFF,
            0x00000000,
            0x00001000
          )
      Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive) { 44 }
    })
    Method (_STA) { Return (0xF) }
  }
}
