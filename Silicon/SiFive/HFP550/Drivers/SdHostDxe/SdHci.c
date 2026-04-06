/** @file
  The implementation for handling SD card operations using the SD Host Controller Interface (SDHCI).

  Copyright (c) 2016-2017, ARM Limited and Contributors. All rights reserved.
  Copyright (c) 2023, Academy of Intelligent Innovation, Shandong Universiy, China.P.R. All rights reserved.<BR>
  SPDX-License-Identifier: BSD-2-Clause-Patent

**/

#include <Uefi.h>
#include <Base.h>
#include <Library/BaseLib.h>
#include <Library/MemoryAllocationLib.h>
#include <Library/DebugLib.h>
#include <Library/IoLib.h>
#include <Library/PcdLib.h>
#include <Library/UefiBootServicesTableLib.h>
#include <Library/BaseMemoryLib.h>
#include <Include/MmcHost.h>
#include <Library/TimerLib.h>

#include "SdHci.h"

#define SDCARD_INIT_FREQ  (200 * 1000)
#define SDCARD_TRAN_FREQ  (6 * 1000 * 1000)

/**
  Return the clock rate of SD card.

  @retval the clock rate of SD card.

**/
INT32
BmGetSdClk (
  VOID
  )
{
  return 100*1000*1000;
}

/**
  SD card sends command with response block data.

  @param    Cmd   Command sent by SD card.

  @retval EFI_SUCCESS             The command with response block data was sent successfully.
  @retval EFI_DEVICE_ERROR        There was an error during the command transmission or response handling.
  @retval EFI_TIMEOUT             The command transmission or response handling timed out.

**/
STATIC
EFI_STATUS
SdSendCmdWithData (
  IN OUT MMC_CMD *Cmd
  )
{
  UINTN   Base;
  UINT32  Mode;
  UINT32  State;
  UINT32  DmaAddr;
  UINT32  Flags;
  UINT32  Timeout;

  Base  = BmParams.RegBase;
  Mode  = 0;
  Flags = 0;

  // Make sure Cmd line is clear
  while (1) {
    if (!(MmioRead32 (Base + SDHCI_PSTATE) & SDHCI_CMD_INHIBIT))
    break;
  }

  switch (Cmd->CmdIdx) {
    case MMC_CMD17:
    case MMC_CMD18:
    case MMC_ACMD51:
      Mode = SDHCI_TRNS_BLK_CNT_EN | SDHCI_TRNS_MULTI | SDHCI_TRNS_READ;
      if (!(BmParams.Flags & SD_USE_PIO))
        Mode |= SDHCI_TRNS_DMA;
      break;
    case MMC_CMD24:
    case MMC_CMD25:
      Mode = (SDHCI_TRNS_BLK_CNT_EN | SDHCI_TRNS_MULTI) & ~SDHCI_TRNS_READ;
      if (!(BmParams.Flags & SD_USE_PIO))
        Mode |= SDHCI_TRNS_DMA;
      break;
    default:
      ASSERT(0);
  }

  MmioWrite16 (Base + SDHCI_TRANSFER_MODE, Mode);
  MmioWrite32 (Base + SDHCI_ARGUMENT, Cmd->CmdArg);

  // set Cmd Flags
  if (Cmd->CmdIdx == MMC_CMD0)
    Flags |= SDHCI_CMD_RESP_NONE;
  else {
    if (Cmd->ResponseType & MMC_RSP_136)
      Flags |= SDHCI_CMD_RESP_LONG;
    else
      Flags |= SDHCI_CMD_RESP_SHORT;
    if (Cmd->ResponseType & MMC_RSP_CRC)
      Flags |= SDHCI_CMD_CRC;
    if (Cmd->ResponseType & MMC_RSP_CMD_IDX)
      Flags |= SDHCI_CMD_INDEX;
  }

  Flags |= SDHCI_CMD_DATA;

  // issue the Cmd
  MmioWrite16 (Base + SDHCI_COMMAND, SDHCI_MAKE_CMD(Cmd->CmdIdx, Flags));

  // check Cmd complete if necessary
  if ((MmioRead16 (Base + SDHCI_TRANSFER_MODE) & SDHCI_TRNS_RESP_INT) == 0) {
    Timeout = 100000;
    while (1) {
      State = MmioRead16 (Base + SDHCI_INT_STATUS);
      if (State & SDHCI_INT_ERROR) {
        DEBUG ((DEBUG_ERROR, "%a: interrupt error: 0x%x 0x%x\n", __func__,  MmioRead16 (Base + SDHCI_INT_STATUS),
                                MmioRead16 (Base + SDHCI_ERR_INT_STATUS)));
        return EFI_DEVICE_ERROR;
      }
      if (State & SDHCI_INT_CMD_COMPLETE) {
        MmioWrite16 (Base + SDHCI_INT_STATUS, State | SDHCI_INT_CMD_COMPLETE);
        break;
      }

      gBS->Stall (1);
      if (!Timeout--) {
        DEBUG ((DEBUG_ERROR, "%a: Timeout!\n", __func__));
        return EFI_TIMEOUT;
      }
    }

    // get Cmd respond
    if (Flags != SDHCI_CMD_RESP_NONE)
      Cmd->Response[0] = MmioRead32 (Base + SDHCI_RESPONSE_01);
    if (Flags & SDHCI_CMD_RESP_LONG) {
      Cmd->Response[1] = MmioRead32 (Base + SDHCI_RESPONSE_23);
      Cmd->Response[2] = MmioRead32 (Base + SDHCI_RESPONSE_45);
      Cmd->Response[3] = MmioRead32 (Base + SDHCI_RESPONSE_67);
    }
  }

  // check dma/transfer complete
  if (!(BmParams.Flags & SD_USE_PIO)) {
    while (1) {
      State = MmioRead16 (Base + SDHCI_INT_STATUS);
      if (State & SDHCI_INT_ERROR) {
        DEBUG ((DEBUG_ERROR, "%a: interrupt error: 0x%x 0x%x\n", __func__,  MmioRead16 (Base + SDHCI_INT_STATUS),
                                MmioRead16 (Base + SDHCI_ERR_INT_STATUS)));
        return EFI_DEVICE_ERROR;
      }

      if (State & SDHCI_INT_XFER_COMPLETE) {
        MmioWrite16 (Base + SDHCI_INT_STATUS, State);
        break;
      }

      if (State & SDHCI_INT_DMA_END) {
        MmioWrite16 (Base + SDHCI_INT_STATUS, State);
        if (MmioRead16 (Base + SDHCI_HOST_CONTROL2) & SDHCI_HOST_VER4_ENABLE) {
          DmaAddr = MmioRead32 (Base + SDHCI_ADMA_SA_LOW);
          MmioWrite32 (Base + SDHCI_ADMA_SA_LOW, DmaAddr);
          MmioWrite32 (Base + SDHCI_ADMA_SA_HIGH, 0);
        } else {
          DmaAddr = MmioRead32 (Base + SDHCI_DMA_ADDRESS);
          MmioWrite32 (Base + SDHCI_DMA_ADDRESS, DmaAddr);
        }
      }

    }
  }

  return EFI_SUCCESS;
}

