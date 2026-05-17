/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20251212 (64-bit version)
 * Copyright (c) 2000 - 2025 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of SSDT20.aml
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x00000CB5 (3253)
 *     Revision         0x02
 *     Checksum         0xFD
 *     OEM ID           "HONOR"
 *     OEM Table ID     "UpmpSsdt"
 *     OEM Revision     0x00000000 (0)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20200717 (538969879)
 */
DefinitionBlock ("", "SSDT", 2, "HONOR", "UpmpSsdt", 0x00000000)
{
    External (_SB_.A1PL, MethodObj)    // 0 Arguments
    External (_SB_.A1UP, MethodObj)    // 0 Arguments
    External (_SB_.A2PL, MethodObj)    // 0 Arguments
    External (_SB_.A2UP, MethodObj)    // 0 Arguments
    External (_SB_.A3PL, MethodObj)    // 0 Arguments
    External (_SB_.A3UP, MethodObj)    // 0 Arguments
    External (_SB_.A5PL, MethodObj)    // 0 Arguments
    External (_SB_.A5UP, MethodObj)    // 0 Arguments
    External (_SB_.A6PL, MethodObj)    // 0 Arguments
    External (_SB_.A6UP, MethodObj)    // 0 Arguments
    External (_SB_.A7PL, MethodObj)    // 0 Arguments
    External (_SB_.A7UP, MethodObj)    // 0 Arguments
    External (_SB_.A8PL, MethodObj)    // 0 Arguments
    External (_SB_.A8UP, MethodObj)    // 0 Arguments
    External (_SB_.PC00.XHCI, DeviceObj)
    External (_SB_.PC00.XHCI.RHUB.HS01, DeviceObj)
    External (_SB_.PC00.XHCI.RHUB.HS02, DeviceObj)
    External (_SB_.PC00.XHCI.RHUB.HS03, DeviceObj)
    External (_SB_.PC00.XHCI.RHUB.HS04, DeviceObj)
    External (_SB_.PC00.XHCI.RHUB.HS05, DeviceObj)
    External (_SB_.PC00.XHCI.RHUB.HS06, DeviceObj)
    External (_SB_.PC00.XHCI.RHUB.HS07, DeviceObj)
    External (_SB_.PC00.XHCI.RHUB.HS08, DeviceObj)
    External (_SB_.PC00.XHCI.RHUB.SS01, DeviceObj)
    External (_SB_.PC00.XHCI.RHUB.SS02, DeviceObj)
    External (_SB_.TPLD, MethodObj)    // 2 Arguments
    External (_SB_.TUPC, MethodObj)    // 3 Arguments
    External (ADBG, MethodObj)    // 1 Arguments

    OperationRegion (XHNV, SystemMemory, 0x6FDC1000, 0x0078)
    Field (XHNV, AnyAcc, Lock, Preserve)
    {
        A1GP,   8, 
        A2GP,   8, 
        A3GP,   8, 
        A4GP,   8, 
        A5GP,   8, 
        A6GP,   8, 
        A7GP,   8, 
        A8GP,   8, 
        A9GP,   8, 
        AAGP,   8, 
        ABGP,   8, 
        ACGP,   8, 
        ADGP,   8, 
        AEGP,   8, 
        A1VS,   8, 
        A2VS,   8, 
        A3VS,   8, 
        A4VS,   8, 
        A5VS,   8, 
        A6VS,   8, 
        A7VS,   8, 
        A8VS,   8, 
        A9VS,   8, 
        AAVS,   8, 
        ABVS,   8, 
        ACVS,   8, 
        ADVS,   8, 
        AEVS,   8, 
        A1CN,   8, 
        A2CN,   8, 
        A3CN,   8, 
        A4CN,   8, 
        A5CN,   8, 
        A6CN,   8, 
        A7CN,   8, 
        A8CN,   8, 
        A9CN,   8, 
        AACN,   8, 
        ABCN,   8, 
        ACCN,   8, 
        ADCN,   8, 
        AECN,   8, 
        A1TP,   8, 
        A2TP,   8, 
        A3TP,   8, 
        A4TP,   8, 
        A5TP,   8, 
        A6TP,   8, 
        A7TP,   8, 
        A8TP,   8, 
        A9TP,   8, 
        AATP,   8, 
        ABTP,   8, 
        ACTP,   8, 
        ADTP,   8, 
        AETP,   8, 
        A1CP,   8, 
        A2CP,   8, 
        A3CP,   8, 
        A4CP,   8, 
        A5CP,   8, 
        A6CP,   8, 
        A7CP,   8, 
        A8CP,   8, 
        A9CP,   8, 
        AACP,   8, 
        ABCP,   8, 
        ACCP,   8, 
        ADCP,   8, 
        AECP,   8, 
        B1GP,   8, 
        B2GP,   8, 
        B3GP,   8, 
        B4GP,   8, 
        B5GP,   8, 
        B6GP,   8, 
        B7GP,   8, 
        B8GP,   8, 
        B9GP,   8, 
        BAGP,   8, 
        B1VS,   8, 
        B2VS,   8, 
        B3VS,   8, 
        B4VS,   8, 
        B5VS,   8, 
        B6VS,   8, 
        B7VS,   8, 
        B8VS,   8, 
        B9VS,   8, 
        BAVS,   8, 
        B1CN,   8, 
        B2CN,   8, 
        B3CN,   8, 
        B4CN,   8, 
        B5CN,   8, 
        B6CN,   8, 
        B7CN,   8, 
        B8CN,   8, 
        B9CN,   8, 
        BACN,   8, 
        B1TP,   8, 
        B2TP,   8, 
        B3TP,   8, 
        B4TP,   8, 
        B5TP,   8, 
        B6TP,   8, 
        B7TP,   8, 
        B8TP,   8, 
        B9TP,   8, 
        BATP,   8, 
        B1CP,   8, 
        B2CP,   8, 
        B3CP,   8, 
        B4CP,   8, 
        B5CP,   8, 
        B6CP,   8, 
        B7CP,   8, 
        B8CP,   8, 
        B9CP,   8, 
        BACP,   8
    }

    If (CondRefOf (ADBG))
    {
        ADBG ("[USB PORT MAP SSDT][AcpiTableEntry]")
    }

    If (CondRefOf (\_SB.PC00.XHCI.RHUB.HS01))
    {
        Scope (\_SB.PC00.XHCI.RHUB.HS01)
        {
            Method (_UPC, 0, Serialized)  // _UPC: USB Port Capabilities
            {
                If (CondRefOf (\_SB.A1UP))
                {
                    Local0 = A1UP ()
                    If ((DerefOf (Local0 [Zero]) == One))
                    {
                        Return (DerefOf (Local0 [One]))
                    }
                }

                Return (\_SB.TUPC (A1CN, A1TP, A1CP))
            }

            Method (_PLD, 0, Serialized)  // _PLD: Physical Location of Device
            {
                If (CondRefOf (\_SB.A1PL))
                {
                    Local0 = A1PL ()
                    If ((DerefOf (Local0 [Zero]) == One))
                    {
                        Return (DerefOf (Local0 [One]))
                    }
                }

                Return (\_SB.TPLD (A1VS, A1GP))
            }
        }
    }

    If (CondRefOf (\_SB.PC00.XHCI.RHUB.HS02))
    {
        Scope (\_SB.PC00.XHCI.RHUB.HS02)
        {
            Method (_UPC, 0, Serialized)  // _UPC: USB Port Capabilities
            {
                If (CondRefOf (\_SB.A2UP))
                {
                    Local0 = A2UP ()
                    If ((DerefOf (Local0 [Zero]) == One))
                    {
                        Return (DerefOf (Local0 [One]))
                    }
                }

                Return (\_SB.TUPC (A2CN, A2TP, A2CP))
            }

            Method (_PLD, 0, Serialized)  // _PLD: Physical Location of Device
            {
                If (CondRefOf (\_SB.A2PL))
                {
                    Local0 = A2PL ()
                    If ((DerefOf (Local0 [Zero]) == One))
                    {
                        Return (DerefOf (Local0 [One]))
                    }
                }

                Return (\_SB.TPLD (A2VS, A2GP))
            }
        }
    }

    If (CondRefOf (\_SB.PC00.XHCI.RHUB.HS03))
    {
        Scope (\_SB.PC00.XHCI.RHUB.HS03)
        {
            Method (_UPC, 0, Serialized)  // _UPC: USB Port Capabilities
            {
                If (CondRefOf (\_SB.A3UP))
                {
                    Local0 = A3UP ()
                    If ((DerefOf (Local0 [Zero]) == One))
                    {
                        Return (DerefOf (Local0 [One]))
                    }
                }

                Return (\_SB.TUPC (A3CN, A3TP, A3CP))
            }

            Method (_PLD, 0, Serialized)  // _PLD: Physical Location of Device
            {
                If (CondRefOf (\_SB.A3PL))
                {
                    Local0 = A3PL ()
                    If ((DerefOf (Local0 [Zero]) == One))
                    {
                        Return (DerefOf (Local0 [One]))
                    }
                }

                Return (\_SB.TPLD (A3VS, A3GP))
            }
        }
    }

    If (CondRefOf (\_SB.PC00.XHCI.RHUB.HS04))
    {
        Scope (\_SB.PC00.XHCI.RHUB.HS04)
        {
            Name (_UPC, Package (0x04)  // _UPC: USB Port Capabilities
            {
                0xFF, 
                Zero, 
                Zero, 
                Zero
            })
            Method (_PLD, 0, Serialized)  // _PLD: Physical Location of Device
            {
                Name (PCKG, Package (0x01)
                {
                    Buffer (0x14){}
                })
                CreateField (DerefOf (PCKG [Zero]), Zero, 0x07, REV)
                CreateField (DerefOf (PCKG [Zero]), 0x07, One, RGB)
                CreateField (DerefOf (PCKG [Zero]), 0x40, One, VISI)
                CreateField (DerefOf (PCKG [Zero]), 0x42, One, LIDP)
                CreateField (DerefOf (PCKG [Zero]), 0x43, 0x03, PANS)
                CreateField (DerefOf (PCKG [Zero]), 0x46, 0x02, VERP)
                CreateField (DerefOf (PCKG [Zero]), 0x80, 0x20, VAHO)
                REV = 0x02
                RGB = One
                VISI = Zero
                LIDP = One
                PANS = 0x04
                VERP = Zero
                VAHO = 0xFFFFFFFF
                Return (PCKG) /* \_SB_.PC00.XHCI.RHUB.HS04._PLD.PCKG */
            }

            Device (FCAM)
            {
                Name (_ADR, 0x04)  // _ADR: Address
                Name (_UPC, Package (0x04)  // _UPC: USB Port Capabilities
                {
                    0xFF, 
                    Zero, 
                    Zero, 
                    Zero
                })
                Method (_PLD, 0, Serialized)  // _PLD: Physical Location of Device
                {
                    Name (PCKG, Package (0x01)
                    {
                        Buffer (0x14){}
                    })
                    CreateField (DerefOf (PCKG [Zero]), Zero, 0x07, REV)
                    CreateField (DerefOf (PCKG [Zero]), 0x07, One, RGB)
                    CreateField (DerefOf (PCKG [Zero]), 0x40, One, VISI)
                    CreateField (DerefOf (PCKG [Zero]), 0x42, One, LIDP)
                    CreateField (DerefOf (PCKG [Zero]), 0x43, 0x03, PANS)
                    CreateField (DerefOf (PCKG [Zero]), 0x46, 0x02, VERP)
                    CreateField (DerefOf (PCKG [Zero]), 0x80, 0x20, VAHO)
                    REV = 0x02
                    RGB = One
                    VISI = Zero
                    LIDP = One
                    PANS = 0x04
                    VERP = Zero
                    VAHO = 0xFFFFFFFF
                    Return (PCKG) /* \_SB_.PC00.XHCI.RHUB.HS04.FCAM._PLD.PCKG */
                }
            }
        }
    }

    If (CondRefOf (\_SB.PC00.XHCI.RHUB.HS05))
    {
        Scope (\_SB.PC00.XHCI.RHUB.HS05)
        {
            Method (_UPC, 0, Serialized)  // _UPC: USB Port Capabilities
            {
                If (CondRefOf (\_SB.A5UP))
                {
                    Local0 = A5UP ()
                    If ((DerefOf (Local0 [Zero]) == One))
                    {
                        Return (DerefOf (Local0 [One]))
                    }
                }

                Return (\_SB.TUPC (A5CN, A5TP, A5CP))
            }

            Method (_PLD, 0, Serialized)  // _PLD: Physical Location of Device
            {
                If (CondRefOf (\_SB.A5PL))
                {
                    Local0 = A5PL ()
                    If ((DerefOf (Local0 [Zero]) == One))
                    {
                        Return (DerefOf (Local0 [One]))
                    }
                }

                Return (\_SB.TPLD (A5VS, A5GP))
            }
        }
    }

    If (CondRefOf (\_SB.PC00.XHCI.RHUB.HS06))
    {
        Scope (\_SB.PC00.XHCI.RHUB.HS06)
        {
            Method (_UPC, 0, Serialized)  // _UPC: USB Port Capabilities
            {
                If (CondRefOf (\_SB.A6UP))
                {
                    Local0 = A6UP ()
                    If ((DerefOf (Local0 [Zero]) == One))
                    {
                        Return (DerefOf (Local0 [One]))
                    }
                }

                Return (\_SB.TUPC (A6CN, A6TP, A6CP))
            }

            Method (_PLD, 0, Serialized)  // _PLD: Physical Location of Device
            {
                If (CondRefOf (\_SB.A6PL))
                {
                    Local0 = A6PL ()
                    If ((DerefOf (Local0 [Zero]) == One))
                    {
                        Return (DerefOf (Local0 [One]))
                    }
                }

                Return (\_SB.TPLD (A6VS, A6GP))
            }
        }
    }

    If (CondRefOf (\_SB.PC00.XHCI.RHUB.HS07))
    {
        Scope (\_SB.PC00.XHCI.RHUB.HS07)
        {
            Method (_UPC, 0, Serialized)  // _UPC: USB Port Capabilities
            {
                If (CondRefOf (\_SB.A7UP))
                {
                    Local0 = A7UP ()
                    If ((DerefOf (Local0 [Zero]) == One))
                    {
                        Return (DerefOf (Local0 [One]))
                    }
                }

                Return (\_SB.TUPC (A7CN, A7TP, A7CP))
            }

            Method (_PLD, 0, Serialized)  // _PLD: Physical Location of Device
            {
                If (CondRefOf (\_SB.A7PL))
                {
                    Local0 = A7PL ()
                    If ((DerefOf (Local0 [Zero]) == One))
                    {
                        Return (DerefOf (Local0 [One]))
                    }
                }

                Return (\_SB.TPLD (A7VS, A7GP))
            }
        }
    }

    If (CondRefOf (\_SB.PC00.XHCI.RHUB.HS08))
    {
        Scope (\_SB.PC00.XHCI.RHUB.HS08)
        {
            Method (_UPC, 0, Serialized)  // _UPC: USB Port Capabilities
            {
                If (CondRefOf (\_SB.A8UP))
                {
                    Local0 = A8UP ()
                    If ((DerefOf (Local0 [Zero]) == One))
                    {
                        Return (DerefOf (Local0 [One]))
                    }
                }

                Return (\_SB.TUPC (A8CN, A8TP, A8CP))
            }

            Method (_PLD, 0, Serialized)  // _PLD: Physical Location of Device
            {
                If (CondRefOf (\_SB.A8PL))
                {
                    Local0 = A8PL ()
                    If ((DerefOf (Local0 [Zero]) == One))
                    {
                        Return (DerefOf (Local0 [One]))
                    }
                }

                Return (\_SB.TPLD (A8VS, A8GP))
            }
        }
    }

    If (CondRefOf (\_SB.PC00.XHCI.RHUB.SS01))
    {
        Scope (\_SB.PC00.XHCI.RHUB.SS01)
        {
            Method (_UPC, 0, Serialized)  // _UPC: USB Port Capabilities
            {
                Return (\_SB.TUPC (B1CN, B1TP, B1CP))
            }

            Method (_PLD, 0, Serialized)  // _PLD: Physical Location of Device
            {
                Return (\_SB.TPLD (B1VS, B1GP))
            }
        }
    }

    If (CondRefOf (\_SB.PC00.XHCI.RHUB.SS02))
    {
        Scope (\_SB.PC00.XHCI.RHUB.SS02)
        {
            Method (_UPC, 0, Serialized)  // _UPC: USB Port Capabilities
            {
                Return (\_SB.TUPC (B2CN, B2TP, B2CP))
            }

            Method (_PLD, 0, Serialized)  // _PLD: Physical Location of Device
            {
                Return (\_SB.TPLD (B2VS, B2GP))
            }
        }
    }

    If (CondRefOf (ADBG))
    {
        ADBG ("[USB PORT MAP SSDT][AcpiTableExit]")
    }
}

