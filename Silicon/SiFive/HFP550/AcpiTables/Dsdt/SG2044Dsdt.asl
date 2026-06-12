/** @file
*  Differentiated System Description Table Fields (DSDT)
*
*  Copyright (c) 2024, SOPHGO Inc. All rights reserved.
*  Copyright (c) 2023, Academy of Intelligent Innovation, Shandong Universiy, China.P.R. All rights reserved.<BR>
*
*  SPDX-License-Identifier: BSD-2-Clause-Patent
*
**/

#include "SG2044AcpiHeader.h"

DefinitionBlock ("DsdtTable.aml", "DSDT", 2, "SOPHGO", "2044    ",
                 EFI_ACPI_RISCV_OEM_REVISION) {
  include ("Cpu.asl")
  include ("CommonDevices.asl")
  include ("Uart.asl")
  include ("Mmc.asl")
  include ("Ethernet.asl")
  include ("Intc.asl")
  include ("Pci.asl")
  include ("PowerButton.asl")
  include ("Video.asl")

  Scope (\_SB_.I2C1)
  {
    Device (FAN0) {
      Name (_HID, "PNP0C0B")
      Name (_UID, 0)
      Name (FAS0, 0)
      OperationRegion(PR0, SystemMemory, 0x704000C000, 0xd4)
      Field(PR0, DWordAcc, NoLock, Preserve) {
        HLP0, 32,
        PER0, 32,
        Offset (0x20),
        FQ0, 32,
        FQ0D, 32,
        Offset (0x40),
        POL0, 1,
        Offset (0x44),
        PWM0, 1,
        Offset (0xd0),
        OE0, 1
      }
      Method (_STA)
      {
        Return (0xF)
      }
      Method (_FIF, 0, NotSerialized)
      {
        Return (Package ()
        {
          0x00,
          0x00,
          0x1,
          0x80,
        })
      }
      Method (_FPS, 0, NotSerialized)
      {
        Return (Package ()
        {
          0x00,
          Package ()
          {
            3900,
            0x00,
            3000,
            0xFFFFFFFF,
            0xFFFFFFFF,
          },
          Package ()
          {
            3200,
            0x01,
            2400,
            0xFFFFFFFF,
            0xFFFFFFFF,
          },
          Package ()
          {
            2400,
            0x02,
            1800,
            0xFFFFFFFF,
            0xFFFFFFFF,
          },
          Package ()
          {
            1600,
            0x03,
            1200,
            0xFFFFFFFF,
            0xFFFFFFFF,
          },
          Package ()
          {
            800,
            0x04,
            600,
            0xFFFFFFFF,
            0xFFFFFFFF,
          }
        })
      }
      Method (_FSL, 1, NotSerialized)
      {
        Store (4000, PER0)
        Store (Arg0, HLP0)
        Store (1, POL0)
        Store (0, PWM0)
        Store (1, OE0)
        Store (1, PWM0)
        Store (Arg0, FAS0)
      }
      Method (_FST, 0, NotSerialized)
      {
        Return (Package ()
        {
          0,
          FAS0,
          0XFFFFFFFF
        })
      }
    }

    Device (FAN1) {
      Name (_HID, "PNP0C0B")
      Name (_UID, 1)
      Name (FAS1, 0)
      OperationRegion(PR1, SystemMemory, 0x704000C000, 0xd4)
      Field(PR1, DWordAcc, NoLock, Preserve) {
        Offset (0x8),
        HLP1, 32,
        PER1, 32,
        Offset (0x28),
        FQ1, 32,
        FQ1D, 32,
        Offset (0x40),
        POL0, 1,
        POL1, 1,
        Offset (0x44),
        PWM0, 1,
        PWM1, 1,
        Offset (0xd0),
        OE0, 1,
        OE1, 1
      }
      Method (_STA)
      {
        Return (0xF)
      }
      Method (_FIF, 0, NotSerialized)
      {
        Return (Package ()
        {
          0x00,
          0x00,
          0x1,
          0x80,
        })
      }
      Method (_FPS, 0, NotSerialized)
      {
        Return (Package ()
        {
          0x00,
          Package ()
          {
            3900,
            0x00,
            3000,
            0xFFFFFFFF,
            0xFFFFFFFF,
          },
          Package ()
          {
            3200,
            0x01,
            2400,
            0xFFFFFFFF,
            0xFFFFFFFF,
          },
          Package ()
          {
            2400,
            0x02,
            1800,
            0xFFFFFFFF,
            0xFFFFFFFF,
          },
          Package ()
          {
            1600,
            0x03,
            1200,
            0xFFFFFFFF,
            0xFFFFFFFF,
          },
          Package ()
          {
            800,
            0x04,
            600,
            0xFFFFFFFF,
            0xFFFFFFFF,
          }
        })
      }
      Method (_FSL, 1, NotSerialized)
      {
        Store (4000, PER1)
        Store (Arg0, HLP1)
        Store (1, POL1)
        Store (0, PWM1)
        Store (1, OE1)
        Store (1, PWM1)
        Store (Arg0, FAS1)
      }
      Method (_FST, 0, NotSerialized)
      {
        Return (Package ()
        {
          0,
          FAS1,
          0XFFFFFFFF
        })
      }
    }

    ThermalZone (TZ00) {
      OperationRegion(TZ0, SystemMemory, 0x7040003000, 0x4000)
      Field(TZ0, DWordAcc, NoLock, Preserve) {
        Offset (0x3000),
        CON, 32,
        TAR, 32,
        Offset (0x3010),
        DATA, 32,
        HCNT, 32,
        LCNT, 32,
        FCNH, 32,
        FCNL, 32,
        Offset (0x3030),
        MASK, 32,
        INT, 32,
        RXTL, 32,
        TXTL, 32,
        Offset (0x306c),
        EN, 1
      }
      Method (_STA)
      {
        Return (0xF)
      }
      Method (_TMP, 0, Serialized)
      {
          Store (0, EN)
          Store (0x63, CON)
          Store (0x17, TAR)
          Store (0x69, HCNT)
          Store (0x7c, LCNT)
          Store (0x14, FCNH)
          Store (0x27, FCNL)
          Store (0, MASK)
          Store (0, RXTL)
          Store (1, TXTL)
          Store (1, EN)

          Store (0x404, DATA)
          Store (0x300, DATA)

          Store (DATA, Local1)
          Local1 = (Local1 & 0xff)
          if (Local1 & 0x80) {
            Local1 = Local1 - 0x100
          }
          Return (((Local1) * 10) + 2732)
      }
      Method(_AC0) { Return ( 3432 ) }
      Method(_AC1) { Return ( 3332 ) }
      Method(_AC2) { Return ( 3232 ) }
      Method(_CRT) { Return ( 3732 ) }
      Name(_AL0, Package(){FAN0})
      Name(_AL1, Package(){FAN0})
      Name(_AL2, Package(){FAN0})
      Name(_AL3, Package(){FAN0})
      Name(_AL4, Package(){FAN0})
      Name(_TZP, 200)
      Name (_STR, Unicode ("System thermal zone0"))
    }

    ThermalZone (TZ01) {
      OperationRegion(TZ1, SystemMemory, 0x7040003000, 0x4000)
      Field(TZ1, DWordAcc, NoLock, Preserve) {
        Offset (0x3000),
        CON, 32,
        TAR, 32,
        Offset (0x3010),
        DATA, 32,
        HCNT, 32,
        LCNT, 32,
        FCNH, 32,
        FCNL, 32,
        Offset (0x3030),
        MASK, 32,
        INT, 32,
        RXTL, 32,
        TXTL, 32,
        Offset (0x306c),
        EN, 1
      }
      Method (_STA)
      {
        Return (0xF)
      }
      Method (_TMP, 0, Serialized)
      {
          Store (0, EN)
          Store (0x63, CON)
          Store (0x17, TAR)
          Store (0x69, HCNT)
          Store (0x7c, LCNT)
          Store (0x14, FCNH)
          Store (0x27, FCNL)
          Store (0, MASK)
          Store (0, RXTL)
          Store (1, TXTL)
          Store (1, EN)

          Store (0x405, DATA)
          Store (0x300, DATA)

          Store (DATA, Local1)
          Local1 = (Local1 & 0xff)
          if (Local1 & 0x80) {
            Local1 = Local1 - 0x100
          }
          Return (((Local1) * 10) + 2732)
      }
      Method(_AC0) { Return ( 3432 ) }
      Method(_AC1) { Return ( 3332 ) }
      Method(_AC2) { Return ( 3232 ) }
      Name(_AL0, Package(){FAN1})
      Name(_AL1, Package(){FAN1})
      Name(_AL2, Package(){FAN1})
      Name(_AL3, Package(){FAN1})
      Name(_AL4, Package(){FAN1})
      Name(_TZP, 200)
      Name (_STR, Unicode ("System thermal zone1"))
    }
  }
}