/**
  SD card sends command without response block data.

  @param    Cmd   Command sent by SD card.

  @retval EFI_SUCCESS             The command without response block data was sent successfully.
  @retval EFI_DEVICE_ERROR        There was an error during the command transmission or response handling.
  @retval EFI_TIMEOUT             The command transmission or response handling timed out.

**/
STATIC
EFI_STATUS
SdSendCmdWithoutData (
  IN OUT MMC_CMD *Cmd
  )
{
  UINTN   Base;
  UINT32  State;
  UINT32  Flags;
  UINT32  Timeout;

  Base    = BmParams.RegBase;
  Flags   = 0x0;
  Timeout = 10000;

  // make sure Cmd line is clear
  while (1) {
    if (!(MmioRead32 (Base + SDHCI_PSTATE) & SDHCI_CMD_INHIBIT))
      break;
  }

  // set Cmd Flags
  if (Cmd->CmdIdx == MMC_CMD0)
    Flags |= SDHCI_CMD_RESP_NONE;
  else if (Cmd->CmdIdx == MMC_CMD1)
    Flags |= SDHCI_CMD_RESP_SHORT;
  else if (Cmd->CmdIdx == MMC_ACMD41)
    Flags |= SDHCI_CMD_RESP_SHORT;
  else {
    if (Cmd->ResponseType & MMC_RSP_136)
      Flags |= SDHCI_CMD_RESP_LONG;
    else
      Flags |= SDHCI_CMD_RESP_SHORT;
    if (Cmd->ResponseType & MMC_RSP_CRC)
      Flags |= SDHCI_CMD_CRC;
    if (Cmd->ResponseType & MMC_RSP_CMD_IDX)
      Flags |= SDHCI_CMD_INDEX;
  }

  // make sure dat line is clear if necessary
  if (Flags != SDHCI_CMD_RESP_NONE) {
    while (1) {
      if (!(MmioRead32 (Base + SDHCI_PSTATE) & SDHCI_CMD_INHIBIT_DAT))
        break;
    }
  }

  // issue the Cmd
  MmioWrite32 (Base + SDHCI_ARGUMENT, Cmd->CmdArg);
  MmioWrite16 (Base + SDHCI_COMMAND, SDHCI_MAKE_CMD(Cmd->CmdIdx, Flags));

  // check Cmd complete
  Timeout = 100000;
  while (1) {
    State = MmioRead16 (Base + SDHCI_INT_STATUS);
    if (State & SDHCI_INT_ERROR) {
      DEBUG ((DEBUG_ERROR, "%a: interrupt error: 0x%x 0x%x\n", __func__,  MmioRead16 (Base + SDHCI_INT_STATUS),
                              MmioRead16 (Base + SDHCI_ERR_INT_STATUS)));
      return EFI_DEVICE_ERROR;
    }
    if (State & SDHCI_INT_CMD_COMPLETE) {
      MmioWrite16 (Base + SDHCI_INT_STATUS, State | SDHCI_INT_CMD_COMPLETE);
      break;
    }

    gBS->Stall (1);
    if (!Timeout--) {
      DEBUG ((DEBUG_ERROR, "%a: Timeout!\n", __func__));
      return EFI_TIMEOUT;
    }
  }

  // get Cmd respond
  if (!(Flags & SDHCI_CMD_RESP_NONE))
    Cmd->Response[0] = MmioRead32 (Base + SDHCI_RESPONSE_01);
  if (Flags & SDHCI_CMD_RESP_LONG) {
    Cmd->Response[1] = MmioRead32 (Base + SDHCI_RESPONSE_23);
    Cmd->Response[2] = MmioRead32 (Base + SDHCI_RESPONSE_45);
    Cmd->Response[3] = MmioRead32 (Base + SDHCI_RESPONSE_67);
  }

  return EFI_SUCCESS;
}

