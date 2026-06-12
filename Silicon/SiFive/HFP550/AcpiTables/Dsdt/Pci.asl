/** @file
*
*  Copyright (c) 2023, Academy of Intelligent Innovation, Shandong Universiy, China.P.R. All rights reserved.<BR>
*  Copyright (c) 2024, SOPHGO Inc. All rights reserved.
*
*  SPDX-License-Identifier: BSD-2-Clause-Patent
*
**/

/*
  See ACPI 6.5 Spec, 6.2.11, PCI Firmware Spec 3.0, 4.5
*/
#define LNK_DEVICE(Unique_Id, Link_Name, irq)                                  \
  Device(Link_Name) {                                                          \
      Name(_HID, EISAID("PNP0C0F"))                                            \
      Name(_UID, Unique_Id)                                                    \
      Name(_PRS, ResourceTemplate() {                                          \
          Interrupt(ResourceProducer, Level, ActiveHigh, Exclusive) { irq }    \
      })                                                                       \
      Method (_CRS, 0) { Return (_PRS) }                                       \
      Method (_SRS, 1) { }                                                     \
      Method (_DIS) { }                                                        \
  }

#define PRT_ENTRY(Address, Pin, Link)                                                             \
        Package (4) {                                                                             \
            Address,    /* uses the same format as _ADR */                                        \
            Pin,        /* The PCI pin number of the device (0-INTA, 1-INTB, 2-INTC, 3-INTD). */  \
            Link,       /* Interrupt allocated via Link device. */                                \
            Zero        /* global system interrupt number (no used) */                            \
          }

#define ROOT_PRT_ENTRY(Pin, Link)   PRT_ENTRY(0x0000FFFF, Pin, Link)
                                                    // Device 0 for Bridge.

#define PCI_OSC_SUPPORT() \
  Name(SUPP, Zero) /* PCI _OSC Support Field value */ \
  Name(CTRL, Zero) /* PCI _OSC Control Field value */ \
  Method(_OSC,4) { \
    If(LEqual(Arg0,ToUUID("33DB4D5B-1FF7-401C-9657-7441C03DD766"))) { \
      /* Create DWord-adressable fields from the Capabilities Buffer */ \
      CreateDWordField(Arg3,0,CDW1) \
      CreateDWordField(Arg3,4,CDW2) \
      CreateDWordField(Arg3,8,CDW3) \
      /* Save Capabilities DWord2 & 3 */ \
      Store(CDW2,SUPP) \
      Store(CDW3,CTRL) \
      /* Only allow native hot plug control if OS supports: */ \
      /* ASPM */ \
      /* Clock PM */ \
      /* MSI/MSI-X */ \
      If(LNotEqual(And(SUPP, 0x16), 0x16)) { \
        And(CTRL,0x1E,CTRL) \
      }\
      \
      /* Always allow native PME, AER */ \
      /* Never allow SHPC (no SHPC controller in this system)*/ \
      And(CTRL,0x1D,CTRL) \
      If(LNotEqual(Arg1,One)) { /* Unknown revision */ \
        Or(CDW1,0x08,CDW1) \
      } \
      \
      If(LNotEqual(CDW3,CTRL)) { /* Capabilities bits were masked */ \
        Or(CDW1,0x10,CDW1) \
      } \
      \
      /* Update DWORD3 in the buffer */ \
      Store(CTRL,CDW3) \
      Return(Arg3) \
    } Else { \
      Or(CDW1,4,CDW1) /* Unrecognized UUID */ \
      Return(Arg3) \
    } \
  } // End _OSC

