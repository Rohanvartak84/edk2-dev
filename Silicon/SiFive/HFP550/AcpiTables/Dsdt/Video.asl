/** @file
*  Differentiated System Description Table Fields (DSDT)
*
*  Copyright (c) 2025, SOPHGO Inc. All rights reserved.
*
*  SPDX-License-Identifier: BSD-2-Clause-Patent
*
**/

Scope (_SB)
{
  Device (BASE){
    Name (_HID, "SOPH0014")
    Name (_CID, "sophon,base")
    Method (_STA)  
    {              
      Return (0xF) 
    }              
  }
  Device (VCDV){
    Name (_HID, "SOPH0015")
    Name (_CID, "sophgo,vc_drv")
    Name (_UID, 0)


    Method(_STA) {
        Return (0xF)
    }

    Name (_CRS, ResourceTemplate ()
    {
        QWordMemory (
            ResourceConsumer,
            ,
            MinFixed,
            MaxFixed,
            NonCacheable,
            ReadWrite,
            0x0,
            0x6b00180000,
            0x6b0018FFFF,
            0x0,
            0x10000
        )
        QWordMemory (
            ResourceConsumer,
            ,
            MinFixed,
            MaxFixed,
            NonCacheable,
            ReadWrite,
            0x0,
            0x6b00190000,
            0x6b0019FFFF,
            0x0,
            0x10000
        )
        QWordMemory (
            ResourceConsumer,
            ,
            MinFixed,
            MaxFixed,
            NonCacheable,
            ReadWrite,
            0x0,
            0x6b001a0000,
            0x6b001aFFFF,
            0x0,
            0x10000
        )
        QWordMemory (
            ResourceConsumer,
            ,
            MinFixed,
            MaxFixed,
            NonCacheable,
            ReadWrite,
            0x0,
            0x6b001b0000,
            0x6b001bFFFF,
            0x0,
            0x10000
        )
        QWordMemory (
            ResourceConsumer,
            ,
            MinFixed,
            MaxFixed,
            NonCacheable,
            ReadWrite,
            0x0,
            0x6b02180000,
            0x6b0218FFFF,
            0x0,
            0x10000
        )
        QWordMemory (
            ResourceConsumer,
            ,
            MinFixed,
            MaxFixed,
            NonCacheable,
            ReadWrite,
            0x0,
            0x6b02190000,
            0x6b0219FFFF,
            0x0,
            0x10000
        )
        QWordMemory (
            ResourceConsumer,
            ,
            MinFixed,
            MaxFixed,
            NonCacheable,
            ReadWrite,
            0x0,
            0x6b021a0000,
            0x6b021aFFFF,
            0x0,
            0x10000
        )
        QWordMemory (
            ResourceConsumer,
            ,
            MinFixed,
            MaxFixed,
            NonCacheable,
            ReadWrite,
            0x0,
            0x6b021b0000,
            0x6b021bFFFF,
            0x0,
            0x10000
        )
        QWordMemory (
            ResourceConsumer,
            ,
            MinFixed,
            MaxFixed,
            NonCacheable,
            ReadWrite,
            0x0,
            0x6b04180000,
            0x6b0418FFFF,
            0x0,
            0x10000
        )
        QWordMemory (
            ResourceConsumer,
            ,
            MinFixed,
            MaxFixed,
            NonCacheable,
            ReadWrite,
            0x0,
            0x6b04190000,
            0x6b0419FFFF,
            0x0,
            0x10000
        )
        QWordMemory (
            ResourceConsumer,
            ,
            MinFixed,
            MaxFixed,
            NonCacheable,
            ReadWrite,
            0x0,
            0x6b041a0000,
            0x6b041aFFFF,
            0x0,
            0x10000
        )
        QWordMemory (
            ResourceConsumer,
            ,
            MinFixed,
            MaxFixed,
            NonCacheable,
            ReadWrite,
            0x0,
            0x6b041b0000,
            0x6b041bFFFF,
            0x0,
            0x10000
        )
        QWordMemory (
            ResourceConsumer,
            ,
            MinFixed,
            MaxFixed,
            NonCacheable,
            ReadWrite,
            0x0,
            0x6b06180000,
            0x6b0618FFFF,
            0x0,
            0x10000
        )
        QWordMemory (
            ResourceConsumer,
            ,
            MinFixed,
            MaxFixed,
            NonCacheable,
            ReadWrite,
            0x0,
            0x6b06190000,
            0x6b0619FFFF,
            0x0,
            0x10000
        )
        QWordMemory (
            ResourceConsumer,
            ,
            MinFixed,
            MaxFixed,
            NonCacheable,
            ReadWrite,
            0x0,
            0x6b061a0000,
            0x6b061aFFFF,
            0x0,
            0x10000
        )
        QWordMemory (
            ResourceConsumer,
            ,
            MinFixed,
            MaxFixed,
            NonCacheable,
            ReadWrite,
            0x0,
            0x6b061b0000,
            0x6b061bFFFF,
            0x0,
            0x10000
        )
        QWordMemory (
            ResourceConsumer,
            ,
            MinFixed,
            MaxFixed,
            NonCacheable,
            ReadWrite,
            0x0,
            0x0000010000,
            0x000001FFFF,
            0x0,
            0x10000
        )
        QWordMemory (
            ResourceConsumer,
            ,
            MinFixed,
            MaxFixed,
            NonCacheable,
            ReadWrite,
            0x0,
            0x0000020000,
            0x000002FFFF,
            0x0,
            0x10000
        )
        QWordMemory (
            ResourceConsumer,
            ,
            MinFixed,
            MaxFixed,
            NonCacheable,
            ReadWrite,
            0x0,
            0x0002010000,
            0x000201FFFF,
            0x0,
            0x10000
        )
        QWordMemory (
            ResourceConsumer,
            ,
            MinFixed,
            MaxFixed,
            NonCacheable,
            ReadWrite,
            0x0,
            0x0002020000,
            0x000202FFFF,
            0x0,
            0x10000
        )
        QWordMemory (
            ResourceConsumer,
            ,
            MinFixed,
            MaxFixed,
            NonCacheable,
            ReadWrite,
            0x0,
            0x0004010000,
            0x000401FFFF,
            0x0,
            0x10000
        )
        QWordMemory (
            ResourceConsumer,
            ,
            MinFixed,
            MaxFixed,
            NonCacheable,
            ReadWrite,
            0x0,
            0x0004020000,
            0x000402FFFF,
            0x0,
            0x10000
        )
        QWordMemory (
            ResourceConsumer,
            ,
            MinFixed,
            MaxFixed,
            NonCacheable,
            ReadWrite,
            0x0,
            0x0006010000,
            0x000601FFFF,
            0x0,
            0x10000
        )
        QWordMemory (
            ResourceConsumer,
            ,
            MinFixed,
            MaxFixed,
            NonCacheable,
            ReadWrite,
            0x0,
            0x0006020000,
            0x000602FFFF,
            0x0,
            0x10000
        )
        QWordMemory (
            ResourceConsumer,
            ,
            MinFixed,
            MaxFixed,
            NonCacheable,
            ReadWrite,
            0x0,
            0x6b00040000,
            0x6b00040FFF,
            0x0,
            0x1000
        )
        QWordMemory (
            ResourceConsumer,
            ,
            MinFixed,
            MaxFixed,
            NonCacheable,
            ReadWrite,
            0x0,
            0x6b00042000,
            0x6b00042FFF,
            0x0,
            0x1000
        )
        QWordMemory (
            ResourceConsumer,
            ,
            MinFixed,
            MaxFixed,
            NonCacheable,
            ReadWrite,
            0x0,
            0x6b02040000,
            0x6b02040FFF,
            0x0,
            0x1000
        )
        QWordMemory (
            ResourceConsumer,
            ,
            MinFixed,
            MaxFixed,
            NonCacheable,
            ReadWrite,
            0x0,
            0x6b02042000,
            0x6b02042FFF,
            0x0,
            0x1000
        )
        QWordMemory (
            ResourceConsumer,
            ,
            MinFixed,
            MaxFixed,
            NonCacheable,
            ReadWrite,
            0x0,
            0x6b04040000,
            0x6b04040FFF,
            0x0,
            0x1000
        )
        QWordMemory (
            ResourceConsumer,
            ,
            MinFixed,
            MaxFixed,
            NonCacheable,
            ReadWrite,
            0x0,
            0x6b04042000,
            0x6b04042FFF,
            0x0,
            0x1000
        )
        QWordMemory (
            ResourceConsumer,
            ,
            MinFixed,
            MaxFixed,
            NonCacheable,
            ReadWrite,
            0x0,
            0x6b06040000,
            0x6b06040FFF,
            0x0,
            0x1000
        )
        QWordMemory (
            ResourceConsumer,
            ,
            MinFixed,
            MaxFixed,
            NonCacheable,
            ReadWrite,
            0x0,
            0x6b06042000,
            0x6b06042FFF,
            0x0,
            0x1000
        )
        QWordMemory (
            ResourceConsumer,
            ,
            MinFixed,
            MaxFixed,
            NonCacheable,
            ReadWrite,
            0x0,
            0x1080000000,
            0x137FFFFFFF,
            0x0,
            0x300000000
        )
        QWordMemory (
            ResourceConsumer,
            ,
            MinFixed,
            MaxFixed,
            NonCacheable,
            ReadWrite,
            0x0,
            0x1380000000,
            0x147FFFFFFF,
            0x0,
            0x100000000
        )
        Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, , ,)
        {
            161, 162, 167, 168, 201, 202, 207, 208,
            241, 242, 247, 248, 281, 282, 287, 288,
            136, 140, 176, 180, 216, 220, 256, 260,
            137, 141, 177, 181, 217, 221, 257, 261,
            138, 142, 178, 182, 218, 222, 258, 262,
            139, 143, 179, 183, 219, 223, 259, 263,
            148, 149, 188, 189, 228, 229, 268, 269
        }
    })
  }

  Device (VPSS)
  {
    Name (_HID, "SOPH0016")
    Name (_CID, "sophgo,vpss")
    Name (_UID, 0)
    Method(_STA) {
      Return (0xF)
    }

    Name (_CRS, ResourceTemplate ()
    {
      QWordMemory (
        ResourceConsumer,
        ,
        MinFixed,
        MaxFixed,
        NonCacheable,
        ReadWrite,
        0x0,
        0x6B00100000,
        0x6B0017FFFF,
        0x0,
        0x80000
      )
      QWordMemory (
        ResourceConsumer,
        ,
        MinFixed,
        MaxFixed,
        NonCacheable,
        ReadWrite,
        0x0,
        0x6B02100000,
        0x6B0217FFFF,
        0x0,
        0x80000
      )
      QWordMemory (
        ResourceConsumer,
        ,
        MinFixed,
        MaxFixed,
        NonCacheable,
        ReadWrite,
        0x0,
        0x6B04100000,
        0x6B0417FFFF,
        0x0,
        0x80000
      )
      QWordMemory (
        ResourceConsumer,
        ,
        MinFixed,
        MaxFixed,
        NonCacheable,
        ReadWrite,
        0x0,
        0x6B06100000,
        0x6B0617FFFF,
        0x0,
        0x80000
      )
      Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive,,,) { 157, 158, 159, 160, 163, 164, 165, 166, 197, 198, 199, 200, 203, 204, 205, 206, 237, 238, 239, 240, 243, 244, 245, 246, 277, 278, 279, 280, 283, 284, 285, 286 }
    })
  }
}