/**
  SD card sends command.

  @param[in]  Idx       Command ID.
  @param[in]  Arg       Command argument.
  @param[in]  RespType  Type of response data.
  @param[out] Response  Response data.

  @retval  EFI_SUCCESS             The command was sent successfully.
  @retval  EFI_DEVICE_ERROR        There was an error during the command transmission or response handling.
  @retval  EFI_TIMEOUT             The command transmission or response handling timed out.

**/
EFI_STATUS
EFIAPI
BmSdSendCmd (
  IN  UINT32 Idx,
  IN  UINT32 Arg,
  IN  UINT32 RespType,
  OUT UINT32 *Response
  )
{
  EFI_STATUS  Status;
  MMC_CMD     Cmd;

  // DEBUG ((DEBUG_INFO, "%a: SDHCI Cmd, Idx=%d, Arg=0x%x, ResponseType=0x%x\n", __func__, Idx, Arg, RespType));

  ZeroMem(&Cmd,sizeof(MMC_CMD));

  Cmd.CmdIdx       = Idx;
  Cmd.CmdArg       = Arg;
  Cmd.ResponseType = RespType;

  switch (Cmd.CmdIdx) {
    case MMC_CMD17:
    case MMC_CMD18:
    case MMC_CMD24:
    case MMC_CMD25:
    case MMC_ACMD51:
      Status = SdSendCmdWithData(&Cmd);
      break;
    default:
      Status = SdSendCmdWithoutData(&Cmd);
  }

  if ((Status == EFI_SUCCESS) && (Response != NULL)) {
    for (INT32 I = 0; I < 4; I++) {
      *Response = Cmd.Response[I];
      Response++;
    }
  }
  return Status;
}

/**
  Set clock frequency of SD card.

  @param[in] Clk       The clock frequency of SD card.

**/
VOID
SdSetClk (
  IN INT32 Clk
  )
{
  INT32  I;
  INT32  Div;
  UINTN  Base;

  ASSERT (Clk > 0);

  if (BmParams.ClkRate <= Clk) {
    Div = 0;
  } else {
    for (Div = 0x1; Div < 0xFF; Div++) {
      if (BmParams.ClkRate / (2 * Div) <= Clk)
        break;
    }
  }
  ASSERT (Div <= 0xFF);

  Base = BmParams.RegBase;
  if (MmioRead16 (Base + SDHCI_HOST_CONTROL2) & (1 << 15)) {
    //verbose("Use SDCLK Preset Value\n");
  } else {
    //verbose("Set SDCLK by driver. Div=0x%x(%d)\n", Div, Div);
    MmioWrite16 (Base + SDHCI_CLK_CTRL,
            MmioRead16 (Base + SDHCI_CLK_CTRL) & ~0x9); // disable INTERNAL_CLK_EN and PLL_ENABLE
    MmioWrite16 (Base + SDHCI_CLK_CTRL,
            (MmioRead16 (Base + SDHCI_CLK_CTRL) & 0xDF) | Div << 8); // set Clk Div
    MmioWrite16 (Base + SDHCI_CLK_CTRL,
            MmioRead16 (Base + SDHCI_CLK_CTRL) | 0x1); // set INTERNAL_CLK_EN

    for (I = 0; I <= 150000; I += 100) {
      if (MmioRead16 (Base + SDHCI_CLK_CTRL) & 0x2)
        break;
      gBS->Stall (100);
    }

    if (I > 150000) {
      DEBUG ((DEBUG_ERROR, "%a: SD INTERNAL_CLK_EN setting FAILED!\n", __func__));
      ASSERT(0);
    }

    MmioWrite16 (Base + SDHCI_CLK_CTRL, MmioRead16 (Base + SDHCI_CLK_CTRL) | 0x8); // set PLL_ENABLE

    for (I = 0; I <= 150000; I += 100) {
      if (MmioRead16 (Base + SDHCI_CLK_CTRL) & 0x2)
        return;
      gBS->Stall (100);
    }
  }

  DEBUG ((DEBUG_INFO, "%a: SD PLL setting FAILED!\n", __func__));
}

