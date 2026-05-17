/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20251212 (64-bit version)
 * Copyright (c) 2000 - 2025 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of SSDT12.aml
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x000000AD (173)
 *     Revision         0x02
 *     Checksum         0x06
 *     OEM ID           "HONOR"
 *     OEM Table ID     "TseSsdt"
 *     OEM Revision     0x00001000 (4096)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20200717 (538969879)
 */
DefinitionBlock ("", "SSDT", 2, "HONOR", "TseSsdt", 0x00001000)
{
    External (_SB_.PC00, DeviceObj)
    External (ADBG, MethodObj)    // 1 Arguments
    External (PCHS, IntObj)
    External (TSEE, UnknownObj)

    Scope (\_SB.PC00)
    {
        Device (TSE)
        {
            Name (_HID, "INTC10DF")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                ADBG (Concatenate ("TSE Device Enabled = ", ToHexString (TSEE)))
                If ((TSEE == One))
                {
                    Return (0x0F)
                }

                Return (Zero)
            }
        }
    }
}