Scope(_SB)
{

  LNK_DEVICE(1, RCA0, 64)
  LNK_DEVICE(2, RCA1, 66)
  LNK_DEVICE(3, RCA2, 65)
  LNK_DEVICE(4, RCA3, 67)
  LNK_DEVICE(5, RCA4, 73)
  LNK_DEVICE(6, RCA5, 75)
  LNK_DEVICE(7, RCA6, 74)
  LNK_DEVICE(8, RCA7, 76)
  LNK_DEVICE(9, RCA8, 125)
  LNK_DEVICE(10, RCA9, 126)

  // PCIe Root bus
  Device (PCI0)
  {
    Name (_HID, "PNP0A08") // PCI Express Root Bridge
    Name (_CID, "PNP0A03") // Compatible PCI Root Bridge
    Name (_SEG, 0)         // Segment of this Root complex
    Name (_BBN, 0)         // Base Bus Number
    Name (_CCA, 1)

    Method (_STA) {
      Return (0xF)
    }

    Name (_DEP, Package () {
      \_SB.MSI
    })

    // PCI Routing Table
    Name(_PRT, Package() {
      ROOT_PRT_ENTRY(0, RCA0),   // INTA
      ROOT_PRT_ENTRY(1, RCA0),   // INTB
      ROOT_PRT_ENTRY(2, RCA0),   // INTC
      ROOT_PRT_ENTRY(3, RCA0),   // INTD
    })

    Name (_DSD, Package () {
      ToUUID("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
      Package () {
        Package () { "interrupt-parent" , Package() { \_SB.MSI }},
      }
    })

    Name (_CRS, ResourceTemplate () { // Root complex resources
      WordBusNumber ( // Bus numbers assigned to this root
        ResourceProducer, MinFixed, MaxFixed, PosDecode,
        0x0,                // AddressGranularity
        0x0,                // AddressMinimum - Minimum Bus Number
        0xff,               // AddressMaximum - Maximum Bus Number
        0x0,                  // AddressTranslation - Set to 0
        0x100                // RangeLength - Number of Busses
      )
      QWordMemory ( // 32-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Prefetchable, ReadWrite,
        0x0,                // Granularity
        0x0000000000,       // Min Base Address
        0x0003FFFFFF,       // Max Base Address
        0x0000000000,       // Translate
        0x0004000000        // Length
      )
      QWordMemory ( // 32-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Cacheable, ReadWrite,
        0x0,                // Granularity
        0x0004000000,       // Min Base Address
        0x0007FFFFFF,       // Max Base Address
        0x0000000000,       // Translate
        0x0004000000        // Length
      )
      QWordMemory ( // 64-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Prefetchable, ReadWrite,
        0x0,                // Granularity
        0x4400000000,       // Min Base Address pci address
        0x47FFFFFFFF,       // Max Base Address
        0x0,                // Translate
        0x0400000000        // Length
      )
      QWordMemory ( // 64-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Cacheable, ReadWrite,
        0x0,                // Granularity
        0x4200000000,       // Min Base Address pci address
        0x43FFFFFFFF,       // Max Base Address
        0x0,                // Translate
        0x0200000000        // Length
      )
      QWordIO (
        ResourceProducer, MinFixed, MaxFixed,
        PosDecode, EntireRange,
        0x0000000000,       // Granularity
        0x0000000000,       // Min Base Address
        0x00001FFFFF,       // Max Base Address
        0x4010000000,       // Translate
        0x0000200000        // Length
      )
    })

    PCI_OSC_SUPPORT()

    Name (_DMA, ResourceTemplate() {
      QWordMemory (ResourceProducer,
        ,
        MinFixed,
        MaxFixed,
        Prefetchable,
        ReadWrite,
        0x0,
        0x0,          // MIN
        0x3FFFFFFFFF, // MAX
        0x0,          // TRA
        0x4000000000, // LEN
        ,
        ,
        )
    })

    Device (RES0)
    {
      Name (_HID, "SOPH0000" /* PNP Motherboard Resources */)  // _HID: Hardware ID
      Name (_UID, 0x0)  // Unique ID
      Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
      {
        QWordMemory ( // dbi
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x6C00400000,                       // Range Minimum
          0x6C00400FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000001000,                       // Length
          , , , AddressRangeMemory, TypeStatic)

        QWordMemory ( // ctrl
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x6C00780000,                       // Range Minimum
          0x6C00780FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000001000,                       // Length
          , , , AddressRangeMemory, TypeStatic)

        QWordMemory ( // atu
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x6C00700000,                       // Range Minimum
          0x6C00703FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000004000,                       // Length
          , , , AddressRangeMemory, TypeStatic)

        QWordMemory ( // config
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x4000000000,                       // Range Minimum
          0x4000000FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000001000,                       // Length
          , , , AddressRangeMemory, TypeStatic)

      })
      Method (_STA) {
        Return (0xF)
      }
    }

  } // Device(PCI0)

  // PCIe Root bus
  Device (PCI1)
  {
    Name (_HID, "PNP0A08") // PCI Express Root Bridge
    Name (_CID, "PNP0A03") // Compatible PCI Root Bridge
    Name (_SEG, 1)         // Segment of this Root complex
    Name (_BBN, 0x0)      // Base Bus Number
    Name (_CCA, 1)

    Method (_STA) {
      Return (0xF)
    }

    Name (_DEP, Package () {
      \_SB.MSI
    })


    // PCI Routing Table
    Name(_PRT, Package() {
      ROOT_PRT_ENTRY(0, RCA1),   // INTA
      ROOT_PRT_ENTRY(1, RCA1),   // INTB
      ROOT_PRT_ENTRY(2, RCA1),   // INTC
      ROOT_PRT_ENTRY(3, RCA1),   // INTD
    })

    Name (_DSD, Package () {
      ToUUID("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
      Package () {
        Package () { "interrupt-parent" , Package() { \_SB.MSI }},
      }
    })

    Name (_CRS, ResourceTemplate () { // Root complex resources
      WordBusNumber ( // Bus numbers assigned to this root
        ResourceProducer, MinFixed, MaxFixed, PosDecode,
        0x0,                    // AddressGranularity
        0x00,                   // AddressMinimum - Minimum Bus Number
        0xFF,                   // AddressMaximum - Maximum Bus Number
        0,                      // AddressTranslation - Set to 0
        0x100                    // RangeLength - Number of Busses
      )
      QWordMemory ( // 32-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Prefetchable, ReadWrite,
        0x0,                 // Granularity
        0x0008000000,        // Min Base Address
        0x000BFFFFFF,        // Max Base Address
        0x0000000000,        // Translate
        0x0004000000         // Length
      )
      QWordMemory ( // 32-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Cacheable, ReadWrite,
        0x0,                 // Granularity
        0x000C000000,        // Min Base Address
        0x000FFFFFFF,        // Max Base Address
        0x0000000000,        // Translate
        0x0004000000         // Length
      )
      QWordMemory ( // 64-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Prefetchable, ReadWrite,
        0x0,               // Granularity
        0x4C00000000,      // Min Base Address pci address
        0x4FFFFFFFFF,      // Max Base Address
        0x0000000000,      // Translate
        0x0400000000       // Length
      )
      QWordMemory ( // 64-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Cacheable, ReadWrite,
        0x0,               // Granularity
        0x4A00000000,      // Min Base Address pci address
        0x4BFFFFFFFF,      // Max Base Address
        0x0000000000,      // Translate
        0x0200000000       // Length
      )
      QWordIO (
        ResourceProducer, MinFixed, MaxFixed,
        PosDecode, EntireRange,
        0x0,               // Granularity
        0x0000000000,      // Min Base Address
        0x00001FFFFF,      // Max Base Address
        0x4810000000,      // Translate
        0x0000200000       // Length
      )
    })

    PCI_OSC_SUPPORT()

    Name (_DMA, ResourceTemplate() {
      QWordMemory (ResourceProducer,
        ,
        MinFixed,
        MaxFixed,
        Prefetchable,
        ReadWrite,
        0x0,
        0x0,          // MIN
        0x3FFFFFFFFF, // MAX
        0x0,          // TRA
        0x4000000000, // LEN
        ,
        ,
        )
    })

    Device (RES1)
    {
      Name (_HID, "SOPH0000" /* PNP Motherboard Resources */)  // _HID: Hardware ID
      Name (_UID, 0x1)  // Unique ID
      Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
      {
        QWordMemory ( // dbi
          ResourceProducer, PosDecode, 
          MinFixed, MaxFixed, 
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x6C00800000,                       // Range Minimum
          0x6C00800FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000001000,                       // Length
          , , , AddressRangeMemory, TypeStatic)

        QWordMemory ( // ctrl
          ResourceProducer, PosDecode, 
          MinFixed, MaxFixed, 
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x6C00B80000,                       // Range Minimum
          0x6C00B80FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000001000,                       // Length
          , , , AddressRangeMemory, TypeStatic)

        QWordMemory ( // atu
          ResourceProducer, PosDecode, 
          MinFixed, MaxFixed, 
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x6C00B00000,                       // Range Minimum
          0x6C00B03FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000004000,                       // Length
          , , , AddressRangeMemory, TypeStatic)

        QWordMemory ( // config
          ResourceProducer, PosDecode, 
          MinFixed, MaxFixed, 
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x4800000000,                       // Range Minimum
          0x4800000FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000001000,                       // Length
          , , , AddressRangeMemory, TypeStatic)
      })
      Method (_STA) {
        Return (0xF)
      }
    }

  } // Device(PCI1)

  // PCIe Root bus
  Device (PCI2)
  {
    Name (_HID, "PNP0A08") // PCI Express Root Bridge
    Name (_CID, "PNP0A03") // Compatible PCI Root Bridge
    Name (_SEG, 2)         // Segment of this Root complex
    Name (_BBN, 0x0)      // Base Bus Number
    Name (_CCA, 1)

    Method (_STA) {
      Return (0xF)
    }

    Name (_DEP, Package () {
      \_SB.MSI
    })

    // PCI Routing Table
    Name(_PRT, Package() {
      ROOT_PRT_ENTRY(0, RCA2),   // INTA
      ROOT_PRT_ENTRY(1, RCA2),   // INTB
      ROOT_PRT_ENTRY(2, RCA2),   // INTC
      ROOT_PRT_ENTRY(3, RCA2),   // INTD
    })

    Name (_DSD, Package () {
      ToUUID("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
      Package () {
        Package () { "interrupt-parent" , Package() { \_SB.MSI }},
      }
    })

    Name (_CRS, ResourceTemplate () { // Root complex resources
      WordBusNumber ( // Bus numbers assigned to this root
        ResourceProducer, MinFixed, MaxFixed, PosDecode,
        0,                   // AddressGranularity
        0x00,                // AddressMinimum - Minimum Bus Number
        0xFF,                // AddressMaximum - Maximum Bus Number
        0,                   // AddressTranslation - Set to 0
        0x100                 // RangeLength - Number of Busses
      )
      QWordMemory ( // 32-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Prefetchable, ReadWrite,
        0x0000000000,        // Granularity
        0x0010000000,        // Min Base Address
        0x0013FFFFFF,        // Max Base Address
        0x0000000000,        // Translate
        0x0004000000         // Length
      )
      QWordMemory ( // 32-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Cacheable, ReadWrite,
        0x0000000000,        // Granularity
        0x0014000000,        // Min Base Address
        0x0017FFFFFF,        // Max Base Address
        0x0000000000,        // Translate
        0x0004000000         // Length
      )
      QWordMemory ( // 64-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Prefetchable, ReadWrite,
        0x0000000000,       // Granularity
        0x5400000000,       // Min Base Address pci address
        0x57FFFFFFFF,       // Max Base Address
        0x0000000000,       // Translate
        0x0400000000        // Length
      )
      QWordMemory ( // 64-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Cacheable, ReadWrite,
        0x0000000000,       // Granularity
        0x5200000000,       // Min Base Address pci address
        0x53FFFFFFFF,       // Max Base Address
        0x0000000000,       // Translate
        0x0200000000        // Length
      )
      QWordIO (
        ResourceProducer, MinFixed, MaxFixed,
        PosDecode, EntireRange,
        0x0,               // Granularity
        0x0000000000,      // Min Base Address
        0x00001FFFFF,      // Max Base Address
        0x5010000000,      // Translate
        0x0000200000       // Length
      )
    })

    PCI_OSC_SUPPORT()

    Name (_DMA, ResourceTemplate() {
      QWordMemory (ResourceProducer,
        ,
        MinFixed,
        MaxFixed,
        Prefetchable,
        ReadWrite,
        0x0,
        0x0,          // MIN
        0x3FFFFFFFFF, // MAX
        0x0,          // TRA
        0x4000000000, // LEN
        ,
        ,
        )
    })

    Device (RES2)
    {
      Name (_HID, "SOPH0000" /* PNP Motherboard Resources */)  // _HID: Hardware ID
      Name (_UID, 0x2)  // Unique ID
      Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
      {
        QWordMemory ( // dbi
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x6C00000000,                       // Range Minimum
          0x6C00000FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000001000,                       // Length
          , , , AddressRangeMemory, TypeStatic)

        QWordMemory ( // ctrl
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x6C000C0000,                       // Range Minimum
          0x6C000C0FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000001000,                       // Length
          , , , AddressRangeMemory, TypeStatic)

        QWordMemory ( // atu
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x6C00300000,                       // Range Minimum
          0x6C00303FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000004000,                       // Length
          , , , AddressRangeMemory, TypeStatic)

        QWordMemory ( // config
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x5000000000,                       // Range Minimum
          0x5000000FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000001000,                       // Length
          , , , AddressRangeMemory, TypeStatic)
      })
      Method (_STA) {
        Return (0xF)
      }
    }

  } // Device(PCI2)

  // PCIe Root bus
  Device (PCI3)
  {
    Name (_HID, "PNP0A08") // PCI Express Root Bridge
    Name (_CID, "PNP0A03") // Compatible PCI Root Bridge
    Name (_SEG, 3)         // Segment of this Root complex
    Name (_BBN, 0x0)      // Base Bus Number
    Name (_CCA, 1)

    Method (_STA) {
      Return (0xF)
    }

    Name (_DEP, Package () {
      \_SB.MSI
    })

    // PCI Routing Table
    Name(_PRT, Package() {
      ROOT_PRT_ENTRY(0, RCA3),   // INTA
      ROOT_PRT_ENTRY(1, RCA3),   // INTB
      ROOT_PRT_ENTRY(2, RCA3),   // INTC
      ROOT_PRT_ENTRY(3, RCA3),   // INTD
    })

    Name (_DSD, Package () {
      ToUUID("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
      Package () {
        Package () { "interrupt-parent" , Package() { \_SB.MSI }},
      }
    })

    Name (_CRS, ResourceTemplate () { // Root complex resources
      WordBusNumber ( // Bus numbers assigned to this root
        ResourceProducer, MinFixed, MaxFixed, PosDecode,
        0,                   // AddressGranularity
        0x00,                // AddressMinimum - Minimum Bus Number
        0xFF,                // AddressMaximum - Maximum Bus Number
        0,                   // AddressTranslation - Set to 0
        0x100                 // RangeLength - Number of Busses
      )
      QWordMemory ( // 32-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Prefetchable, ReadWrite,
        0x0000000000,        // Granularity
        0x0018000000,        // Min Base Address
        0x001BFFFFFF,        // Max Base Address
        0x0000000000,        // Translate
        0x0004000000         // Length
      )
      QWordMemory ( // 32-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Cacheable, ReadWrite,
        0x0000000000,        // Granularity
        0x001C000000,        // Min Base Address
        0x001FFFFFFF,        // Max Base Address
        0x0000000000,        // Translate
        0x0004000000         // Length
      )
      QWordMemory ( // 64-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Prefetchable, ReadWrite,
        0x0000000000,       // Granularity
        0x5C00000000,       // Min Base Address pci address
        0x5FFFFFFFFF,       // Max Base Address
        0x0000000000,       // Translate
        0x0400000000        // Length
      )
      QWordMemory ( // 64-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Cacheable, ReadWrite,
        0x0000000000,       // Granularity
        0x5A00000000,       // Min Base Address pci address
        0x5BFFFFFFFF,       // Max Base Address
        0x0000000000,       // Translate
        0x0200000000        // Length
      )
      QWordIO (
        ResourceProducer, MinFixed, MaxFixed,
        PosDecode, EntireRange,
        0x0,               // Granularity
        0x0000000000,      // Min Base Address
        0x00001FFFFF,      // Max Base Address
        0x5810000000,      // Translate
        0x0000200000       // Length
      )
    })

    PCI_OSC_SUPPORT()

    Name (_DMA, ResourceTemplate() {
      QWordMemory (ResourceProducer,
        ,
        MinFixed,
        MaxFixed,
        Prefetchable,
        ReadWrite,
        0x0,
        0x0,          // MIN
        0x3FFFFFFFFF, // MAX
        0x0,          // TRA
        0x4000000000, // LEN
        ,
        ,
        )
    })

    Device (RES3)
    {
      Name (_HID, "SOPH0000" /* PNP Motherboard Resources */)  // _HID: Hardware ID
      Name (_UID, 0x3)  // Unique ID
      Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
      {
        QWordMemory ( // dbi
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x6C00C00000,                       // Range Minimum
          0x6C00C00FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000001000,                       // Length
          , , , AddressRangeMemory, TypeStatic)

        QWordMemory ( // ctrl
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x6C00F80000,                       // Range Minimum
          0x6C00F80FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000001000,                       // Length
          , , , AddressRangeMemory, TypeStatic)

        QWordMemory ( //atu
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x6C00F00000,                       // Range Minimum
          0x6C00F03FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000004000,                       // Length
          , , , AddressRangeMemory, TypeStatic)

        QWordMemory ( // config
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x5800000000,                       // Range Minimum
          0x5800000FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000001000,                       // Length
          , , , AddressRangeMemory, TypeStatic)
      })
      Method (_STA) {
        Return (0xF)
      }
    }

  } // Device(PCI3)

  // PCIe Root bus
  Device (PCI4)
  {
    Name (_HID, "PNP0A08") // PCI Express Root Bridge
    Name (_CID, "PNP0A03") // Compatible PCI Root Bridge
    Name (_SEG, 0x4)         // Segment of this Root complex
    Name (_BBN, 0x0)      // Base Bus Number
    Name (_CCA, 1)

    Method (_STA) {
      Return (0xF)
    }

    Name (_DEP, Package () {
      \_SB.MSI
    })

    // PCI Routing Table
    Name(_PRT, Package() {
      ROOT_PRT_ENTRY(0, RCA4),   // INTA
      ROOT_PRT_ENTRY(1, RCA4),   // INTB
      ROOT_PRT_ENTRY(2, RCA4),   // INTC
      ROOT_PRT_ENTRY(3, RCA4),   // INTD
    })

    Name (_DSD, Package () {
      ToUUID("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
      Package () {
        Package () { "interrupt-parent" , Package() { \_SB.MSI }},
      }
    })

    Name (_CRS, ResourceTemplate () { // Root complex resources
      WordBusNumber ( // Bus numbers assigned to this root
        ResourceProducer, MinFixed, MaxFixed, PosDecode,
        0,                   // AddressGranularity
        0x00,                // AddressMinimum - Minimum Bus Number
        0xFF,                // AddressMaximum - Maximum Bus Number
        0,                   // AddressTranslation - Set to 0
        0x100                 // RangeLength - Number of Busses
      )
      QWordMemory ( // 32-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Prefetchable, ReadWrite,
        0x0000000000,        // Granularity
        0x0020000000,        // Min Base Address
        0x0023FFFFFF,        // Max Base Address
        0x0000000000,        // Translate
        0x0004000000         // Length
      )
      QWordMemory ( // 32-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Cacheable, ReadWrite,
        0x0000000000,        // Granularity
        0x0024000000,        // Min Base Address
        0x0027FFFFFF,        // Max Base Address
        0x0000000000,        // Translate
        0x0004000000         // Length
      )
      QWordMemory ( // 64-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Prefetchable, ReadWrite,
        0x0000000000,       // Granularity
        0x7900000000,       // Min Base Address pci address
        0x79FFFFFFFF,       // Max Base Address
        0x0000000000,       // Translate
        0x0100000000        // Length
      )
      QWordMemory ( // 64-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Cacheable, ReadWrite,
        0x0000000000,       // Granularity
        0x7880000000,       // Min Base Address pci address
        0x78FFFFFFFF,       // Max Base Address
        0x0000000000,       // Translate
        0x0080000000        // Length
      )
      QWordIO (
        ResourceProducer, MinFixed, MaxFixed,
        PosDecode, EntireRange,
        0x0,               // Granularity
        0x0000000000,      // Min Base Address
        0x00001FFFFF,      // Max Base Address
        0x7810000000,      // Translate
        0x0000200000       // Length
      )
    })

    PCI_OSC_SUPPORT()

    Name (_DMA, ResourceTemplate() {
      QWordMemory (ResourceProducer,
        ,
        MinFixed,
        MaxFixed,
        Prefetchable,
        ReadWrite,
        0x0,
        0x0,          // MIN
        0x3FFFFFFFFF, // MAX
        0x0,          // TRA
        0x4000000000, // LEN
        ,
        ,
        )
    })

    Device (RES4)
    {
      Name (_HID, "SOPH0000" /* PNP Motherboard Resources */)  // _HID: Hardware ID
      Name (_UID, 0x4)  // Unique ID
      Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
      {
        QWordMemory ( // dbi
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x6C04400000,                       // Range Minimum
          0x6C04400FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000001000,                       // Length
          , , , AddressRangeMemory, TypeStatic)

        QWordMemory ( // ctrl
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x6C04780000,                       // Range Minimum
          0x6C04780FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000001000,                       // Length
          , , , AddressRangeMemory, TypeStatic)

        QWordMemory ( // atu
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x6C04700000,                       // Range Minimum
          0x6C04703FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000004000,                       // Length
          , , , AddressRangeMemory, TypeStatic)

        QWordMemory (
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x7800000000,                       // Range Minimum
          0x7800000FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000001000,                       // Length
          , , , AddressRangeMemory, TypeStatic)
      })
      Method (_STA) {
        Return (0xF)
      }
    }

  } // Device(PCI4)

  // PCIe Root bus
  Device (PCI5)
  {
    Name (_HID, "PNP0A08") // PCI Express Root Bridge
    Name (_CID, "PNP0A03") // Compatible PCI Root Bridge
    Name (_SEG, 0x5)         // Segment of this Root complex
    Name (_BBN, 0x0)      // Base Bus Number
    Name (_CCA, 1)

    Method (_STA) {
      Return (0xF)
    }

    Name (_DEP, Package () {
      \_SB.MSI
    })

    // PCI Routing Table
    Name(_PRT, Package() {
      ROOT_PRT_ENTRY(0, RCA5),   // INTA
      ROOT_PRT_ENTRY(1, RCA5),   // INTB
      ROOT_PRT_ENTRY(2, RCA5),   // INTC
      ROOT_PRT_ENTRY(3, RCA5),   // INTD
    })

    Name (_DSD, Package () {
      ToUUID("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
      Package () {
        Package () { "interrupt-parent" , Package() { \_SB.MSI }},
      }
    })

    Name (_CRS, ResourceTemplate () { // Root complex resources
      WordBusNumber ( // Bus numbers assigned to this root
        ResourceProducer, MinFixed, MaxFixed, PosDecode,
        0,                   // AddressGranularity
        0x00,                // AddressMinimum - Minimum Bus Number
        0xFF,                // AddressMaximum - Maximum Bus Number
        0,                   // AddressTranslation - Set to 0
        0x100                 // RangeLength - Number of Busses
      )
      QWordMemory ( // 32-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Prefetchable, ReadWrite,
        0x0000000000,        // Granularity
        0x0028000000,        // Min Base Address
        0x002BFFFFFF,        // Max Base Address
        0x0000000000,        // Translate
        0x0004000000         // Length
      )
      QWordMemory ( // 32-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Cacheable, ReadWrite,
        0x0000000000,        // Granularity
        0x002C000000,        // Min Base Address
        0x002FFFFFFF,        // Max Base Address
        0x0000000000,        // Translate
        0x0004000000         // Length
      )
      QWordMemory ( // 64-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Prefetchable, ReadWrite,
        0x0000000000,       // Granularity
        0x7B00000000,       // Min Base Address pci address
        0x7BFFFFFFFF,       // Max Base Address
        0x0000000000,       // Translate
        0x0100000000        // Length
      )
      QWordMemory ( // 64-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Cacheable, ReadWrite,
        0x0000000000,       // Granularity
        0x7A80000000,       // Min Base Address pci address
        0x7AFFFFFFFF,       // Max Base Address
        0x0000000000,       // Translate
        0x0080000000        // Length
      )
      QWordIO (
        ResourceProducer, MinFixed, MaxFixed,
        PosDecode, EntireRange,
        0x0,               // Granularity
        0x0000000000,      // Min Base Address
        0x00001FFFFF,      // Max Base Address
        0x7A10000000,      // Translate
        0x0000200000       // Length
      )
    })

    PCI_OSC_SUPPORT()

    Name (_DMA, ResourceTemplate() {
      QWordMemory (ResourceProducer,
        ,
        MinFixed,
        MaxFixed,
        Prefetchable,
        ReadWrite,
        0x0,
        0x0,          // MIN
        0x3FFFFFFFFF, // MAX
        0x0,          // TRA
        0x4000000000, // LEN
        ,
        ,
        )
    })

    Device (RES4)
    {
      Name (_HID, "SOPH0000" /* PNP Motherboard Resources */)  // _HID: Hardware ID
      Name (_UID, 0x5)  // Unique ID
      Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
      {
        QWordMemory ( // dbi
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x6C04800000,                       // Range Minimum
          0x6C04800FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000001000,                       // Length
          , , , AddressRangeMemory, TypeStatic)

        QWordMemory ( // ctrl
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x6C04B80000,                       // Range Minimum
          0x6C04B80FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000001000,                       // Length
          , , , AddressRangeMemory, TypeStatic)

        QWordMemory ( // atu
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x6C04B00000,                       // Range Minimum
          0x6C04B03FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000004000,                       // Length
          , , , AddressRangeMemory, TypeStatic)

        QWordMemory (
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x7A00000000,                       // Range Minimum
          0x7A00000FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000001000,                       // Length
          , , , AddressRangeMemory, TypeStatic)
      })
      Method (_STA) {
        Return (0xF)
      }
    }

  } // Device(PCI5)

  // PCIe Root bus
  Device (PCI6)
  {
    Name (_HID, "PNP0A08") // PCI Express Root Bridge
    Name (_CID, "PNP0A03") // Compatible PCI Root Bridge
    Name (_SEG, 0x6)         // Segment of this Root complex
    Name (_BBN, 0x0)      // Base Bus Number
    Name (_CCA, 1)

    Method (_STA) {
      Return (0xF)
    }

    Name (_DEP, Package () {
      \_SB.MSI
    })

    // PCI Routing Table
    Name(_PRT, Package() {
      ROOT_PRT_ENTRY(0, RCA6),   // INTA
      ROOT_PRT_ENTRY(1, RCA6),   // INTB
      ROOT_PRT_ENTRY(2, RCA6),   // INTC
      ROOT_PRT_ENTRY(3, RCA6),   // INTD
    })

    Name (_DSD, Package () {
      ToUUID("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
      Package () {
        Package () { "interrupt-parent" , Package() { \_SB.MSI }},
      }
    })

    Name (_CRS, ResourceTemplate () { // Root complex resources
      WordBusNumber ( // Bus numbers assigned to this root
        ResourceProducer, MinFixed, MaxFixed, PosDecode,
        0,                   // AddressGranularity
        0x00,                // AddressMinimum - Minimum Bus Number
        0xFF,                // AddressMaximum - Maximum Bus Number
        0,                   // AddressTranslation - Set to 0
        0x100                 // RangeLength - Number of Busses
      )
      QWordMemory ( // 32-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Prefetchable, ReadWrite,
        0x0000000000,        // Granularity
        0x0030000000,        // Min Base Address
        0x0033FFFFFF,        // Max Base Address
        0x0000000000,        // Translate
        0x0004000000         // Length
      )
      QWordMemory ( // 32-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Cacheable, ReadWrite,
        0x0000000000,        // Granularity
        0x0034000000,        // Min Base Address
        0x0037FFFFFF,        // Max Base Address
        0x0000000000,        // Translate
        0x0004000000         // Length
      )
      QWordMemory ( // 64-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Prefetchable, ReadWrite,
        0x0000000000,       // Granularity
        0x7D00000000,       // Min Base Address pci address
        0x7DFFFFFFFF,       // Max Base Address
        0x0000000000,       // Translate
        0x0100000000        // Length
      )
      QWordMemory ( // 64-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Cacheable, ReadWrite,
        0x0000000000,       // Granularity
        0x7C80000000,       // Min Base Address pci address
        0x7CFFFFFFFF,       // Max Base Address
        0x0000000000,       // Translate
        0x0080000000        // Length
      )
      QWordIO (
        ResourceProducer, MinFixed, MaxFixed,
        PosDecode, EntireRange,
        0x0,               // Granularity
        0x0000000000,      // Min Base Address
        0x00001FFFFF,      // Max Base Address
        0x7C10000000,      // Translate
        0x0000200000       // Length
      )
    })

    PCI_OSC_SUPPORT()

    Name (_DMA, ResourceTemplate() {
      QWordMemory (ResourceProducer,
        ,
        MinFixed,
        MaxFixed,
        Prefetchable,
        ReadWrite,
        0x0,
        0x0,          // MIN
        0x3FFFFFFFFF, // MAX
        0x0,          // TRA
        0x4000000000, // LEN
        ,
        ,
        )
    })

    Device (RES4)
    {
      Name (_HID, "SOPH0000" /* PNP Motherboard Resources */)  // _HID: Hardware ID
      Name (_UID, 0x6)  // Unique ID
      Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
      {
        QWordMemory ( // dbi
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x6C04000000,                       // Range Minimum
          0x6C04000FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000001000,                       // Length
          , , , AddressRangeMemory, TypeStatic)

        QWordMemory ( // ctrl
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x6C040C0000,                       // Range Minimum
          0x6C040C0FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000001000,                       // Length
          , , , AddressRangeMemory, TypeStatic)

        QWordMemory ( // atu
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x6C04300000,                       // Range Minimum
          0x6C04303FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000004000,                       // Length
          , , , AddressRangeMemory, TypeStatic)

        QWordMemory (
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x7C00000000,                       // Range Minimum
          0x7C00000FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000001000,                       // Length
          , , , AddressRangeMemory, TypeStatic)
      })
      Method (_STA) {
        Return (0xF)
      }
    }

  } // Device(PCI6)

  // PCIe Root bus
  Device (PCI7)
  {
    Name (_HID, "PNP0A08") // PCI Express Root Bridge
    Name (_CID, "PNP0A03") // Compatible PCI Root Bridge
    Name (_SEG, 0x7)         // Segment of this Root complex
    Name (_BBN, 0x0)      // Base Bus Number
    Name (_CCA, 1)

    Method (_STA) {
      Return (0xF)
    }

    Name (_DEP, Package () {
      \_SB.MSI
    })

    // PCI Routing Table
    Name(_PRT, Package() {
      ROOT_PRT_ENTRY(0, RCA7),   // INTA
      ROOT_PRT_ENTRY(1, RCA7),   // INTB
      ROOT_PRT_ENTRY(2, RCA7),   // INTC
      ROOT_PRT_ENTRY(3, RCA7),   // INTD
    })

    Name (_DSD, Package () {
      ToUUID("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
      Package () {
        Package () { "interrupt-parent" , Package() { \_SB.MSI }},
      }
    })

    Name (_CRS, ResourceTemplate () { // Root complex resources
      WordBusNumber ( // Bus numbers assigned to this root
        ResourceProducer, MinFixed, MaxFixed, PosDecode,
        0,                   // AddressGranularity
        0x00,                // AddressMinimum - Minimum Bus Number
        0xFF,                // AddressMaximum - Maximum Bus Number
        0,                   // AddressTranslation - Set to 0
        0x100                 // RangeLength - Number of Busses
      )
      QWordMemory ( // 32-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Prefetchable, ReadWrite,
        0x0000000000,        // Granularity
        0x0038000000,        // Min Base Address
        0x003BFFFFFF,        // Max Base Address
        0x0000000000,        // Translate
        0x0004000000         // Length
      )
      QWordMemory ( // 32-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Cacheable, ReadWrite,
        0x0000000000,        // Granularity
        0x003C000000,        // Min Base Address
        0x003FFFFFFF,        // Max Base Address
        0x0000000000,        // Translate
        0x0004000000         // Length
      )
      QWordMemory ( // 64-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Prefetchable, ReadWrite,
        0x0000000000,       // Granularity
        0x7F00000000,       // Min Base Address pci address
        0x7FFFFFFFFF,       // Max Base Address
        0x0000000000,       // Translate
        0x0100000000        // Length
      )
      QWordMemory ( // 64-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Cacheable, ReadWrite,
        0x0000000000,       // Granularity
        0x7E80000000,       // Min Base Address pci address
        0x7EFFFFFFFF,       // Max Base Address
        0x0000000000,       // Translate
        0x0080000000        // Length
      )
      QWordIO (
        ResourceProducer, MinFixed, MaxFixed,
        PosDecode, EntireRange,
        0x0,               // Granularity
        0x0000000000,      // Min Base Address
        0x00001FFFFF,      // Max Base Address
        0x7E10000000,      // Translate
        0x0000200000       // Length
      )
    })

    PCI_OSC_SUPPORT()

    Name (_DMA, ResourceTemplate() {
      QWordMemory (ResourceProducer,
        ,
        MinFixed,
        MaxFixed,
        Prefetchable,
        ReadWrite,
        0x0,
        0x0,          // MIN
        0x3FFFFFFFFF, // MAX
        0x0,          // TRA
        0x4000000000, // LEN
        ,
        ,
        )
    })

    Device (RES4)
    {
      Name (_HID, "SOPH0000" /* PNP Motherboard Resources */)  // _HID: Hardware ID
      Name (_UID, 0x7)  // Unique ID
      Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
      {
        QWordMemory ( // dbi
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x6C04C00000,                       // Range Minimum
          0x6C04C00FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000001000,                       // Length
          , , , AddressRangeMemory, TypeStatic)

        QWordMemory ( // ctrl
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x6C04F80000,                       // Range Minimum
          0x6C04F80FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000001000,                       // Length
          , , , AddressRangeMemory, TypeStatic)

        QWordMemory ( // atu
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x6C04F00000,                       // Range Minimum
          0x6C04F03FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000004000,                       // Length
          , , , AddressRangeMemory, TypeStatic)

        QWordMemory (
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x7E00000000,                       // Range Minimum
          0x7E00000FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000001000,                       // Length
          , , , AddressRangeMemory, TypeStatic)
      })
      Method (_STA) {
        Return (0xF)
      }
    }

  } // Device(PCI7)

  // PCIe Root bus
  Device (PCI8)
  {
    Name (_HID, "PNP0A08") // PCI Express Root Bridge
    Name (_CID, "PNP0A03") // Compatible PCI Root Bridge
    Name (_SEG, 0x8)         // Segment of this Root complex
    Name (_BBN, 0x0)      // Base Bus Number
    Name (_CCA, 1)

    Method (_STA) {
      Return (0xF)
    }

    Name (_DEP, Package () {
      \_SB.MSI
    })

    // PCI Routing Table
    Name(_PRT, Package() {
      ROOT_PRT_ENTRY(0, RCA8),   // INTA
      ROOT_PRT_ENTRY(1, RCA8),   // INTB
      ROOT_PRT_ENTRY(2, RCA8),   // INTC
      ROOT_PRT_ENTRY(3, RCA8),   // INTD
    })

    Name (_DSD, Package () {
      ToUUID("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
      Package () {
        Package () { "interrupt-parent" , Package() { \_SB.MSI }},
      }
    })

    Name (_CRS, ResourceTemplate () { // Root complex resources
      WordBusNumber ( // Bus numbers assigned to this root
        ResourceProducer, MinFixed, MaxFixed, PosDecode,
        0,                   // AddressGranularity
        0x00,                // AddressMinimum - Minimum Bus Number
        0xFF,                // AddressMaximum - Maximum Bus Number
        0,                   // AddressTranslation - Set to 0
        0x100                 // RangeLength - Number of Busses
      )
      QWordMemory ( // 32-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Prefetchable, ReadWrite,
        0x0000000000,        // Granularity
        0x0040000000,        // Min Base Address
        0x0043FFFFFF,        // Max Base Address
        0x0000000000,        // Translate
        0x0004000000         // Length
      )
      QWordMemory ( // 32-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Cacheable, ReadWrite,
        0x0000000000,        // Granularity
        0x0044000000,        // Min Base Address
        0x0047FFFFFF,        // Max Base Address
        0x0000000000,        // Translate
        0x0004000000         // Length
      )
      QWordMemory ( // 64-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Prefetchable, ReadWrite,
        0x0000000000,       // Granularity
        0x6200000000,       // Min Base Address pci address
        0x63FFFFFFFF,       // Max Base Address
        0x0000000000,       // Translate
        0x0200000000        // Length
      )
      QWordMemory ( // 64-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Cacheable, ReadWrite,
        0x0000000000,       // Granularity
        0x6100000000,       // Min Base Address pci address
        0x61FFFFFFFF,       // Max Base Address
        0x0000000000,       // Translate
        0x0100000000        // Length
      )
      QWordIO (
        ResourceProducer, MinFixed, MaxFixed,
        PosDecode, EntireRange,
        0x0,               // Granularity
        0x0000000000,      // Min Base Address
        0x00001FFFFF,      // Max Base Address
        0x6010000000,      // Translate
        0x0000200000       // Length
      )
    })

    PCI_OSC_SUPPORT()

    Name (_DMA, ResourceTemplate() {
      QWordMemory (ResourceProducer,
        ,
        MinFixed,
        MaxFixed,
        Prefetchable,
        ReadWrite,
        0x0,
        0x0,          // MIN
        0x3FFFFFFFFF, // MAX
        0x0,          // TRA
        0x4000000000, // LEN
        ,
        ,
        )
    })

    Device (RES4)
    {
      Name (_HID, "SOPH0000" /* PNP Motherboard Resources */)  // _HID: Hardware ID
      Name (_UID, 0x8)  // Unique ID
      Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
      {
        QWordMemory ( // dbi
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x6C08400000,                       // Range Minimum
          0x6C08400FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000001000,                       // Length
          , , , AddressRangeMemory, TypeStatic)

        QWordMemory ( // ctrl
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x6C08780000,                       // Range Minimum
          0x6C08780FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000001000,                       // Length
          , , , AddressRangeMemory, TypeStatic)

        QWordMemory ( // atu
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x6C08700000,                       // Range Minimum
          0x6C08703FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000004000,                       // Length
          , , , AddressRangeMemory, TypeStatic)

        QWordMemory (
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x6000000000,                       // Range Minimum
          0x6000000FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000001000,                       // Length
          , , , AddressRangeMemory, TypeStatic)
      })
      Method (_STA) {
        Return (0xF)
      }
    }

  } // Device(PCI8)

  // PCIe Root bus
  Device (PCI9)
  {
    Name (_HID, "PNP0A08") // PCI Express Root Bridge
    Name (_CID, "PNP0A03") // Compatible PCI Root Bridge
    Name (_SEG, 0x9)         // Segment of this Root complex
    Name (_BBN, 0x0)      // Base Bus Number
    Name (_CCA, 1)

    Method (_STA) {
      Return (0xF)
    }

    Name (_DEP, Package () {
      \_SB.MSI
    })

    // PCI Routing Table
    Name(_PRT, Package() {
      ROOT_PRT_ENTRY(0, RCA9),   // INTA
      ROOT_PRT_ENTRY(1, RCA9),   // INTB
      ROOT_PRT_ENTRY(2, RCA9),   // INTC
      ROOT_PRT_ENTRY(3, RCA9),   // INTD
    })

    Name (_DSD, Package () {
      ToUUID("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
      Package () {
        Package () { "interrupt-parent" , Package() { \_SB.MSI }},
      }
    })

    Name (_CRS, ResourceTemplate () { // Root complex resources
      WordBusNumber ( // Bus numbers assigned to this root
        ResourceProducer, MinFixed, MaxFixed, PosDecode,
        0,                   // AddressGranularity
        0x00,                // AddressMinimum - Minimum Bus Number
        0xFF,                // AddressMaximum - Maximum Bus Number
        0,                   // AddressTranslation - Set to 0
        0x100                 // RangeLength - Number of Busses
      )
      QWordMemory ( // 32-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Prefetchable, ReadWrite,
        0x0000000000,        // Granularity
        0x0048000000,        // Min Base Address
        0x004BFFFFFF,        // Max Base Address
        0x0000000000,        // Translate
        0x0004000000         // Length
      )
      QWordMemory ( // 32-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Cacheable, ReadWrite,
        0x0000000000,        // Granularity
        0x004C000000,        // Min Base Address
        0x004FFFFFFF,        // Max Base Address
        0x0000000000,        // Translate
        0x0004000000         // Length
      )
      QWordMemory ( // 64-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Prefetchable, ReadWrite,
        0x0000000000,       // Granularity
        0x6600000000,       // Min Base Address pci address
        0x67FFFFFFFF,       // Max Base Address
        0x0000000000,       // Translate
        0x0200000000        // Length
      )
      QWordMemory ( // 64-bit BAR Windows
        ResourceProducer, PosDecode,
        MinFixed, MaxFixed,
        Cacheable, ReadWrite,
        0x0000000000,       // Granularity
        0x6500000000,       // Min Base Address pci address
        0x65FFFFFFFF,       // Max Base Address
        0x0000000000,       // Translate
        0x0100000000        // Length
      )
      QWordIO (
        ResourceProducer, MinFixed, MaxFixed,
        PosDecode, EntireRange,
        0x0,               // Granularity
        0x0000000000,      // Min Base Address
        0x00001FFFFF,      // Max Base Address
        0x6410000000,      // Translate
        0x0000200000       // Length
      )
    })

    PCI_OSC_SUPPORT()

    Name (_DMA, ResourceTemplate() {
      QWordMemory (ResourceProducer,
        ,
        MinFixed,
        MaxFixed,
        Prefetchable,
        ReadWrite,
        0x0,
        0x0,          // MIN
        0x3FFFFFFFFF, // MAX
        0x0,          // TRA
        0x4000000000, // LEN
        ,
        ,
        )
    })

    Device (RES4)
    {
      Name (_HID, "SOPH0000" /* PNP Motherboard Resources */)  // _HID: Hardware ID
      Name (_UID, 0x9)  // Unique ID
      Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
      {
        QWordMemory ( // dbi
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x6C08800000,                       // Range Minimum
          0x6C08800FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000001000,                       // Length
          , , , AddressRangeMemory, TypeStatic)

        QWordMemory ( // ctrl
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x6C08B80000,                       // Range Minimum
          0x6C08B80FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000001000,                       // Length
          , , , AddressRangeMemory, TypeStatic)

        QWordMemory ( // atu
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x6C08B00000,                       // Range Minimum
          0x6C08B03FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000004000,                       // Length
          , , , AddressRangeMemory, TypeStatic)

        QWordMemory (
          ResourceProducer, PosDecode,
          MinFixed, MaxFixed,
          NonCacheable, ReadWrite,
          0x0000000000,                       // Granularity
          0x6400000000,                       // Range Minimum
          0x6400000FFF,                       // Range Maximum
          0x0000000000,                       // Translation Offset
          0x0000001000,                       // Length
          , , , AddressRangeMemory, TypeStatic)
      })
      Method (_STA) {
        Return (0xF)
      }
    }

  } // Device(PCI9)
}