/**
  Change clock frequency of SD card.

  @param[in] Clk       The clock frequency of SD card.

**/
VOID
SdChangeClk (
  IN INT32 Clk
  )
{
  INT32  I;
  INT32  Div;
  UINTN  Base;

  ASSERT (Clk > 0);

  if (BmParams.ClkRate <= Clk) {
    Div = 0;
  } else {
    for (Div = 0x1; Div < 0xFF; Div++) {
      if (BmParams.ClkRate / (2 * Div) <= Clk)
        break;
    }
  }
  ASSERT (Div <= 0xFF);

  Base = BmParams.RegBase;

  MmioWrite16 (Base + SDHCI_CLK_CTRL,
          MmioRead16 (Base + SDHCI_CLK_CTRL) & ~(0x1 << 2)); // stop SD clock

  MmioWrite16 (Base + SDHCI_CLK_CTRL,
          MmioRead16 (Base + SDHCI_CLK_CTRL) & ~0x8); // disable  PLL_ENABLE

  if (MmioRead16 (Base + SDHCI_HOST_CONTROL2) & (1 << 15)) {
    MmioWrite16 (Base + SDHCI_HOST_CONTROL2,
            MmioRead16 (Base + SDHCI_HOST_CONTROL2) & ~0x7); // clr UHS_MODE_SEL
  } else {
    MmioWrite16 (Base + SDHCI_CLK_CTRL,
            (MmioRead16 (Base + SDHCI_CLK_CTRL) & 0xDF) | Div << 8); // set Clk Div
    MmioWrite16 (Base + SDHCI_CLK_CTRL,
            MmioRead16 (Base + SDHCI_CLK_CTRL) & ~(0x1 << 5)); // CLK_GEN_SELECT
  }

  MmioWrite16 (Base + SDHCI_CLK_CTRL,
          MmioRead16 (Base + SDHCI_CLK_CTRL) | 0xc); // enable  PLL_ENABLE

  for (I = 0; I <= 150000; I += 100) {
    if (MmioRead16 (Base + SDHCI_CLK_CTRL) & 0x2)
      return;
    gBS->Stall (100);
  }

  DEBUG ((DEBUG_INFO, "%a: SD PLL setting FAILED!\n", __func__));
}

/**
  Detect the status of the SD card.

  @return The status of the SD card:
          - SDCARD_STATUS_INSERTED:      The SD card is inserted.
          - SDCARD_STATUS_NOT_INSERTED:  The SD card is not inserted.
          - SDCARD_STATUS_UNKNOWN:       The status of the SD card is unknown.

**/
INT32
BmSdCardDetect (
  VOID
  )
{
  UINTN  Base;
  UINTN  Reg;

  Base = BmParams.RegBase;

  if (BmParams.CardIn != SDCARD_STATUS_UNKNOWN)
    return BmParams.CardIn;

  MmioWrite16 (Base + SDHCI_INT_STATUS_EN,
          MmioRead16 (Base + SDHCI_INT_STATUS_EN) | SDHCI_INT_CARD_INSERTION_EN);

  Reg = MmioRead32 (Base + SDHCI_PSTATE);

  if (Reg & SDHCI_CARD_INSERTED)
    BmParams.CardIn = SDCARD_STATUS_INSERTED;
  else
    BmParams.CardIn = SDCARD_STATUS_NOT_INSERTED;

  return BmParams.CardIn;
}

/**
  Set the input/output settings for the SD card.

  @param[in] Clk     The clock frequency for the SD card.
  @param[in] Width   The bus width for data transfer.

  @retval EFI_SUCCESS             The input/output settings were set successfully.
  @retval EFI_UNSUPPORTED         The specified bus width is not supported.

**/
EFI_STATUS
BmSdSetIos (
  IN UINT32 Clk,
  IN UINT32 Width
  )
{
  switch (Width) {
    case MMC_BUS_WIDTH_1:
      MmioWrite8 (BmParams.RegBase + SDHCI_HOST_CONTROL,
              MmioRead8 (BmParams.RegBase + SDHCI_HOST_CONTROL) &
              ~SDHCI_DAT_XFER_WIDTH);
      break;
    case MMC_BUS_WIDTH_4:
      MmioWrite8 (BmParams.RegBase + SDHCI_HOST_CONTROL,
              MmioRead8 (BmParams.RegBase + SDHCI_HOST_CONTROL) |
              SDHCI_DAT_XFER_WIDTH);
      break;
    default:
      ASSERT (0);
  }

  SdChangeClk (Clk);

  return EFI_SUCCESS;
}

/**
  Prepare the SD card for data transfer.
  Set the number and size of data blocks before sending IO commands to the SD card.

  @param[in]  Lba       Logical Block Address.
  @param[in]  Buf       Buffer Address.
  @param[in]  Size      Size of Data Blocks.

  @retval EFI_SUCCESS             The SD card was prepared successfully.
  @retval Other                   An error occurred during the preparation of the SD card.

**/
EFI_STATUS
BmSdPrepare (
  IN INT32 Lba,
  IN UINTN Buf,
  IN UINTN Size
  )
{
  UINTN   LoadAddr;
  UINTN   Base;
  UINT32  BlockCnt;
  UINT32  BlockSize;
  UINT8   Tmp;

  LoadAddr = Buf;

  if (Size >= MMC_BLOCK_SIZE) {
    // CMD17, 18, 24, 25
    // ASSERT (((LoadAddr & MMC_BLOCK_MASK) == 0) && ((Size % MMC_BLOCK_SIZE) == 0));
    BlockSize = MMC_BLOCK_SIZE;
    BlockCnt  = Size / MMC_BLOCK_SIZE;
  } else {
    // ACMD51
    ASSERT (((LoadAddr & 8) == 0) && ((Size % 8) == 0));
    BlockSize = 8;
    BlockCnt  = Size / 8;
  }

  Base = BmParams.RegBase;

  if (!(BmParams.Flags & SD_USE_PIO)) {
    if (MmioRead16 (Base + SDHCI_HOST_CONTROL2) & SDHCI_HOST_VER4_ENABLE) {
      MmioWrite32 (Base + SDHCI_ADMA_SA_LOW, LoadAddr);
      MmioWrite32 (Base + SDHCI_ADMA_SA_HIGH, (LoadAddr >> 32));
      MmioWrite32 (Base + SDHCI_DMA_ADDRESS, BlockCnt);
      MmioWrite16 (Base + SDHCI_BLOCK_COUNT, 0);
    } else {
      ASSERT((LoadAddr >> 32) == 0);
      MmioWrite32 (Base + SDHCI_DMA_ADDRESS, LoadAddr);
      MmioWrite16 (Base + SDHCI_BLOCK_COUNT, BlockCnt);
    }

    // 512K bytes SDMA buffer boundary
    MmioWrite16 (Base + SDHCI_BLOCK_SIZE, SDHCI_MAKE_BLKSZ(7, BlockSize));

    // select SDMA
    Tmp = MmioRead8 (Base + SDHCI_HOST_CONTROL);
    Tmp &= ~SDHCI_CTRL_DMA_MASK;
    Tmp |= SDHCI_CTRL_SDMA;
    MmioWrite8 (Base + SDHCI_HOST_CONTROL, Tmp);
  } else {
    MmioWrite16 (Base + SDHCI_BLOCK_SIZE, BlockSize);
    MmioWrite16 (Base + SDHCI_BLOCK_COUNT, BlockCnt);
  }

  return EFI_SUCCESS;
}

