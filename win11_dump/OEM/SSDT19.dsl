/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20251212 (64-bit version)
 * Copyright (c) 2000 - 2025 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of SSDT19.aml
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x000010EB (4331)
 *     Revision         0x02
 *     Checksum         0x05
 *     OEM ID           "HONOR"
 *     OEM Table ID     "UcsiTabl"
 *     OEM Revision     0x00001000 (4096)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20200717 (538969879)
 */
DefinitionBlock ("", "SSDT", 2, "HONOR", "UcsiTabl", 0x00001000)
{
    External (_SB_.PC00.LPCB.H_EC.RPOI, MethodObj)    // 0 Arguments
    External (_SB_.PC00.LPCB.H_EC.WOPM, MethodObj)    // 1 Arguments
    External (_SB_.PC00.XHCI.RHUB, DeviceObj)
    External (_SB_.TPLD, MethodObj)    // 2 Arguments
    External (_SB_.TUPC, MethodObj)    // 3 Arguments
    External (ADBG, MethodObj)    // 1 Arguments
    External (UCMS, UnknownObj)
    External (UDRS, UnknownObj)
    External (USTC, UnknownObj)
    External (XDCE, UnknownObj)

    Debug = "[UcsiTabl SSDT][AcpiTableEntry]"
    Debug = Timer
    If (CondRefOf (ADBG))
    {
        ADBG ("[UcsiTabl SSDT][AcpiTableEntry]")
    }

    OperationRegion (UPNV, SystemMemory, 0x6FDC3000, 0x0042)
    Field (UPNV, AnyAcc, Lock, Preserve)
    {
        UBCB,   32, 
        TCCM,   16, 
        TP1U,   8, 
        TP2U,   8, 
        TP3U,   8, 
        TP4U,   8, 
        TP5U,   8, 
        TP6U,   8, 
        TP7U,   8, 
        TP8U,   8, 
        TP9U,   8, 
        TPAU,   8, 
        CRP1,   8, 
        CRP2,   8, 
        CRP3,   8, 
        CRP4,   8, 
        CRP5,   8, 
        CRP6,   8, 
        CRP7,   8, 
        CRP8,   8, 
        CRP9,   8, 
        CRPA,   8, 
        CRV1,   8, 
        CRV2,   8, 
        CRV3,   8, 
        CRV4,   8, 
        CRV5,   8, 
        CRV6,   8, 
        CRV7,   8, 
        CRV8,   8, 
        CRV9,   8, 
        CRVA,   8, 
        CRC1,   8, 
        CRC2,   8, 
        CRC3,   8, 
        CRC4,   8, 
        CRC5,   8, 
        CRC6,   8, 
        CRC7,   8, 
        CRC8,   8, 
        CRC9,   8, 
        CRCA,   8, 
        CRT1,   8, 
        CRT2,   8, 
        CRT3,   8, 
        CRT4,   8, 
        CRT5,   8, 
        CRT6,   8, 
        CRT7,   8, 
        CRT8,   8, 
        CRT9,   8, 
        CRTA,   8, 
        CRB1,   8, 
        CRB2,   8, 
        CRB3,   8, 
        CRB4,   8, 
        CRB5,   8, 
        CRB6,   8, 
        CRB7,   8, 
        CRB8,   8, 
        CRB9,   8, 
        CRBA,   8
    }

    If (CondRefOf (ADBG))
    {
        ADBG (Concatenate ("TCCM:", ToHexString (TCCM)))
    }

    If (CondRefOf (ADBG))
    {
        ADBG (Concatenate ("UCMS:", ToHexString (UCMS)))
    }

    Scope (\_SB)
    {
        Device (UBTC)
        {
            Name (_HID, EisaId ("USBC000"))  // _HID: Hardware ID
            Name (_CID, EisaId ("PNP0CA0"))  // _CID: Compatible ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_DDN, "USB Type C")  // _DDN: DOS Device Name
            Method (MGBS, 1, Serialized)
            {
                If ((UCMS >= 0x02))
                {
                    Local0 = 0x0100
                }
                ElseIf ((Arg0 == One))
                {
                    Local0 = 0x10
                }
                Else
                {
                    Local0 = 0x14
                }

                If (CondRefOf (ADBG))
                {
                    ADBG (Concatenate ("USBC.MGBS", ToHexString (Local0)))
                }

                Return (Local0)
            }

            Method (UCMI, 0, Serialized)
            {
                Local0 = 0x10
                Local1 = (UBCB + Local0)
                If (CondRefOf (ADBG))
                {
                    ADBG (Concatenate ("UBTC", ToHexString (UBCB)))
                }

                If (CondRefOf (ADBG))
                {
                    ADBG (Concatenate ("UCSI Input Data Structure offset:", ToHexString (Local1)))
                }

                Return (Local1)
            }

            Method (UCMO, 0, Serialized)
            {
                Local0 = MGBS (Zero)
                Local0 = (Local0 + 0x10)
                Local1 = (UBCB + Local0)
                If (CondRefOf (ADBG))
                {
                    ADBG (Concatenate ("UCSI Output Data Structure offset:", ToHexString (Local1)))
                }

                Return (Local1)
            }

            Name (CRS, ResourceTemplate ()
            {
                Memory32Fixed (ReadWrite,
                    0x00000000,         // Address Base
                    0x00001000,         // Address Length
                    _Y00)
            })
            OperationRegion (USBC, SystemMemory, UBCB, 0x10)
            Field (USBC, ByteAcc, Lock, Preserve)
            {
                VER1,   8, 
                VER2,   8, 
                RSV1,   8, 
                RSV2,   8, 
                CCI0,   8, 
                CCI1,   8, 
                CCI2,   8, 
                CCI3,   8, 
                CTL0,   8, 
                CTL1,   8, 
                CTL2,   8, 
                CTL3,   8, 
                CTL4,   8, 
                CTL5,   8, 
                CTL6,   8, 
                CTL7,   8
            }

            OperationRegion (USCI, SystemMemory, UCMI (), MGBS (Zero))
            Field (USCI, ByteAcc, Lock, Preserve)
            {
                MI00,   8, 
                MI01,   8, 
                MI02,   8, 
                MI03,   8, 
                MI04,   8, 
                MI05,   8, 
                MI06,   8, 
                MI07,   8, 
                MI08,   8, 
                MI09,   8, 
                MI0A,   8, 
                MI0B,   8, 
                MI0C,   8, 
                MI0D,   8, 
                MI0E,   8, 
                MI0F,   8, 
                MI10,   8, 
                MI11,   8, 
                MI12,   8, 
                MI13,   8
            }

            OperationRegion (UCSO, SystemMemory, UCMO (), MGBS (One))
            Field (UCSO, ByteAcc, Lock, Preserve)
            {
                MGO0,   8, 
                MGO1,   8, 
                MGO2,   8, 
                MGO3,   8, 
                MGO4,   8, 
                MGO5,   8, 
                MGO6,   8, 
                MGO7,   8, 
                MGO8,   8, 
                MGO9,   8, 
                MGOA,   8, 
                MGOB,   8, 
                MGOC,   8, 
                MGOD,   8, 
                MGOE,   8, 
                MGOF,   8
            }

            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                CreateDWordField (CRS, \_SB.UBTC._Y00._BAS, CBAS)  // _BAS: Base Address
                CBAS = UBCB /* \UBCB */
                Return (CRS) /* \_SB_.UBTC.CRS_ */
            }

            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (((USTC == One) && (TCCM != Zero)))
                {
                    If ((UCMS != Zero))
                    {
                        Return (0x0F)
                    }
                }

                Return (Zero)
            }

            If ((((TCCM & One) != Zero) && ((
                TP1U != Zero) && ((CRT1 >= 0x08) && (CRT1 <= 0x0A)))))
            {
                If (CondRefOf (ADBG))
                {
                    ADBG ("[UCSI] CR01")
                }

                Device (CR01)
                {
                    Name (_ADR, Zero)  // _ADR: Address
                    Method (_PLD, 0, Serialized)  // _PLD: Physical Location of Device
                    {
                        Return (\_SB.TPLD (CRV1, CRP1))
                    }

                    Method (_UPC, 0, Serialized)  // _UPC: USB Port Capabilities
                    {
                        Return (\_SB.TUPC (CRC1, CRT1, CRB1))
                    }
                }
            }

            If ((((TCCM & 0x02) != Zero) && ((
                TP2U != Zero) && ((CRT2 >= 0x08) && (CRT2 <= 0x0A)))))
            {
                If (CondRefOf (ADBG))
                {
                    ADBG ("[UCSI] CR02")
                }

                Device (CR02)
                {
                    Name (_ADR, One)  // _ADR: Address
                    Method (_PLD, 0, Serialized)  // _PLD: Physical Location of Device
                    {
                        Return (\_SB.TPLD (CRV2, CRP2))
                    }

                    Method (_UPC, 0, Serialized)  // _UPC: USB Port Capabilities
                    {
                        Return (\_SB.TUPC (CRC2, CRT2, CRB2))
                    }
                }
            }

            If ((((TCCM & 0x04) != Zero) && ((
                TP3U != Zero) && ((CRT3 >= 0x08) && (CRT3 <= 0x0A)))))
            {
                If (CondRefOf (ADBG))
                {
                    ADBG ("[UCSI] CR03")
                }

                Device (CR03)
                {
                    Name (_ADR, 0x02)  // _ADR: Address
                    Method (_PLD, 0, Serialized)  // _PLD: Physical Location of Device
                    {
                        Return (\_SB.TPLD (CRV3, CRP3))
                    }

                    Method (_UPC, 0, Serialized)  // _UPC: USB Port Capabilities
                    {
                        Return (\_SB.TUPC (CRC3, CRT3, CRB3))
                    }
                }
            }

            If ((((TCCM & 0x08) != Zero) && ((
                TP4U != Zero) && ((CRT4 >= 0x08) && (CRT4 <= 0x0A)))))
            {
                If (CondRefOf (ADBG))
                {
                    ADBG ("[UCSI] CR04")
                }

                Device (CR04)
                {
                    Name (_ADR, 0x03)  // _ADR: Address
                    Method (_PLD, 0, Serialized)  // _PLD: Physical Location of Device
                    {
                        Return (\_SB.TPLD (CRV4, CRP4))
                    }

                    Method (_UPC, 0, Serialized)  // _UPC: USB Port Capabilities
                    {
                        Return (\_SB.TUPC (CRC4, CRT4, CRB4))
                    }
                }
            }

            If ((((TCCM & 0x10) != Zero) && ((
                TP5U != Zero) && ((CRT5 >= 0x08) && (CRT5 <= 0x0A)))))
            {
                If (CondRefOf (ADBG))
                {
                    ADBG ("[UCSI] CR05")
                }

                Device (CR05)
                {
                    Name (_ADR, 0x04)  // _ADR: Address
                    Method (_PLD, 0, Serialized)  // _PLD: Physical Location of Device
                    {
                        Return (\_SB.TPLD (CRV5, CRP5))
                    }

                    Method (_UPC, 0, Serialized)  // _UPC: USB Port Capabilities
                    {
                        Return (\_SB.TUPC (CRC5, CRT5, CRB5))
                    }
                }
            }

            If ((((TCCM & 0x20) != Zero) && ((
                TP6U != Zero) && ((CRT6 >= 0x08) && (CRT6 <= 0x0A)))))
            {
                If (CondRefOf (ADBG))
                {
                    ADBG ("[UCSI] CR06")
                }

                Device (CR06)
                {
                    Name (_ADR, 0x05)  // _ADR: Address
                    Method (_PLD, 0, Serialized)  // _PLD: Physical Location of Device
                    {
                        Return (\_SB.TPLD (CRV6, CRP6))
                    }

                    Method (_UPC, 0, Serialized)  // _UPC: USB Port Capabilities
                    {
                        Return (\_SB.TUPC (CRC6, CRT6, CRB6))
                    }
                }
            }

            If ((((TCCM & 0x40) != Zero) && ((
                TP7U != Zero) && ((CRT7 >= 0x08) && (CRT7 <= 0x0A)))))
            {
                Device (CR07)
                {
                    If (CondRefOf (ADBG))
                    {
                        ADBG ("[UCSI] CR07")
                    }

                    Name (_ADR, 0x06)  // _ADR: Address
                    Method (_PLD, 0, Serialized)  // _PLD: Physical Location of Device
                    {
                        Return (\_SB.TPLD (CRV7, CRP7))
                    }

                    Method (_UPC, 0, Serialized)  // _UPC: USB Port Capabilities
                    {
                        Return (\_SB.TUPC (CRC7, CRT7, CRB7))
                    }
                }
            }

            If ((((TCCM & 0x80) != Zero) && ((
                TP8U != Zero) && ((CRT8 >= 0x08) && (CRT8 <= 0x0A)))))
            {
                If (CondRefOf (ADBG))
                {
                    ADBG ("[UCSI] CR08")
                }

                Device (CR08)
                {
                    Name (_ADR, 0x07)  // _ADR: Address
                    Method (_PLD, 0, Serialized)  // _PLD: Physical Location of Device
                    {
                        Return (\_SB.TPLD (CRV8, CRP8))
                    }

                    Method (_UPC, 0, Serialized)  // _UPC: USB Port Capabilities
                    {
                        Return (\_SB.TUPC (CRC8, CRT8, CRB8))
                    }
                }
            }

            If ((((TCCM & 0x0100) != Zero) && ((
                TP9U != Zero) && ((CRT9 >= 0x08) && (CRT9 <= 0x0A)))))
            {
                If (CondRefOf (ADBG))
                {
                    ADBG ("[UCSI] CR09")
                }

                Device (CR09)
                {
                    Name (_ADR, 0x08)  // _ADR: Address
                    Method (_PLD, 0, Serialized)  // _PLD: Physical Location of Device
                    {
                        Return (\_SB.TPLD (CRV9, CRP9))
                    }

                    Method (_UPC, 0, Serialized)  // _UPC: USB Port Capabilities
                    {
                        Return (\_SB.TUPC (CRC9, CRT9, CRB9))
                    }
                }
            }

            If ((((TCCM & 0x0200) != Zero) && ((
                TPAU != Zero) && ((CRTA >= 0x08) && (CRTA <= 0x0A)))))
            {
                If (CondRefOf (ADBG))
                {
                    ADBG ("[UCSI] CR0A")
                }

                Device (CR0A)
                {
                    Name (_ADR, 0x09)  // _ADR: Address
                    Method (_PLD, 0, Serialized)  // _PLD: Physical Location of Device
                    {
                        Return (\_SB.TPLD (CRVA, CRPA))
                    }

                    Method (_UPC, 0, Serialized)  // _UPC: USB Port Capabilities
                    {
                        Return (\_SB.TUPC (CRCA, CRTA, CRBA))
                    }
                }
            }

            Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
            {
                Name (OPMP, Buffer (0x18){})
                If ((Arg0 == ToUUID ("6f8398c2-7ca4-11e4-ad36-631042b5008f") /* Unknown UUID */))
                {
                    Switch (ToInteger (Arg2))
                    {
                        Case (Zero)
                        {
                            Return (Buffer (One)
                            {
                                 0x3F                                             // ?
                            })
                        }
                        Case (One)
                        {
                            OPMP [Zero] = MGO0 /* \_SB_.UBTC.MGO0 */
                            OPMP [One] = MGO1 /* \_SB_.UBTC.MGO1 */
                            OPMP [0x02] = MGO2 /* \_SB_.UBTC.MGO2 */
                            OPMP [0x03] = MGO3 /* \_SB_.UBTC.MGO3 */
                            OPMP [0x04] = MGO4 /* \_SB_.UBTC.MGO4 */
                            OPMP [0x05] = MGO5 /* \_SB_.UBTC.MGO5 */
                            OPMP [0x06] = MGO6 /* \_SB_.UBTC.MGO6 */
                            OPMP [0x07] = MGO7 /* \_SB_.UBTC.MGO7 */
                            OPMP [0x08] = MGO8 /* \_SB_.UBTC.MGO8 */
                            OPMP [0x09] = MGO9 /* \_SB_.UBTC.MGO9 */
                            OPMP [0x0A] = MGOA /* \_SB_.UBTC.MGOA */
                            OPMP [0x0B] = MGOB /* \_SB_.UBTC.MGOB */
                            OPMP [0x0C] = MGOC /* \_SB_.UBTC.MGOC */
                            OPMP [0x0D] = MGOD /* \_SB_.UBTC.MGOD */
                            OPMP [0x0E] = MGOE /* \_SB_.UBTC.MGOE */
                            OPMP [0x0F] = MGOF /* \_SB_.UBTC.MGOF */
                            OPMP [0x10] = CTL0 /* \_SB_.UBTC.CTL0 */
                            OPMP [0x11] = CTL1 /* \_SB_.UBTC.CTL1 */
                            OPMP [0x12] = CTL2 /* \_SB_.UBTC.CTL2 */
                            OPMP [0x13] = CTL3 /* \_SB_.UBTC.CTL3 */
                            OPMP [0x14] = CTL4 /* \_SB_.UBTC.CTL4 */
                            OPMP [0x15] = CTL5 /* \_SB_.UBTC.CTL5 */
                            OPMP [0x16] = CTL6 /* \_SB_.UBTC.CTL6 */
                            OPMP [0x17] = CTL7 /* \_SB_.UBTC.CTL7 */
                            \_SB.PC00.LPCB.H_EC.WOPM (OPMP)
                            If (CondRefOf (ADBG))
                            {
                                ADBG ("_DSM OPM write to EC")
                            }
                        }
                        Case (0x02)
                        {
                            MI00 = DerefOf (\_SB.PC00.LPCB.H_EC.RPOI () [Zero])
                            MI01 = DerefOf (\_SB.PC00.LPCB.H_EC.RPOI () [One])
                            MI02 = DerefOf (\_SB.PC00.LPCB.H_EC.RPOI () [0x02])
                            MI03 = DerefOf (\_SB.PC00.LPCB.H_EC.RPOI () [0x03])
                            MI04 = DerefOf (\_SB.PC00.LPCB.H_EC.RPOI () [0x04])
                            MI05 = DerefOf (\_SB.PC00.LPCB.H_EC.RPOI () [0x05])
                            MI06 = DerefOf (\_SB.PC00.LPCB.H_EC.RPOI () [0x06])
                            MI07 = DerefOf (\_SB.PC00.LPCB.H_EC.RPOI () [0x07])
                            MI08 = DerefOf (\_SB.PC00.LPCB.H_EC.RPOI () [0x08])
                            MI09 = DerefOf (\_SB.PC00.LPCB.H_EC.RPOI () [0x09])
                            MI0A = DerefOf (\_SB.PC00.LPCB.H_EC.RPOI () [0x0A])
                            MI0B = DerefOf (\_SB.PC00.LPCB.H_EC.RPOI () [0x0B])
                            MI0C = DerefOf (\_SB.PC00.LPCB.H_EC.RPOI () [0x0C])
                            MI0D = DerefOf (\_SB.PC00.LPCB.H_EC.RPOI () [0x0D])
                            MI0E = DerefOf (\_SB.PC00.LPCB.H_EC.RPOI () [0x0E])
                            MI0F = DerefOf (\_SB.PC00.LPCB.H_EC.RPOI () [0x0F])
                            If ((UCMS == One))
                            {
                                CCI0 = DerefOf (\_SB.PC00.LPCB.H_EC.RPOI () [0x10])
                                CCI1 = DerefOf (\_SB.PC00.LPCB.H_EC.RPOI () [0x11])
                                CCI2 = DerefOf (\_SB.PC00.LPCB.H_EC.RPOI () [0x12])
                                CCI3 = DerefOf (\_SB.PC00.LPCB.H_EC.RPOI () [0x13])
                            }
                            Else
                            {
                                MI10 = DerefOf (\_SB.PC00.LPCB.H_EC.RPOI () [0x10])
                                MI11 = DerefOf (\_SB.PC00.LPCB.H_EC.RPOI () [0x11])
                                MI12 = DerefOf (\_SB.PC00.LPCB.H_EC.RPOI () [0x12])
                                MI13 = DerefOf (\_SB.PC00.LPCB.H_EC.RPOI () [0x13])
                                CCI0 = DerefOf (\_SB.PC00.LPCB.H_EC.RPOI () [0x14])
                                CCI1 = DerefOf (\_SB.PC00.LPCB.H_EC.RPOI () [0x15])
                                CCI2 = DerefOf (\_SB.PC00.LPCB.H_EC.RPOI () [0x16])
                                CCI3 = DerefOf (\_SB.PC00.LPCB.H_EC.RPOI () [0x17])
                            }
                        }
                        Case (0x03)
                        {
                            Return (XDCE) /* External reference */
                        }
                        Case (0x04)
                        {
                            Return (UDRS) /* External reference */
                        }
                        Case (0x05)
                        {
                            If ((UCMS >= 0x02))
                            {
                                Return (Buffer (One)
                                {
                                     0x01                                             // .
                                })
                            }
                            Else
                            {
                                Return (Buffer (One)
                                {
                                     0x00                                             // .
                                })
                            }
                        }

                    }
                }

                Return (Buffer (One)
                {
                     0x00                                             // .
                })
            }
        }
    }

    If (CondRefOf (ADBG))
    {
        ADBG ("[UcsiTabl SSDT][AcpiTableExit]")
    }

    Debug = "[UcsiTabl SSDT][AcpiTableExit]"
    Debug = Timer
}