/**
  SD card sends command to read data blocks.

  @param[in]  Lba       Logical Block Address.
  @param[in]  Buf       Buffer Address.
  @param[in]  Size      Size of Data Blocks.

  @retval  EFI_SUCCESS             The command to read data blocks was sent successfully.
  @retval  EFI_TIMEOUT             The command transmission or data transfer timed out.

**/
#define  SDHCI_INT_SPACE_AVAIL		BIT4
#define  SDHCI_INT_DATA_AVAIL		BIT5
#define  SDHCI_SPACE_AVAILABLE		BIT10
#define  SDHCI_DATA_AVAILABLE		BIT11

EFI_STATUS
BmSdRead (
  IN INT32   Lba,
  IN UINT32* Buf,
  IN UINTN   Size
  )
{
  UINT32  Timeout;
  UINTN   Base;
  UINT32  *Data;
  UINT32  BlockSize;
  UINT32  BlockCnt;
  UINT32  Status;

  Timeout   = 0;
  Base      = BmParams.RegBase;
  Data      = Buf;
  BlockSize = 0;
  BlockCnt  = 0;
  Status    = 0;

  UINT32 Rdy, Mask;

  Rdy = SDHCI_INT_SPACE_AVAIL | SDHCI_INT_DATA_AVAIL;
  Mask = SDHCI_SPACE_AVAILABLE | SDHCI_DATA_AVAILABLE;

  if (BmParams.Flags & SD_USE_PIO) {
    BlockSize = MmioRead16 (Base + SDHCI_BLOCK_SIZE);
    BlockCnt  = Size / BlockSize;
    BlockSize /= 4;

    for (INT32 I = 0; I < BlockCnt; ) {
      Status = MmioRead16 (Base + SDHCI_INT_STATUS);
      if (Status & SDHCI_INT_ERROR) {
        DEBUG ((DEBUG_ERROR, "%a: error: 0x%x 0x%x\n", __func__,  MmioRead16 (Base + SDHCI_INT_STATUS),
                                MmioRead16 (Base + SDHCI_ERR_INT_STATUS)));
        return EFI_DEVICE_ERROR;
      }

      if ((Status & Rdy)) {
	  if(!(MmioRead32 (Base + SDHCI_PSTATE) & Mask)) {
		  continue;
	  }

	MmioWrite16 (Base + SDHCI_INT_STATUS, Rdy); 
        for (INT32 j = 0; j < BlockSize; j++) {
          *(Data++) = MmioRead32 (Base + SDHCI_BUF_DATA_R);
        }

        Timeout = 0;
        I++;
      } else {
        gBS->Stall (1);
        Timeout++;
	MicroSecondDelay(10);
      }

      if (Timeout >= 1000000) {
        DEBUG ((DEBUG_INFO, "%a: sdhci read data Timeout\n", __func__));
        goto Timeout;
      }
    }

    Timeout = 0;
    while (1) {
      Status = MmioRead16 (Base + SDHCI_INT_STATUS);
      if (Status & SDHCI_INT_XFER_COMPLETE) {
        MmioWrite16 (Base + SDHCI_INT_STATUS,
                Status | SDHCI_INT_XFER_COMPLETE);

        return EFI_SUCCESS;
      } else {
        gBS->Stall (1);
        Timeout++;
      }

      if (Timeout >= 10000) {
        DEBUG ((DEBUG_INFO, "%a:wait xfer complete Timeout\n", __func__));
        goto Timeout;
      }
    }
  } else {
    return EFI_SUCCESS;
  }

Timeout:
  return EFI_TIMEOUT;

}

/**
  SD card sends commands to write data blocks.

  @param[in]  Lba       Logical Block Address.
  @param[in]  Buf       Buffer Address.
  @param[in]  Size      Size of Data Blocks.

  @retval  EFI_SUCCESS             The command to write data blocks was sent successfully.
  @retval  EFI_TIMEOUT             The command transmission or data transfer timed out.

**/
EFI_STATUS
BmSdWrite (
  IN INT32   Lba,
  IN UINT32* Buf,
  IN UINTN   Size
  )
{
  UINT32  Timeout;
  UINTN   Base;
  UINT32  *Data;
  UINT32  BlockSize;
  UINT32  BlockCnt;
  UINT32  Status;

  Timeout   = 0;
  Base      = BmParams.RegBase;
  Data      = Buf;
  BlockSize = 0;
  BlockCnt  = 0;
  Status    = 0;

  if (BmParams.Flags & SD_USE_PIO) {
    BlockSize = MmioRead16 (Base + SDHCI_BLOCK_SIZE);
    BlockCnt = Size / BlockSize;
    BlockSize /= 4;

    for (INT32 j = 0; j < BlockSize; j++) {
      MmioWrite32 (Base + SDHCI_BUF_DATA_R, *(Data++));
    }

    for (INT32 I = 0; I < BlockCnt-1; ) {
      Status = MmioRead16 (Base + SDHCI_INT_STATUS);
      if ((Status & SDHCI_INT_BUF_WR_READY) &&
          (MmioRead32 (Base + SDHCI_PSTATE) &
          SDHCI_BUF_WR_ENABLE)) {
        MmioWrite16 (Base + SDHCI_INT_STATUS, SDHCI_INT_BUF_WR_READY);
        for (INT32 j = 0; j < BlockSize; j++) {
          MmioWrite32 (Base + SDHCI_BUF_DATA_R, *(Data++));
        }

        Timeout = 0;
        I++;
      } else {
        gBS->Stall (1);
        Timeout++;
      }

      if (Timeout >= 10000000) {
        DEBUG ((DEBUG_INFO, "%a:sdhci write data Timeout\n", __func__));
        goto Timeout;
      }
    }

    Timeout = 0;
    while (1) {
      Status = MmioRead16 (Base + SDHCI_INT_STATUS);
      if (Status & SDHCI_INT_XFER_COMPLETE) {
        MmioWrite16 (Base + SDHCI_INT_STATUS,
                Status | SDHCI_INT_XFER_COMPLETE);

        return EFI_SUCCESS;
      } else {
        gBS->Stall (1);
        Timeout++;
      }

      if (Timeout >= 10000) {
        DEBUG ((DEBUG_INFO, "%a:wait xfer complete Timeout\n", __func__));
        goto Timeout;
      }
    }
  } else
    return EFI_SUCCESS;

Timeout:
  return EFI_TIMEOUT;
}

#define  SDHCI_CLOCK_CARD_EN      	BIT2
#define  SDHCI_CLOCK_INT_STABLE		BIT1
#define  SDHCI_CLOCK_INT_EN		BIT0
VOID
DisableCardClk (
  VOID
  )
{
  UINTN  Base = BmParams.RegBase;
  UINT32 Clk;

  /* Reset SD Clock Enable */
  Clk = MmioRead16 (Base + SDHCI_CLK_CTRL);
  Clk &= ~SDHCI_CLOCK_CARD_EN;
  MmioWrite16 (Base + SDHCI_CLK_CTRL, Clk);
}

VOID
EnableCardClk (
  VOID
  )
{
  UINTN  Base = BmParams.RegBase;
  UINT32 Val, Count = 0;

  Val = MmioRead16 (Base + SDHCI_CLK_CTRL);
  Val |= SDHCI_CLOCK_INT_EN;
  MmioWrite16 (Base + SDHCI_CLK_CTRL, Val);

  while(1) {
    Count++;
    Val = MmioRead16 (Base + SDHCI_CLK_CTRL);
    if (Val & SDHCI_CLOCK_INT_STABLE )
      break;
    if ( Count > 15000 ) {
      DEBUG((DEBUG_INFO, "%a::%d Internal clock never stabilised\n",__func__,__LINE__));
      return;
    }
    MicroSecondDelay(10);
  }

  Val |= SDHCI_CLOCK_CARD_EN;
  MmioWrite16 (Base + SDHCI_CLK_CTRL, Val);
  MicroSecondDelay (100);
}


#define  SDHCI_DIV_MASK			0xFF
#define  SDHCI_DIVIDER_SHIFT		8
#define  SDHCI_DIV_HI_MASK		0x300
#define  SDHCI_DIV_MASK_LEN		8
#define  SDHCI_DIVIDER_HI_SHIFT		6
#define  SDHCI_CLOCK_PLL_EN		BIT3

#define PHY_UPDATE_DELAY_CODE     BIT4
#define PHY_CLK_MAX_DELAY_MASK    0x7F
VOID
SdConfPhyDelay (
  VOID
  )
{
#if 0
  UINTN Base = BmParams.RegBase;
  UINT32 Delay = 0x55; /* u-boot DTS have this node */

  Delay &= PHY_CLK_MAX_DELAY_MASK;

  /*phy clk delay line config*/
  MmioWrite8 (Base + SDHCI_P_SDCLKDL_CNFG, PHY_UPDATE_DELAY_CODE);
  MmioWrite8 (Base + SDHCI_P_SDCLKDL_DC,   Delay);
  MmioWrite8 (Base + SDHCI_P_SDCLKDL_CNFG, 0x0);
#endif
}

#define PHY_PAD_RXSEL_0         0x0
#define PHY_PAD_RXSEL_1         0x1
VOID
SdConfPhy (
  VOID
  )
{
  UINTN Base = BmParams.RegBase;
  UINT32 Drv, DriveImpedance = 0xee; /* convert drive impedance ohm = 33 ohm */

  Drv = DriveImpedance << PHY_CNFG_PAD_SP;

  DisableCardClk ();

  /* reset phy,config phy's pad */
  MmioWrite32 (Base + SDHCI_P_PHY_CNFG, Drv | (~(1 << PHY_CNFG_PHY_RSTN)));

  // Set PAD_SN PAD_SP
  MmioWrite32 (Base + SDHCI_P_PHY_CNFG,
          (1 << PHY_CNFG_PHY_PWRGOOD) | (0x9 << PHY_CNFG_PAD_SP) | (0x8 << PHY_CNFG_PAD_SN));

  // Set CMDPAD
  MmioWrite16 (Base + SDHCI_P_CMDPAD_CNFG,
          (0x2 << PAD_CNFG_RXSEL) | (1 << PAD_CNFG_WEAKPULL_EN) |
          (0x3 << PAD_CNFG_TXSLEW_CTRL_P) | (0x2 << PAD_CNFG_TXSLEW_CTRL_N));

  // Set DATAPAD
  MmioWrite16 (Base + SDHCI_P_DATPAD_CNFG,
          (0x2 << PAD_CNFG_RXSEL) | (1 << PAD_CNFG_WEAKPULL_EN) |
          (0x3 << PAD_CNFG_TXSLEW_CTRL_P) | (0x2 << PAD_CNFG_TXSLEW_CTRL_N));

  // Set CLKPAD
  MmioWrite16 (Base + SDHCI_P_CLKPAD_CNFG,
          (0x2 << PAD_CNFG_RXSEL) | (0x3 << PAD_CNFG_TXSLEW_CTRL_P) | (0x2 << PAD_CNFG_TXSLEW_CTRL_N));

  // Set STB_PAD
  MmioWrite16 (Base + SDHCI_P_STBPAD_CNFG,
          (0x2 << PAD_CNFG_RXSEL) | (0x2 << PAD_CNFG_WEAKPULL_EN) |
          (0x3 << PAD_CNFG_TXSLEW_CTRL_P) | (0x2 << PAD_CNFG_TXSLEW_CTRL_N));

  // Set RSTPAD
  MmioWrite16 (Base + SDHCI_P_RSTNPAD_CNFG,
          (0x2 << PAD_CNFG_RXSEL) | (1 << PAD_CNFG_WEAKPULL_EN) |
          (0x3 << PAD_CNFG_TXSLEW_CTRL_P) | (0x2 << PAD_CNFG_TXSLEW_CTRL_N));

  // Set SDCLKDL_CNFG, EXTDLY_EN = 1, fix delay
  MmioWrite8 (Base + SDHCI_P_SDCLKDL_CNFG, (1 << SDCLKDL_CNFG_EXTDLY_EN));

  // Set SMPLDL_CNFG, Bypass
  MmioWrite8 (Base + SDHCI_P_SMPLDL_CNFG, (1 << SMPLDL_CNFG_BYPASS_EN));

  // Set ATDL_CNFG, tuning Clk not use for init
  MmioWrite8 (Base + SDHCI_P_ATDL_CNFG, (2 << ATDL_CNFG_INPSEL_CNFG));

  SdConfPhyDelay ();
  
  MmioWrite32 (Base + SDHCI_P_PHY_CNFG, Drv | (1 << PHY_CNFG_PHY_RSTN));

  EnableCardClk ();

}

#define SDHCI_CTRL_TUNED_CLK		0x0080
#define SW_TUNE_ENABLE			BIT4
#define VENDOR_AT_CTRL_R		0x540
#define VENDOR_AT_SATA_R		0x544
VOID
SdCardTuning (
  VOID
  )
{
  UINTN Base = BmParams.RegBase;
  UINT32 Ctrl, Val;
  //INT32 Ret = 0;

  Ctrl = MmioRead16 (Base + SDHCI_HOST_CONTROL2);
  Ctrl &= ~SDHCI_CTRL_TUNED_CLK;
  MmioWrite16 (Base + SDHCI_HOST_CONTROL2, Ctrl);

  Val = MmioRead16 (Base + VENDOR_AT_CTRL_R);
  Val |= SW_TUNE_ENABLE;
  MmioWrite16 (Base + VENDOR_AT_CTRL_R, Val);
  MmioWrite16 (Base + VENDOR_AT_SATA_R, 0x0);

  MmioWrite16 (Base + SDHCI_CMD_DATA, 0x0);

  //ret = eswin_sdhci_phase_code_tuning(host, opcode);

}
#define HSP_IO_MEM     0x50440000;
VOID
SdPhyPowerOn (
  VOID
  )
{
  UINTN Base = BmParams.RegBase;
  UINTN HspBase = HSP_IO_MEM;
  INT32 RetryCount = 100;
  INT32 Ret = 0;

  /*CONFIGURE IN HSPTOP, VOLTAGE*/
  MmioWrite32 (HspBase + 0x608, 0x10010101);
  MmioWrite32 (HspBase + 0x60C, 0x1       );
  MmioWrite32 (HspBase + 0xB08, 0x2000000 );

  /* reset sd */
  MmioWrite8 (Base + SDHCI_SOFTWARE_RESET, 0x7);
  
  MmioWrite16 (Base + 0x508, 0x2);

  /* SDHCI_PWR_CONTROL */
  MmioWrite8 (Base + SDHCI_PWR_CONTROL, 0xF);

  /* SDHCI_HOST_CONTROL2 */
  MmioWrite16 (Base + SDHCI_HOST_CONTROL2, 0x0);

  MmioWrite16 (Base + 0x52C, 0xC);

  MmioWrite8 (Base + 0x31C, 0x0);
  MmioWrite8 (Base + 0x52D, 0x0);
  MmioWrite8 (Base + 0x320, 0x8);
  MmioWrite8 (Base + 0x321, 0x8);

  // Wait for the PHY power on ready
  while(RetryCount--) {
	Ret = MmioRead32 (Base + SDHCI_P_PHY_CNFG);
	if ( Ret == (1 << PHY_CNFG_PHY_PWRGOOD) ) {
	    DEBUG ((DEBUG_INFO, "%a: PHY power on ready\n", __func__));
	    break;
	}
	else
	    gBS->Stall (10000);
  }
}

#define  SDHCI_POWER_330		0x0E
#define  SDHCI_POWER_ON			0x01
STATIC
VOID
SdHwInit (
  VOID
  )
{
  UINTN Base = BmParams.RegBase;

  /* reset data & Cmd */
  MmioWrite8 (Base + SDHCI_SOFTWARE_RESET, 0x6);

  /* init common parameters */

  /* sdhci_set_power */	
  MmioWrite8 (Base + SDHCI_PWR_CONTROL, SDHCI_POWER_330 | SDHCI_POWER_ON);
  MmioWrite8 (Base + SDHCI_TOUT_CTRL, 0xe);  // for TMCLK 50Khz
  MmioWrite16 (Base + SDHCI_HOST_CONTROL2,
          MmioRead16 (Base + SDHCI_HOST_CONTROL2) | 1 << 11);  // set cmd23 support
  
  MmioWrite16 (Base + SDHCI_CLK_CTRL, MmioRead16 (Base + SDHCI_CLK_CTRL) & ~(0x1 << 5));  // divided clock Mode

  /* set host version 4 parameters */
  MmioWrite16 (Base + SDHCI_HOST_CONTROL2,
          MmioRead16 (Base + SDHCI_HOST_CONTROL2) | (1 << 12)); // set HOST_VER4_ENABLE
  if (MmioRead32 (Base + SDHCI_CAPABILITIES1) & (0x1 << 27)) {
    MmioWrite16 (Base + SDHCI_HOST_CONTROL2,
            MmioRead16 (Base + SDHCI_HOST_CONTROL2) | 0x1 << 13); // set 64bit addressing
  }

  /* if support asynchronous int */
  if (MmioRead32 (Base + SDHCI_CAPABILITIES1) & (0x1 << 29))
    MmioWrite16 (Base + SDHCI_HOST_CONTROL2,
            MmioRead16 (Base + SDHCI_HOST_CONTROL2) | (0x1 << 14)); // enable async int

  /* give some time to power down card */
  gBS->Stall (20000);

  MmioWrite16 (Base + SDHCI_HOST_CONTROL2,
          MmioRead16 (Base + SDHCI_HOST_CONTROL2) & ~(0x1 << 8)); // clr UHS2_IF_ENABLE
  MmioWrite8 (Base + SDHCI_PWR_CONTROL,
          MmioRead8 (Base + SDHCI_PWR_CONTROL) | 0x1); // set SD_BUS_PWR_VDD1
  MmioWrite16 (Base + SDHCI_HOST_CONTROL2,
          MmioRead16 (Base + SDHCI_HOST_CONTROL2) & ~0x7); // clr UHS_MODE_SEL

  SdCardTuning ();

  SdSetClk (400 * 1000);
  gBS->Stall (50000);

  EnableCardClk ();
  gBS->Stall (400); // wait for voltage ramp up time at least 74 cycle, 400us is 80 cycles for 200Khz

  MmioWrite16 (Base + SDHCI_INT_STATUS, MmioRead16 (Base + SDHCI_INT_STATUS) | (0x1 << 6));

  /* we enable all interrupt Status here for testing */
  MmioWrite16 (Base + SDHCI_INT_STATUS_EN, MmioRead16 (Base + SDHCI_INT_STATUS_EN) | 0xFFFF);
  MmioWrite16 (Base + SDHCI_ERR_INT_STATUS_EN, MmioRead16 (Base + SDHCI_ERR_INT_STATUS_EN) | 0xFFFF);

}

/**
  Initialize the SD PHY.

  This function performs the initialization of the SD PHY hardware.

**/

#define ESWIN_HSPDMA_RST_CTRL   0x5182841c
#define ESWIN_HSPDMA_SD_RST     ((0x7 << 3) | (0x7 << 6) | (1 << 17) | (1 << 18) | (1 << 21) | (1 << 22))

VOID
SdPhyInit (
  VOID
  )
{
  UINT32 *Addr;
  UINT32 RegVal;
  
  /* sw rst */
  Addr = (UINT32 *)ESWIN_HSPDMA_RST_CTRL;
  RegVal = *Addr;
  RegVal |= ESWIN_HSPDMA_SD_RST;
  *Addr = RegVal;
  
  SdPhyPowerOn ();

  SdConfPhy ();

  return;
}

/**
  Initialize the SD card.

  This function performs the initialization of the SD card hardware and settings.

  @param[in] Flags     Initialization flags.

  @retval EFI_SUCCESS  The SD card was initialized successfully.

**/
EFI_STATUS
SdInit (
  IN UINT32 Flags
)
{
  DEBUG ((DEBUG_INFO, "%a: SD Card Initializing\n",__func__ ));

  BmParams.Flags = Flags;

  SdPhyInit ();

  SdHwInit ();

  return EFI_SUCCESS;
}
