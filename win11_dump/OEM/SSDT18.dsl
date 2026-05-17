/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20251212 (64-bit version)
 * Copyright (c) 2000 - 2025 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of SSDT18.aml
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x00004A89 (19081)
 *     Revision         0x02
 *     Checksum         0x46
 *     OEM ID           "HONOR"
 *     OEM Table ID     "DptfTabl"
 *     OEM Revision     0x00001000 (4096)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20200717 (538969879)
 */
DefinitionBlock ("", "SSDT", 2, "HONOR", "DptfTabl", 0x00001000)
{
    External (_SB_.AAC0, FieldUnitObj)
    External (_SB_.ACRT, FieldUnitObj)
    External (_SB_.APSV, FieldUnitObj)
    External (_SB_.CBMI, FieldUnitObj)
    External (_SB_.CFGD, FieldUnitObj)
    External (_SB_.CLVL, FieldUnitObj)
    External (_SB_.DPTF.ARTG, MethodObj)    // 0 Arguments
    External (_SB_.DPTF.B1CS, MethodObj)    // 0 Arguments
    External (_SB_.DPTF.B1FC, MethodObj)    // 0 Arguments
    External (_SB_.DPTF.B1RC, MethodObj)    // 0 Arguments
    External (_SB_.DPTF.BCCE, MethodObj)    // 0 Arguments
    External (_SB_.DPTF.BMAX, MethodObj)    // 0 Arguments
    External (_SB_.DPTF.CMPP, MethodObj)    // 0 Arguments
    External (_SB_.DPTF.CTYP, MethodObj)    // 0 Arguments
    External (_SB_.DPTF.FCHG, MethodObj)    // 0 Arguments
    External (_SB_.DPTF.FNSL, MethodObj)    // 3 Arguments
    External (_SB_.DPTF.GFCE, MethodObj)    // 0 Arguments
    External (_SB_.DPTF.GFHE, MethodObj)    // 0 Arguments
    External (_SB_.DPTF.GFLE, MethodObj)    // 0 Arguments
    External (_SB_.DPTF.GFME, MethodObj)    // 0 Arguments
    External (_SB_.DPTF.GFNS, MethodObj)    // 1 Arguments
    External (_SB_.DPTF.GRBC, MethodObj)    // 0 Arguments
    External (_SB_.DPTF.GSHE, MethodObj)    // 0 Arguments
    External (_SB_.DPTF.PBOK, MethodObj)    // 1 Arguments
    External (_SB_.DPTF.PBSS, MethodObj)    // 0 Arguments
    External (_SB_.DPTF.PCCE, MethodObj)    // 0 Arguments
    External (_SB_.DPTF.PROP, MethodObj)    // 0 Arguments
    External (_SB_.DPTF.PWRT, MethodObj)    // 0 Arguments
    External (_SB_.DPTF.RBHF, MethodObj)    // 0 Arguments
    External (_SB_.DPTF.SCHG, MethodObj)    // 1 Arguments
    External (_SB_.DPTF.SCLC, MethodObj)    // 1 Arguments
    External (_SB_.DPTF.SFHE, MethodObj)    // 1 Arguments
    External (_SB_.DPTF.SFLE, MethodObj)    // 1 Arguments
    External (_SB_.DPTF.SFME, MethodObj)    // 1 Arguments
    External (_SB_.DPTF.UPPM, MethodObj)    // 1 Arguments
    External (_SB_.DPTF.UVTH, MethodObj)    // 1 Arguments
    External (_SB_.DPTF.VBNL, MethodObj)    // 0 Arguments
    External (_SB_.IETM, DeviceObj)
    External (_SB_.OSCP, IntObj)
    External (_SB_.PAGD, DeviceObj)
    External (_SB_.PAGD._PUR, PkgObj)
    External (_SB_.PAGD._STA, MethodObj)    // 0 Arguments
    External (_SB_.PC00, DeviceObj)
    External (_SB_.PC00.LPCB.H_EC, DeviceObj)
    External (_SB_.PC00.LPCB.H_EC.B1C1, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.B1CE, MethodObj)    // 0 Arguments
    External (_SB_.PC00.LPCB.H_EC.BHFI, MethodObj)    // 0 Arguments
    External (_SB_.PC00.LPCB.H_EC.BMPC, MethodObj)    // 0 Arguments
    External (_SB_.PC00.LPCB.H_EC.BNLV, MethodObj)    // 0 Arguments
    External (_SB_.PC00.LPCB.H_EC.CPDC, MethodObj)    // 1 Arguments
    External (_SB_.PC00.LPCB.H_EC.GRBE, MethodObj)    // 0 Arguments
    External (_SB_.PC00.LPCB.H_EC.RADR, MethodObj)    // 0 Arguments
    External (_SB_.PC00.LPCB.H_EC.RBPM, MethodObj)    // 0 Arguments
    External (_SB_.PC00.LPCB.H_EC.RBPV, MethodObj)    // 0 Arguments
    External (_SB_.PC00.LPCB.H_EC.RCFS, MethodObj)    // 0 Arguments
    External (_SB_.PC00.LPCB.H_EC.RCTP, MethodObj)    // 0 Arguments
    External (_SB_.PC00.LPCB.H_EC.RFCS, MethodObj)    // 0 Arguments
    External (_SB_.PC00.LPCB.H_EC.RFPM, MethodObj)    // 0 Arguments
    External (_SB_.PC00.LPCB.H_EC.RFTH, MethodObj)    // 0 Arguments
    External (_SB_.PC00.LPCB.H_EC.RFTL, MethodObj)    // 0 Arguments
    External (_SB_.PC00.LPCB.H_EC.RPBS, MethodObj)    // 0 Arguments
    External (_SB_.PC00.LPCB.H_EC.RRPT, MethodObj)    // 0 Arguments
    External (_SB_.PC00.LPCB.H_EC.RSFC, MethodObj)    // 0 Arguments
    External (_SB_.PC00.LPCB.H_EC.RSSV, MethodObj)    // 0 Arguments
    External (_SB_.PC00.LPCB.H_EC.RSTH, MethodObj)    // 0 Arguments
    External (_SB_.PC00.LPCB.H_EC.RWPP, MethodObj)    // 0 Arguments
    External (_SB_.PC00.LPCB.H_EC.SCLE, MethodObj)    // 1 Arguments
    External (_SB_.PC00.LPCB.H_EC.STSN, MethodObj)    // 1 Arguments
    External (_SB_.PC00.LPCB.H_EC.UPCR, MethodObj)    // 1 Arguments
    External (_SB_.PC00.LPCB.H_EC.UPF2, MethodObj)    // 3 Arguments
    External (_SB_.PC00.LPCB.H_EC.UPFH, MethodObj)    // 1 Arguments
    External (_SB_.PC00.LPCB.H_EC.UPFL, MethodObj)    // 1 Arguments
    External (_SB_.PC00.LPCB.H_EC.UPFP, MethodObj)    // 1 Arguments
    External (_SB_.PC00.LPCB.H_EC.UPPM, MethodObj)    // 1 Arguments
    External (_SB_.PC00.LPCB.H_EC.USTP, MethodObj)    // 4 Arguments
    External (_SB_.PC00.LPCB.LXEC, DeviceObj)
    External (_SB_.PC00.LPCB.LXEC.ABNT, FieldUnitObj)
    External (_SB_.PC00.LPCB.LXEC.CDTS, FieldUnitObj)
    External (_SB_.PC00.LPCB.LXEC.CHTS, FieldUnitObj)
    External (_SB_.PC00.LPCB.LXEC.CVTS, FieldUnitObj)
    External (_SB_.PC00.LPCB.LXEC.DDRS, FieldUnitObj)
    External (_SB_.PC00.LPCB.LXEC.DTTF, FieldUnitObj)
    External (_SB_.PC00.LPCB.LXEC.ECAV, FieldUnitObj)
    External (_SB_.PC00.LPCB.LXEC.ECMT, UnknownObj)
    External (_SB_.PC00.LPCB.LXEC.ECPU, FieldUnitObj)
    External (_SB_.PC00.LPCB.LXEC.ESVT, FieldUnitObj)
    External (_SB_.PC00.LPCB.LXEC.FVTS, FieldUnitObj)
    External (_SB_.PC00.LPCB.LXEC.ODP0, FieldUnitObj)
    External (_SB_.PC00.LPCB.LXEC.ODP1, FieldUnitObj)
    External (_SB_.PC00.LPCB.LXEC.ODP2, FieldUnitObj)
    External (_SB_.PC00.LPCB.LXEC.ODP3, FieldUnitObj)
    External (_SB_.PC00.LPCB.LXEC.ODP4, FieldUnitObj)
    External (_SB_.PC00.LPCB.LXEC.ODP5, FieldUnitObj)
    External (_SB_.PC00.LPCB.LXEC.ODP6, FieldUnitObj)
    External (_SB_.PC00.LPCB.LXEC.ODP7, FieldUnitObj)
    External (_SB_.PC00.LPCB.LXEC.ODP8, FieldUnitObj)
    External (_SB_.PC00.LPCB.LXEC.ODP9, FieldUnitObj)
    External (_SB_.PC00.LPCB.LXEC.SCTS, FieldUnitObj)
    External (_SB_.PC00.LPCB.LXEC.TCTS, FieldUnitObj)
    External (_SB_.PC00.MC__.MHBR, FieldUnitObj)
    External (_SB_.PC00.TCPU, DeviceObj)
    External (_SB_.PL1X, FieldUnitObj)
    External (_SB_.PL2X, FieldUnitObj)
    External (_SB_.PLDT.ART0, PkgObj)
    External (_SB_.PLDT.ART1, PkgObj)
    External (_SB_.PLDT.FIDC, MethodObj)    // 1 Arguments
    External (_SB_.PLDT.FPST, MethodObj)    // 1 Arguments
    External (_SB_.PLDT.GDDV, MethodObj)    // 0 Arguments
    External (_SB_.PLDT.GHID, MethodObj)    // 1 Arguments
    External (_SB_.PLDT.PSVT, PkgObj)
    External (_SB_.PLDT.PTRT, MethodObj)    // 0 Arguments
    External (_SB_.PLWX, FieldUnitObj)
    External (_SB_.PR00._PSS, MethodObj)    // 0 Arguments
    External (_SB_.PR00._TPC, IntObj)
    External (_SB_.PR00._TSD, MethodObj)    // 0 Arguments
    External (_SB_.PR00._TSS, MethodObj)    // 0 Arguments
    External (_SB_.PR00.LPSS, PkgObj)
    External (_SB_.PR00.TPSS, PkgObj)
    External (_SB_.PR00.TSMC, PkgObj)
    External (_SB_.PR00.TSMF, PkgObj)
    External (_SB_.SLPB, DeviceObj)
    External (_TZ_.ETMD, IntObj)
    External (_TZ_.TZ00, ThermalZoneObj)
    External (ACTT, IntObj)
    External (ADBG, MethodObj)    // 1 Arguments
    External (ATPC, IntObj)
    External (CRTT, IntObj)
    External (HIDW, MethodObj)    // 4 Arguments
    External (HIWC, MethodObj)    // 1 Arguments
    External (PF00, IntObj)
    External (PNHM, IntObj)
    External (PSVT, IntObj)
    External (PTPC, IntObj)
    External (PWRS, IntObj)
    External (TCNT, IntObj)
    External (TSOD, IntObj)

    Debug = "[Dptf DptfTabl SSDT][AcpiTableEntry]"
    Debug = Timer
    ADBG ("[Dptf DptfTabl SSDT][AcpiTableEntry]")
    Scope (\_SB)
    {
        OperationRegion (DNVS, SystemMemory, 0x6FDC4000, 0x002D)
        Field (DNVS, AnyAcc, Lock, Preserve)
        {
            DTTE,   8, 
            DCFE,   32, 
            FND1,   8, 
            FND2,   8, 
            FND3,   8, 
            CHGE,   8, 
            BATR,   8, 
            S1DE,   8, 
            S2DE,   8, 
            S3DE,   8, 
            S4DE,   8, 
            S5DE,   8, 
            PCHE,   8, 
            PPSZ,   32, 
            PWRE,   8, 
            PPPR,   16, 
            ODV0,   8, 
            ODV1,   8, 
            ODV2,   8, 
            ODV3,   8, 
            ODV4,   8, 
            ODV5,   8, 
            CBCF,   8, 
            TTEF,   8, 
            FNAU,   8, 
            PCGL,   16, 
            PUPR,   8, 
            PLOR,   8, 
            PRTE,   16, 
            HEOL,   8, 
            TNML,   16, 
            ODV6,   8, 
            ODV7,   8, 
            ODV8,   8, 
            ODV9,   8
        }

        If (CondRefOf (\_SB.IETM))
        {
            Scope (\_SB.IETM)
            {
                Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
                {
                    If (CondRefOf (HIWC))
                    {
                        If (HIWC (Arg0))
                        {
                            If (CondRefOf (HIDW))
                            {
                                Return (HIDW (Arg0, Arg1, Arg2, Arg3))
                            }
                        }
                    }

                    Return (Buffer (One)
                    {
                         0x00                                             // .
                    })
                }

                Name (PTRP, Zero)
                Name (PSEM, Zero)
                Name (ATRP, Zero)
                Name (ASEM, Zero)
                Name (YTRP, Zero)
                Name (YSEM, Zero)
                Method (_OSC, 4, Serialized)  // _OSC: Operating System Capabilities
                {
                    CreateDWordField (Arg3, Zero, STS1)
                    CreateDWordField (Arg3, 0x04, CAP1)
                    If ((Arg1 != One))
                    {
                        STS1 &= 0xFFFFFF00
                        STS1 |= 0x0A
                        Return (Arg3)
                    }

                    If ((Arg2 != 0x02))
                    {
                        STS1 &= 0xFFFFFF00
                        STS1 |= 0x02
                        Return (Arg3)
                    }

                    If (CondRefOf (\_SB.APSV))
                    {
                        If ((PSEM == Zero))
                        {
                            PSEM = One
                            PTRP = \_SB.APSV /* External reference */
                        }
                    }

                    If (CondRefOf (\_SB.AAC0))
                    {
                        If ((ASEM == Zero))
                        {
                            ASEM = One
                            ATRP = \_SB.AAC0 /* External reference */
                        }
                    }

                    If (CondRefOf (\_SB.ACRT))
                    {
                        If ((YSEM == Zero))
                        {
                            YSEM = One
                            YTRP = \_SB.ACRT /* External reference */
                        }
                    }

                    If ((Arg0 == ToUUID ("b23ba85d-c8b7-3542-88de-8de2ffcfd698") /* Unknown UUID */))
                    {
                        If (~(STS1 & One))
                        {
                            If ((CAP1 & One))
                            {
                                If ((CAP1 & 0x02))
                                {
                                    \_SB.AAC0 = 0x6E
                                    \_TZ.ETMD = Zero
                                }
                                Else
                                {
                                    \_SB.AAC0 = ATRP /* \_SB_.IETM.ATRP */
                                    \_TZ.ETMD = One
                                }

                                If ((CAP1 & 0x04))
                                {
                                    \_SB.APSV = 0x6E
                                }
                                Else
                                {
                                    \_SB.APSV = PTRP /* \_SB_.IETM.PTRP */
                                }

                                If ((CAP1 & 0x08))
                                {
                                    \_SB.ACRT = 0xD2
                                }
                                Else
                                {
                                    \_SB.ACRT = YTRP /* \_SB_.IETM.YTRP */
                                }

                                If (CondRefOf (\_TZ.TZ00))
                                {
                                    Notify (\_TZ.TZ00, 0x81) // Information Change
                                }
                            }
                            Else
                            {
                                \_SB.ACRT = YTRP /* \_SB_.IETM.YTRP */
                                \_SB.APSV = PTRP /* \_SB_.IETM.PTRP */
                                \_SB.AAC0 = ATRP /* \_SB_.IETM.ATRP */
                                \_TZ.ETMD = One
                            }

                            If (CondRefOf (\_TZ.TZ00))
                            {
                                Notify (\_TZ.TZ00, 0x81) // Information Change
                            }
                        }

                        Return (Arg3)
                    }

                    Return (Arg3)
                }

                Method (DCFG, 0, NotSerialized)
                {
                    Return (\_SB.DCFE)
                }

                Name (ODVX, Package (0x0A)
                {
                    Zero, 
                    Zero, 
                    Zero, 
                    Zero, 
                    Zero, 
                    Zero, 
                    Zero, 
                    Zero, 
                    Zero, 
                    Zero
                })
                Method (ODVP, 0, Serialized)
                {
                    \_SB.ODV0 = \_SB.PC00.LPCB.LXEC.ODP0 /* External reference */
                    \_SB.ODV1 = \_SB.PC00.LPCB.LXEC.ODP1 /* External reference */
                    \_SB.ODV2 = \_SB.PC00.LPCB.LXEC.ODP2 /* External reference */
                    \_SB.ODV3 = \_SB.PC00.LPCB.LXEC.ODP3 /* External reference */
                    \_SB.ODV4 = \_SB.PC00.LPCB.LXEC.ODP4 /* External reference */
                    \_SB.ODV5 = \_SB.PC00.LPCB.LXEC.ODP5 /* External reference */
                    \_SB.ODV6 = \_SB.PC00.LPCB.LXEC.ODP6 /* External reference */
                    \_SB.ODV7 = \_SB.PC00.LPCB.LXEC.ODP7 /* External reference */
                    \_SB.ODV8 = \_SB.PC00.LPCB.LXEC.ODP8 /* External reference */
                    \_SB.ODV9 = \_SB.PC00.LPCB.LXEC.ODP9 /* External reference */
                    ODVX [Zero] = \_SB.ODV0
                    ODVX [One] = \_SB.ODV1
                    ODVX [0x02] = \_SB.ODV2
                    ODVX [0x03] = \_SB.ODV3
                    ODVX [0x04] = \_SB.ODV4
                    ODVX [0x05] = \_SB.ODV5
                    ODVX [0x06] = \_SB.ODV6
                    ODVX [0x07] = \_SB.ODV7
                    ODVX [0x08] = \_SB.ODV8
                    ODVX [0x09] = \_SB.ODV9
                    Return (ODVX) /* \_SB_.IETM.ODVX */
                }

                Name (PTTL, 0x14)
                Method (_TRT, 0, NotSerialized)  // _TRT: Thermal Relationship Table
                {
                    Return (\_SB.PLDT.PTRT ())
                }

                Method (PSVT, 0, NotSerialized)
                {
                    Return (\_SB.PLDT.PSVT) /* External reference */
                }

                Method (_ART, 0, NotSerialized)  // _ART: Active Cooling Relationship Table
                {
                    If (\_SB.IETM.SEN3.CTYP)
                    {
                        Return (\_SB.PLDT.ART1) /* External reference */
                    }
                    Else
                    {
                        Return (\_SB.PLDT.ART0) /* External reference */
                    }
                }

                Method (GDDV, 0, Serialized)
                {
                    Return (\_SB.PLDT.GDDV ())
                }

                Method (IMOK, 1, NotSerialized)
                {
                    \_SB.PC00.LPCB.LXEC.DTTF = One
                    Return (Arg0)
                }

                Method (DTNS, 1, NotSerialized)
                {
                    Local0 = Arg0
                    If ((Local0 & 0x40))
                    {
                        ADBG ("Notify Sensor 7")
                        Notify (\_SB.IETM.SEN7, 0x90) // Device-Specific
                    }

                    If ((Local0 & 0x20))
                    {
                        ADBG ("Notify Sensor 6")
                        Notify (\_SB.IETM.SEN6, 0x90) // Device-Specific
                    }

                    If ((Local0 & 0x10))
                    {
                        ADBG ("Notify Sensor 5")
                        Notify (\_SB.IETM.SEN5, 0x90) // Device-Specific
                    }

                    If ((Local0 & 0x08))
                    {
                        ADBG ("Notify Sensor 4")
                        Notify (\_SB.IETM.SEN4, 0x90) // Device-Specific
                    }

                    If ((Local0 & 0x04))
                    {
                        ADBG ("Notify Sensor 3")
                        Notify (\_SB.IETM.SEN3, 0x90) // Device-Specific
                    }

                    If ((Local0 & 0x02))
                    {
                        ADBG ("Notify Sensor 2")
                        Notify (\_SB.IETM.SEN2, 0x90) // Device-Specific
                    }

                    If ((Local0 & One))
                    {
                        ADBG ("Notify Sensor 1")
                        Notify (\_SB.IETM.SEN1, 0x90) // Device-Specific
                    }
                }
            }
        }

        Device (DPTF)
        {
            Name (_HID, EisaId ("PNP0A05") /* Generic Container Device */)  // _HID: Hardware ID
            Name (_UID, 0x07)  // _UID: Unique ID
            Name (_STR, Unicode ("DPTF Container"))  // _STR: Description String
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (0x0F)
            }

            Method (UVTH, 1, Serialized)
            {
                If (CondRefOf (\_SB.PC00.LPCB.H_EC))
                {
                    \_SB.PC00.LPCB.H_EC.CPDC (Arg0)
                    Return (Zero)
                }
                Else
                {
                    Return (0xFFFFFFFF)
                }
            }

            Method (SCHG, 1, Serialized)
            {
                If (CondRefOf (\_SB.PC00.LPCB.H_EC))
                {
                    \_SB.PC00.LPCB.H_EC.UPCR (Arg0)
                    Return (Zero)
                }
                Else
                {
                    Return (0xFFFFFFFF)
                }
            }

            Method (UPPM, 1, Serialized)
            {
                If (CondRefOf (\_SB.PC00.LPCB.H_EC))
                {
                    \_SB.PC00.LPCB.H_EC.UPPM (Arg0)
                    Return (Zero)
                }
                Else
                {
                    Return (0xFFFFFFFF)
                }
            }

            Method (CMPP, 0, Serialized)
            {
                If (CondRefOf (\_SB.PC00.LPCB.H_EC))
                {
                    Return (\_SB.PC00.LPCB.H_EC.BMPC ())
                }
                Else
                {
                    Return (0xFFFFFFFF)
                }
            }

            Method (VBNL, 0, Serialized)
            {
                If (CondRefOf (\_SB.PC00.LPCB.H_EC))
                {
                    Return (\_SB.PC00.LPCB.H_EC.BNLV ())
                }
                Else
                {
                    Return (0xFFFFFFFF)
                }
            }

            Method (RBHF, 0, Serialized)
            {
                If (CondRefOf (\_SB.PC00.LPCB.H_EC))
                {
                    Return (\_SB.PC00.LPCB.H_EC.BHFI ())
                }
                Else
                {
                    Return (0xFFFFFFFF)
                }
            }

            Method (PBSS, 0, Serialized)
            {
                If (CondRefOf (\_SB.PC00.LPCB.H_EC))
                {
                    Return (\_SB.PC00.LPCB.H_EC.RPBS ())
                }
                Else
                {
                    Return (0xFFFFFFFF)
                }
            }

            Method (CTYP, 0, Serialized)
            {
                If (CondRefOf (\_SB.PC00.LPCB.H_EC))
                {
                    Return (\_SB.PC00.LPCB.H_EC.RCTP ())
                }
                Else
                {
                    Return (0xFFFFFFFF)
                }
            }

            Method (BMAX, 0, Serialized)
            {
                If (CondRefOf (\_SB.PC00.LPCB.H_EC))
                {
                    Return (\_SB.PC00.LPCB.H_EC.RBPM ())
                }
                Else
                {
                    Return (0xFFFFFFFF)
                }
            }

            Method (FCHG, 0, Serialized)
            {
                If (CondRefOf (\_SB.PC00.LPCB.H_EC))
                {
                    Return (\_SB.PC00.LPCB.H_EC.RFCS ())
                }
                Else
                {
                    Return (0xFFFFFFFF)
                }
            }

            Method (FNSL, 3, Serialized)
            {
                If (CondRefOf (\_SB.PC00.LPCB.H_EC))
                {
                    Local0 = \_SB.PLDT.FIDC (Arg0)
                    \_SB.PC00.LPCB.H_EC.UPF2 (Local0, Arg1, Arg2)
                    Return (Zero)
                }
                Else
                {
                    Return (0xFFFFFFFF)
                }
            }

            Name (FTHL, Package (0x02)
            {
                0xFFFFFFFF, 
                0xFFFFFFFF
            })
            Method (GFHE, 0, Serialized)
            {
                If (CondRefOf (\_SB.PC00.LPCB.H_EC))
                {
                    Return (\_SB.PC00.LPCB.H_EC.RFTH ())
                }
                Else
                {
                    Return (0x0000000FFFFFFFFF)
                }
            }

            Method (GFLE, 0, Serialized)
            {
                If (CondRefOf (\_SB.PC00.LPCB.H_EC))
                {
                    Return (\_SB.PC00.LPCB.H_EC.RFTL ())
                }
                Else
                {
                    Return (0x0000000FFFFFFFFF)
                }
            }

            Method (SFHE, 1, Serialized)
            {
                If (CondRefOf (\_SB.PC00.LPCB.H_EC))
                {
                    \_SB.PC00.LPCB.H_EC.UPFH (Arg0)
                }
            }

            Method (SFLE, 1, Serialized)
            {
                If (CondRefOf (\_SB.PC00.LPCB.H_EC))
                {
                    \_SB.PC00.LPCB.H_EC.UPFL (Arg0)
                }
            }

            Method (GSHE, 0, Serialized)
            {
                If (CondRefOf (\_SB.PC00.LPCB.H_EC))
                {
                    Return (\_SB.PC00.LPCB.H_EC.RSTH ())
                }
                Else
                {
                    Return (0x0000000FFFFFFFFF)
                }
            }

            Method (GFCE, 0, Serialized)
            {
                If (CondRefOf (\_SB.PC00.LPCB.H_EC))
                {
                    Return (\_SB.PC00.LPCB.H_EC.RSFC ())
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (GFME, 0, Serialized)
            {
                If (CondRefOf (\_SB.PC00.LPCB.H_EC))
                {
                    Return (\_SB.PC00.LPCB.H_EC.RFPM ())
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (SFME, 1, Serialized)
            {
                If (CondRefOf (\_SB.PC00.LPCB.H_EC))
                {
                    \_SB.PC00.LPCB.H_EC.UPFP (Arg0)
                }
            }

            Method (GFNS, 1, Serialized)
            {
                If (CondRefOf (\_SB.PC00.LPCB.H_EC))
                {
                    Switch (ToInteger (Arg0))
                    {
                        Case (Zero)
                        {
                            Return (\_SB.PC00.LPCB.H_EC.RCFS ())
                        }
                        Case (One)
                        {
                            Return (\_SB.PC00.LPCB.H_EC.RCFS ())
                        }
                        Case (0x02)
                        {
                            Return (\_SB.PC00.LPCB.H_EC.RCFS ())
                        }
                        Default
                        {
                            Return (Zero)
                        }

                    }
                }
                Else
                {
                    Return (0x0000000FFFFFFFFF)
                }
            }

            Method (B1FC, 0, Serialized)
            {
                If (CondRefOf (\_SB.PC00.LPCB.H_EC))
                {
                    Return (\_SB.PC00.LPCB.H_EC.RBPV () [0x02])
                }
                Else
                {
                    Return (0x0000000FFFFFFFFF)
                }
            }

            Method (B1RC, 0, Serialized)
            {
                If (CondRefOf (\_SB.PC00.LPCB.H_EC))
                {
                    Return (\_SB.PC00.LPCB.H_EC.RBPV () [One])
                }
                Else
                {
                    Return (0x0000000FFFFFFFFF)
                }
            }

            Method (PWRT, 0, Serialized)
            {
                If (CondRefOf (\_SB.PC00.LPCB.H_EC))
                {
                    Return (\_SB.PC00.LPCB.H_EC.RRPT ())
                }
                Else
                {
                    Return (0x0000000FFFFFFFFF)
                }
            }

            Method (ARTG, 0, Serialized)
            {
                If (CondRefOf (\_SB.PC00.LPCB.H_EC))
                {
                    Local0 = (\_SB.PC00.LPCB.H_EC.RADR () * 0x0A)
                }
                Else
                {
                    Local0 = 0xFFFFFFFF
                }

                Return (Local0)
            }

            Method (PROP, 0, Serialized)
            {
                If (CondRefOf (\_SB.PC00.LPCB.H_EC))
                {
                    Return (\_SB.PC00.LPCB.H_EC.RWPP ())
                }
                Else
                {
                    Return (0x0000000FFFFFFFFF)
                }
            }

            Method (PBOK, 1, Serialized)
            {
                If (CondRefOf (\_SB.PC00.LPCB.H_EC))
                {
                    \_SB.PC00.LPCB.H_EC.STSN (Arg0)
                    Return (Zero)
                }
                Else
                {
                    Return (0xFFFFFFFF)
                }
            }

            Method (SNRD, 1, Serialized)
            {
                If (CondRefOf (\_SB.PC00.LPCB.H_EC))
                {
                    Local0 = \_SB.PC00.LPCB.H_EC.RSSV ()
                    Switch (ToInteger (Arg0))
                    {
                        Case (Zero)
                        {
                            Return (DerefOf (Local0 [Zero]))
                        }
                        Case (One)
                        {
                            Return (DerefOf (Local0 [One]))
                        }
                        Case (0x02)
                        {
                            Return (DerefOf (Local0 [0x02]))
                        }
                        Case (0x03)
                        {
                            Return (DerefOf (Local0 [0x03]))
                        }
                        Case (0x04)
                        {
                            Return (DerefOf (Local0 [0x04]))
                        }
                        Default
                        {
                            Return (0x0BB8)
                        }

                    }
                }
                Else
                {
                    Return (0x0BB8)
                }
            }

            Mutex (PATM, 0x00)
            Method (STRP, 4, Serialized)
            {
                If (CondRefOf (\_SB.PC00.LPCB.H_EC))
                {
                    Local0 = Acquire (PATM, 0x0064)
                    If ((Local0 == Zero))
                    {
                        \_SB.PC00.LPCB.H_EC.USTP (Arg0, Arg1, Arg2, Arg3)
                        Release (PATM)
                        Return (Zero)
                    }
                    Else
                    {
                        Return (0x0000000FFFFFFFFF)
                    }
                }
                Else
                {
                    Return (0x0000000FFFFFFFFF)
                }
            }

            If ((CBCF == One))
            {
                Method (B1CS, 0, Serialized)
                {
                    If (CondRefOf (\_SB.PC00.LPCB.H_EC))
                    {
                        Local0 = \_SB.PC00.LPCB.H_EC.B1CE ()
                        Return (Local0)
                    }
                    Else
                    {
                        Return (0xFFFFFFFF)
                    }
                }

                Method (BCCE, 0, Serialized)
                {
                    Local0 = 0x34
                    Return (Local0)
                }

                Method (SCLC, 1, Serialized)
                {
                    Return (\_SB.PC00.LPCB.H_EC.SCLE (Arg0))
                }
            }

            If ((TTEF == One))
            {
                Method (PCCE, 0, Serialized)
                {
                    Return (0x31)
                }

                Method (GRBC, 0, Serialized)
                {
                    Return (\_SB.PC00.LPCB.H_EC.GRBE ())
                }
            }

            Method (DP30, 0, NotSerialized)
            {
                If (((\_SB.DTTE == One) && (\_SB.PWRE == One)))
                {
                    Notify (\_SB.IETM.TPWR, 0x81) // Information Change
                }
            }

            Method (DP31, 0, NotSerialized)
            {
                If (((\_SB.DTTE == One) && (\_SB.PWRE == One)))
                {
                    Notify (\_SB.IETM.TPWR, 0x81) // Information Change
                }
            }

            Method (DP32, 0, NotSerialized)
            {
                If (((\_SB.DTTE == One) && (\_SB.BATR == One)))
                {
                    Notify (\_SB.IETM.BAT1, 0x86) // Device-Specific
                }
            }

            Method (DP33, 0, NotSerialized)
            {
                If (((\_SB.DTTE == One) && (\_SB.PWRE == One)))
                {
                    Notify (\_SB.IETM.TPWR, 0x81) // Information Change
                }
            }

            Method (DP34, 0, NotSerialized)
            {
                If (((\_SB.DTTE == One) && (\_SB.BATR == One)))
                {
                    Notify (\_SB.IETM.BAT1, 0x80) // Status Change
                }
            }

            Method (DP35, 0, NotSerialized)
            {
                If (((\_SB.DTTE == One) && (\_SB.BATR == One)))
                {
                    Notify (\_SB.IETM.BAT1, 0x83) // Device-Specific Change
                }
            }

            Method (DP37, 1, NotSerialized)
            {
                If ((Arg0 & 0x04))
                {
                    ADBG ("PPS adapter plugged-in")
                    \_SB.ODV1 = One
                    \_SB.IETM.ODVP ()
                    ADBG ("Update the OEM variable 1")
                    If (((\_SB.ODV0 == One) && (\_SB.ODV1 == One)))
                    {
                        ADBG ("Notify DTT OEM variable changed")
                        Notify (\_SB.IETM, 0x88) // Device-Specific
                        If ((\_SB.CHGE == One))
                        {
                            ADBG ("Notify DTT P state table changed")
                            Notify (\_SB.IETM.CHRG, 0x80) // Status Change
                        }
                    }
                }
                Else
                {
                    ADBG ("PPS adapter removed")
                    \_SB.ODV1 = Zero
                    \_SB.IETM.ODVP ()
                    ADBG ("Turn off variable 1")
                    If (~((\_SB.ODV0 == One) && (\_SB.ODV1 == One)))
                    {
                        ADBG ("Notify DTT OEM variable changed")
                        Notify (\_SB.IETM, 0x88) // Device-Specific
                        If ((\_SB.CHGE == One))
                        {
                            ADBG ("Notify DTT P state table changed")
                            Notify (\_SB.IETM.CHRG, 0x80) // Status Change
                        }
                    }
                }

                If (((\_SB.DTTE == One) && (\_SB.PWRE == One)))
                {
                    Notify (\_SB.IETM.TPWR, 0x81) // Information Change
                }
            }

            Method (DP38, 0, NotSerialized)
            {
                If (((\_SB.DTTE == One) && (\_SB.BATR == One)))
                {
                    Notify (\_SB.IETM.BAT1, 0x85) // Device-Specific
                }
            }

            Method (DP39, 0, NotSerialized)
            {
                If (((\_SB.DTTE == One) && (\_SB.BATR == One)))
                {
                    Notify (\_SB.IETM.BAT1, 0x86) // Device-Specific
                }
            }

            Method (DP3A, 0, NotSerialized)
            {
                If (((\_SB.DTTE == One) && (\_SB.BATR == One)))
                {
                    Notify (\_SB.IETM.BAT1, 0x86) // Device-Specific
                }
            }

            Method (DTTV, 0, NotSerialized)
            {
                If ((\_SB.DTTE == One))
                {
                    Notify (\_SB.IETM, 0xA0) // Device-Specific
                }
            }

            Method (DTTI, 0, NotSerialized)
            {
                If ((\_SB.ODV2 >= 0xFF))
                {
                    \_SB.ODV2 = Zero
                }
                Else
                {
                    \_SB.ODV2++
                }

                If ((\_SB.ODV3 >= 0xFF))
                {
                    \_SB.ODV3 = Zero
                }
                Else
                {
                    \_SB.ODV3++
                }

                If ((\_SB.ODV4 >= 0xFF))
                {
                    \_SB.ODV4 = Zero
                }
                Else
                {
                    \_SB.ODV4++
                }

                If ((\_SB.ODV5 >= 0xFF))
                {
                    \_SB.ODV5 = Zero
                }
                Else
                {
                    \_SB.ODV5++
                }

                \_SB.IETM.ODVP ()
                Notify (\_SB.IETM, 0x88) // Device-Specific
            }
        }
    }

    Scope (\_SB.IETM)
    {
        Method (KTOC, 1, Serialized)
        {
            If ((Arg0 > 0x0AAC))
            {
                Return (((Arg0 - 0x0AAC) / 0x0A))
            }
            Else
            {
                Return (Zero)
            }
        }

        Method (CTOK, 1, Serialized)
        {
            Return (((Arg0 * 0x0A) + 0x0AAC))
        }

        Method (C10K, 1, Serialized)
        {
            Name (TMP1, Buffer (0x10)
            {
                 0x00                                             // .
            })
            CreateByteField (TMP1, Zero, TMPL)
            CreateByteField (TMP1, One, TMPH)
            Local0 = (Arg0 + 0x0AAC)
            TMPL = (Local0 & 0xFF)
            TMPH = ((Local0 & 0xFF00) >> 0x08)
            ToInteger (TMP1, Local1)
            Return (Local1)
        }

        Method (K10C, 1, Serialized)
        {
            If ((Arg0 > 0x0AAC))
            {
                Return ((Arg0 - 0x0AAC))
            }
            Else
            {
                Return (Zero)
            }
        }
    }

    Scope (\_SB.IETM)
    {
        Device (TFN1)
        {
            Name (_UID, "TFN1")  // _UID: Unique ID
            Method (_HID, 0, NotSerialized)  // _HID: Hardware ID
            {
                Return (\_SB.PLDT.GHID (_UID))
            }

            Name (_STR, Unicode ("Fan 1"))  // _STR: Description String
            Name (PTYP, 0x04)
            Name (FON, One)
            Name (PFLG, Zero)
            Name (FSLV, Zero)
            Name (FNID, Zero)
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((FND1 == One))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_FIF, 0, NotSerialized)  // _FIF: Fan Information
            {
                Return (Package (0x04)
                {
                    Zero, 
                    One, 
                    0x02, 
                    Zero
                })
            }

            Method (_FPS, 0, NotSerialized)  // _FPS: Fan Performance States
            {
                Return (\_SB.PLDT.FPST (FNID))
            }

            Method (_FSL, 1, Serialized)  // _FSL: Fan Set Level
            {
                If (CondRefOf (\_SB.DPTF.FNSL))
                {
                    If ((Arg0 != FSLV))
                    {
                        \_SB.DPTF.FNSL (FNID, Arg0, FSLV)
                        FSLV = Arg0
                    }
                    Else
                    {
                        ADBG ("_FSL: New Fan Level is the same as previous level. Ignoring. No action taken")
                    }
                }
                Else
                {
                    ADBG ("_FSL: FNSL not available")
                }
            }

            Name (TFST, Package (0x03)
            {
                Zero, 
                0xFFFFFFFF, 
                0xFFFFFFFF
            })
            Method (_FST, 0, Serialized)  // _FST: Fan Status
            {
                If (CondRefOf (\_SB.DPTF.GFNS))
                {
                    Local0 = \_SB.DPTF.GFNS (FNID)
                    If ((Local0 != 0xFFFFFFFF))
                    {
                        TFST [One] = FSLV /* \_SB_.IETM.TFN1.FSLV */
                        TFST [0x02] = Local0
                    }
                    Else
                    {
                        ADBG ("_FST: EC not available")
                    }
                }
                Else
                {
                    ADBG ("_FST: GFNS not available")
                }

                Return (TFST) /* \_SB_.IETM.TFN1.TFST */
            }

            Method (GFHT, 0, Serialized)
            {
                Return (\_SB.DPTF.GFHE ())
            }

            Method (GFLT, 0, Serialized)
            {
                Return (\_SB.DPTF.GFLE ())
            }

            Method (SFHT, 1, Serialized)
            {
                \_SB.DPTF.SFHE (Arg0)
            }

            Method (SFLT, 1, Serialized)
            {
                \_SB.DPTF.SFLE (Arg0)
            }

            Method (GFSH, 0, Serialized)
            {
                Return (\_SB.DPTF.GSHE ())
            }

            Method (GFCS, 0, Serialized)
            {
                Return (\_SB.DPTF.GFCE ())
            }

            Method (GFOM, 0, Serialized)
            {
                Return (\_SB.DPTF.GFME ())
            }

            Method (SFOM, 1, Serialized)
            {
                \_SB.DPTF.SFME (Arg0)
            }
        }
    }

    Scope (\_SB.IETM)
    {
        Device (CHRG)
        {
            Name (_UID, "CHRG")  // _UID: Unique ID
            Method (_HID, 0, NotSerialized)  // _HID: Hardware ID
            {
                Return (\_SB.PLDT.GHID (_UID))
            }

            Name (_STR, Unicode ("Charger"))  // _STR: Description String
            Name (PTYP, 0x0B)
            Name (PFLG, Zero)
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((\_SB.CHGE == One))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (BCSP, Package (0x04)
            {
                Package (0x03)
                {
                    Zero, 
                    Zero, 
                    Zero
                }, 

                Package (0x03)
                {
                    Zero, 
                    Zero, 
                    Zero
                }, 

                Package (0x03)
                {
                    Zero, 
                    Zero, 
                    Zero
                }, 

                Package (0x03)
                {
                    Zero, 
                    Zero, 
                    Zero
                }
            })
            Name (PSSS, Zero)
            Name (PPPS, Zero)
            Name (PPS1, Package (0x08)
            {
                Package (0x08)
                {
                    0x64, 
                    Zero, 
                    Zero, 
                    Zero, 
                    Zero, 
                    0x0DAC, 
                    "MilliAmps", 
                    Zero
                }, 

                Package (0x08)
                {
                    0x55, 
                    Zero, 
                    Zero, 
                    Zero, 
                    One, 
                    0x0BB8, 
                    "MilliAmps", 
                    Zero
                }, 

                Package (0x08)
                {
                    0x47, 
                    Zero, 
                    Zero, 
                    Zero, 
                    0x02, 
                    0x09C4, 
                    "MilliAmps", 
                    Zero
                }, 

                Package (0x08)
                {
                    0x39, 
                    Zero, 
                    Zero, 
                    Zero, 
                    0x03, 
                    0x07D0, 
                    "MilliAmps", 
                    Zero
                }, 

                Package (0x08)
                {
                    0x2A, 
                    Zero, 
                    Zero, 
                    Zero, 
                    0x04, 
                    0x05DC, 
                    "MilliAmps", 
                    Zero
                }, 

                Package (0x08)
                {
                    0x1C, 
                    Zero, 
                    Zero, 
                    Zero, 
                    0x05, 
                    0x03E8, 
                    "MilliAmps", 
                    Zero
                }, 

                Package (0x08)
                {
                    0x0E, 
                    Zero, 
                    Zero, 
                    Zero, 
                    0x06, 
                    0x01F4, 
                    "MilliAmps", 
                    Zero
                }, 

                Package (0x08)
                {
                    Zero, 
                    Zero, 
                    Zero, 
                    Zero, 
                    0x07, 
                    Zero, 
                    "MilliAmps", 
                    Zero
                }
            })
            Name (PPS2, Package (0x0A)
            {
                Package (0x08)
                {
                    0x64, 
                    Zero, 
                    Zero, 
                    Zero, 
                    Zero, 
                    0x1194, 
                    "MilliAmps", 
                    Zero
                }, 

                Package (0x08)
                {
                    0x58, 
                    Zero, 
                    Zero, 
                    Zero, 
                    One, 
                    0x0FA0, 
                    "MilliAmps", 
                    Zero
                }, 

                Package (0x08)
                {
                    0x4D, 
                    Zero, 
                    Zero, 
                    Zero, 
                    0x02, 
                    0x0DAC, 
                    "MilliAmps", 
                    Zero
                }, 

                Package (0x08)
                {
                    0x42, 
                    Zero, 
                    Zero, 
                    Zero, 
                    0x03, 
                    0x0BB8, 
                    "MilliAmps", 
                    Zero
                }, 

                Package (0x08)
                {
                    0x37, 
                    Zero, 
                    Zero, 
                    Zero, 
                    0x04, 
                    0x09C4, 
                    "MilliAmps", 
                    Zero
                }, 

                Package (0x08)
                {
                    0x2C, 
                    Zero, 
                    Zero, 
                    Zero, 
                    0x05, 
                    0x07D0, 
                    "MilliAmps", 
                    Zero
                }, 

                Package (0x08)
                {
                    0x21, 
                    Zero, 
                    Zero, 
                    Zero, 
                    0x06, 
                    0x05DC, 
                    "MilliAmps", 
                    Zero
                }, 

                Package (0x08)
                {
                    0x16, 
                    Zero, 
                    Zero, 
                    Zero, 
                    0x07, 
                    0x03E8, 
                    "MilliAmps", 
                    Zero
                }, 

                Package (0x08)
                {
                    0x0B, 
                    Zero, 
                    Zero, 
                    Zero, 
                    0x08, 
                    0x01F4, 
                    "MilliAmps", 
                    Zero
                }, 

                Package (0x08)
                {
                    Zero, 
                    Zero, 
                    Zero, 
                    Zero, 
                    0x09, 
                    Zero, 
                    "MilliAmps", 
                    Zero
                }
            })
            Name (PPS3, Package (0x04)
            {
                Package (0x08)
                {
                    Zero, 
                    Zero, 
                    Zero, 
                    Zero, 
                    Zero, 
                    0x3A98, 
                    "MilliVoltage", 
                    Zero
                }, 

                Package (0x08)
                {
                    Zero, 
                    Zero, 
                    Zero, 
                    Zero, 
                    One, 
                    0x2EE0, 
                    "MilliVoltage", 
                    Zero
                }, 

                Package (0x08)
                {
                    Zero, 
                    Zero, 
                    Zero, 
                    Zero, 
                    0x02, 
                    Zero, 
                    "", 
                    Zero
                }, 

                Package (0x08)
                {
                    Zero, 
                    Zero, 
                    Zero, 
                    Zero, 
                    0x03, 
                    Zero, 
                    "", 
                    Zero
                }
            })
            Method (PPSS, 0, Serialized)
            {
                ADBG ("DTT calls PPSS")
                If (((ODV0 == One) && (ODV1 == One)))
                {
                    ADBG ("PPSS: selecting PPS")
                    Return (PPS3) /* \_SB_.IETM.CHRG.PPS3 */
                }
                ElseIf ((CondRefOf (\_SB.DPTF.FCHG) && (\_SB.DPTF.FCHG () == One)))
                {
                    ADBG ("PPSS: selecting FCHG")
                    Return (PPS2) /* \_SB_.IETM.CHRG.PPS2 */
                }
                Else
                {
                    ADBG ("PPSS: FCHG and PPS are not available")
                    Return (PPS1) /* \_SB_.IETM.CHRG.PPS1 */
                }
            }

            Method (PCAL, 0, Serialized)
            {
                ADBG ("PCAL!")
                If (((ODV0 == One) && (ODV1 == One)))
                {
                    ADBG ("Save PPS package size to PSSS!")
                    PSSS = SizeOf (PPS3)
                }
                ElseIf ((CondRefOf (\_SB.DPTF.FCHG) && (\_SB.DPTF.FCHG () == One)))
                {
                    PSSS = SizeOf (PPS2)
                }
                Else
                {
                    ADBG ("PCAL: FCHG not available")
                    PSSS = SizeOf (PPS1)
                }
            }

            Method (PPPC, 0, NotSerialized)
            {
                ADBG ("PPPC return the present p-state!")
                Return (PPPS) /* \_SB_.IETM.CHRG.PPPS */
            }

            Method (SPPC, 1, Serialized)
            {
                ADBG ("SPPC to transfer the selected power package!")
                ADBG (Concatenate ("Package Index: ", ToHexString (Arg0)))
                If (CondRefOf (\_SB.DPTF.SCHG))
                {
                    PCAL ()
                    If ((ToInteger (Arg0) <= (PSSS - One)))
                    {
                        If (((ODV0 == One) && (ODV1 == One)))
                        {
                            Local1 = DerefOf (DerefOf (PPS3 [Arg0]) [0x04])
                            ADBG (Concatenate ("PPS p-state value:", ToHexString (Local1)))
                            PPPS = Local1
                            If (CondRefOf (\_SB.DPTF.UPPM))
                            {
                                ADBG (Concatenate ("PPS sets P-state: ", ToHexString (Local1)))
                                \_SB.DPTF.UPPM (Local1)
                            }
                        }
                        ElseIf ((CondRefOf (\_SB.DPTF.FCHG) && (\_SB.DPTF.FCHG () == One)))
                        {
                            Local1 = DerefOf (DerefOf (PPS2 [Arg0]) [0x05])
                            PPPS = DerefOf (DerefOf (PPS2 [Arg0]) [0x04])
                            \_SB.DPTF.SCHG (Local1)
                        }
                        Else
                        {
                            Local1 = DerefOf (DerefOf (PPS1 [Arg0]) [0x05])
                            PPPS = DerefOf (DerefOf (PPS1 [Arg0]) [0x04])
                            \_SB.DPTF.SCHG (Local1)
                        }
                    }

                    Return (Zero)
                }

                ADBG ("SPPC: SCHG not available")
            }

            Method (PPDL, 0, NotSerialized)
            {
                ADBG ("DTT calls PPDL")
                PCAL ()
                Return ((PSSS - One))
            }

            If ((CBCF == One))
            {
                Method (BCCA, 0, NotSerialized)
                {
                    Return (\_SB.DPTF.BCCE ())
                }

                Method (BCCS, 3, Serialized)
                {
                    If ((Arg0 != One))
                    {
                        Return (One)
                    }

                    If (((Arg1 < One) || (Arg1 > 0x04)))
                    {
                        Return (0x02)
                    }

                    Local0 = Zero
                    While ((Local0 < 0x03))
                    {
                        Local1 = DerefOf (Arg2 [Local0])
                        DerefOf (BCSP [Zero]) [Local0] = Local1
                        Local0++
                    }

                    Local0 = 0x03
                    While ((Local0 < 0x06))
                    {
                        Local1 = DerefOf (Arg2 [Local0])
                        DerefOf (BCSP [One]) [(Local0 - 0x03)] = 
                            Local1
                        Local0++
                    }

                    Local0 = 0x06
                    While ((Local0 < 0x09))
                    {
                        Local1 = DerefOf (Arg2 [Local0])
                        DerefOf (BCSP [0x02]) [(Local0 - 0x06)] = 
                            Local1
                        Local0++
                    }

                    Local0 = 0x09
                    While ((Local0 < 0x0C))
                    {
                        Local1 = DerefOf (Arg2 [Local0])
                        DerefOf (BCSP [0x03]) [(Local0 - 0x09)] = 
                            Local1
                        Local0++
                    }

                    Local0 = \_SB.DPTF.B1CS ()
                    Local1 = Zero
                    While ((Local1 < 0x04))
                    {
                        If ((Local0 < DerefOf (DerefOf (BCSP [Local1]) [Zero])))
                        {
                            Local2 = (DerefOf (DerefOf (BCSP [Local1]) [One]) & 
                                One)
                            If ((Local2 == One))
                            {
                                Local3 = (DerefOf (DerefOf (BCSP [Local1]) [0x02]) | 
                                    0x80)
                            }
                            Else
                            {
                                Local3 = (DerefOf (DerefOf (BCSP [Local1]) [0x02]) & 
                                    0x7F)
                            }

                            \_SB.DPTF.SCLC (Local3)
                        }

                        Local1++
                    }

                    Return (Zero)
                }

                Method (C1BP, 0, Serialized)
                {
                    Local0 = Zero
                    Local0 |= PLOR /* \_SB_.PLOR */
                    Local0 <<= 0x08
                    Local0 |= PUPR /* \_SB_.PUPR */
                    Local0 <<= 0x10
                    Local0 |= PCGL /* \_SB_.PCGL */
                    Return (Local0)
                }

                Method (C2BP, 0, Serialized)
                {
                    Local1 = Zero
                    Local0 = Zero
                    Local0 |= HEOL /* \_SB_.HEOL */
                    Local0 <<= 0x10
                    Local0 |= PRTE /* \_SB_.PRTE */
                    Local0 <<= 0x08
                    Local0 |= Local1
                    Return (Local0)
                }

                Method (C3BP, 0, Serialized)
                {
                    Local0 = Zero
                    Local0 <<= 0x10
                    Local0 |= TNML /* \_SB_.TNML */
                    Return (Local0)
                }
            }
        }
    }

    Scope (\_SB.IETM)
    {
        Device (TPWR)
        {
            Name (_UID, "TPWR")  // _UID: Unique ID
            Method (_HID, 0, NotSerialized)  // _HID: Hardware ID
            {
                Return (\_SB.PLDT.GHID (_UID))
            }

            Name (_STR, Unicode ("Platform Power"))  // _STR: Description String
            Name (PTYP, 0x11)
            Name (PFLG, Zero)
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((\_SB.PWRE == One))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (PSOC, 0, NotSerialized)
            {
                If (CondRefOf (\_SB.DPTF.B1FC))
                {
                    If ((\_SB.DPTF.B1FC () == 0xFFFFFFFF))
                    {
                        ADBG ("EC is not available")
                        Return (Zero)
                    }
                    ElseIf ((\_SB.DPTF.B1FC () == Zero))
                    {
                        ADBG ("Battery malfunction B1FC")
                        Return (Zero)
                    }
                }

                If ((CondRefOf (\_SB.DPTF.B1FC) & (\_SB.DPTF.B1FC () == Zero)))
                {
                    ADBG ("Battery malfunction B1FC")
                    Return (Zero)
                }

                If (!CondRefOf (\_SB.DPTF.B1RC))
                {
                    ADBG ("B1RC not available")
                    Return (Zero)
                }

                If ((\_SB.DPTF.B1RC () > \_SB.DPTF.B1FC ()))
                {
                    ADBG ("Battery malfunction RC greater than FC")
                    Return (Zero)
                }

                If ((\_SB.DPTF.B1RC () == \_SB.DPTF.B1FC ()))
                {
                    ADBG ("Battery Fully Charged")
                    Return (0x64)
                }

                If ((\_SB.DPTF.B1RC () < \_SB.DPTF.B1FC ()))
                {
                    Local0 = (\_SB.DPTF.B1RC () * 0x64)
                    Divide (Local0, \_SB.DPTF.B1FC (), Local2, Local1)
                    Local2 /= 0x64
                    Local3 = (\_SB.DPTF.B1FC () / 0xC8)
                    If ((Local2 >= Local3))
                    {
                        Local1 += One
                    }

                    ADBG (Concatenate ("Battery Current Charge: ", ToDecimalString (Local1)))
                    Return (Local1)
                }
                Else
                {
                    ADBG ("PSOC illegal condition")
                    Return (Zero)
                }
            }

            Method (PSRC, 0, Serialized)
            {
                ADBG ("PSRC")
                If ((CondRefOf (\_SB.DPTF.PWRT) & (\_SB.DPTF.PWRT () == 0xFFFFFFFF)))
                {
                    ADBG ("EC is not available")
                    Return (Zero)
                }
                Else
                {
                    Local0 = \_SB.DPTF.PWRT ()
                    Local1 = (Local0 & 0xF0)
                }

                Switch (ToInteger ((ToInteger (Local0) & 0x07)))
                {
                    Case (Zero)
                    {
                        ADBG ("DC")
                        Local1 |= Zero
                    }
                    Case (One)
                    {
                        ADBG ("AC")
                        Local1 |= One
                    }
                    Case (0x02)
                    {
                        ADBG ("PD")
                        Local1 |= 0x02
                    }
                    Case (0x04)
                    {
                        ADBG ("PD and PPS Adapter")
                        Local1 |= 0x02
                    }
                    Default
                    {
                        ADBG ("Default DC")
                        Local1 |= Zero
                    }

                }

                Return (Local1)
            }

            Method (ARTG, 0, NotSerialized)
            {
                ADBG ("ARTG")
                If (((PSRC () & 0x07) == One))
                {
                    If (CondRefOf (\_SB.DPTF.ARTG))
                    {
                        Local0 = \_SB.DPTF.ARTG ()
                        If ((Local0 != 0xFFFFFFFF))
                        {
                            ADBG (Concatenate ("ARTG EC: ", ToHexString (Local0)))
                            Return (Local0)
                        }
                    }

                    ADBG ("ARTG EC not available")
                    Return (0x00015F90)
                }
                Else
                {
                    ADBG ("ARTG Power Source is  AC")
                    Return (Zero)
                }
            }

            Method (PROP, 0, NotSerialized)
            {
                If (CondRefOf (\_SB.DPTF.PROP))
                {
                    Local0 = \_SB.DPTF.PROP ()
                    If ((Local0 != 0xFFFFFFFF))
                    {
                        Local0 *= 0x03E8
                        ADBG (Concatenate ("PROP EC: ", ToHexString (Local0)))
                        Return (Local0)
                    }
                }

                ADBG ("PROP EC not available")
                Return (0x61A8)
            }

            Method (PBOK, 1, Serialized)
            {
                If (CondRefOf (\_SB.DPTF.PBOK))
                {
                    Local0 = (Arg0 & 0x0F)
                    \_SB.DPTF.PBOK (Local0)
                    Return (Zero)
                }

                ADBG ("PBOK not available")
            }
        }
    }

    Scope (\_SB.IETM)
    {
        Device (BAT1)
        {
            Name (_UID, "1")  // _UID: Unique ID
            Method (_HID, 0, NotSerialized)  // _HID: Hardware ID
            {
                Return (\_SB.PLDT.GHID (_UID))
            }

            Name (_STR, Unicode ("Battery 1 Participant"))  // _STR: Description String
            Name (PTYP, 0x0C)
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((\_SB.BATR == One))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            If ((TTEF == One))
            {
                Name (PBDP, Package (0x02)
                {
                    Package (0x01)
                    {
                        One
                    }, 

                    Package (0x02)
                    {
                        0xFFFFFFFF, 
                        Zero
                    }
                })
            }

            Method (PMAX, 0, Serialized)
            {
                If (CondRefOf (\_SB.DPTF.BMAX))
                {
                    Local0 = \_SB.DPTF.BMAX ()
                    If ((Local0 != 0xFFFFFFFF))
                    {
                        If (Local0)
                        {
                            Local0 = ~Local0 |= 0xFFFF0000
                            Local0 = (Local0 += One * 0x0A)
                        }

                        Return (Local0)
                    }
                }

                ADBG ("PMAX: EC not available")
                Return (Zero)
            }

            Method (CTYP, 0, NotSerialized)
            {
                If (CondRefOf (\_SB.DPTF.CTYP))
                {
                    Local0 = \_SB.DPTF.CTYP ()
                    If ((Local0 != 0xFFFFFFFF))
                    {
                        Return (Local0)
                    }
                }

                ADBG ("CTYP: EC not available")
                Return (0x03)
            }

            Method (PBSS, 0, NotSerialized)
            {
                If (CondRefOf (\_SB.DPTF.PBSS))
                {
                    Local0 = \_SB.DPTF.PBSS ()
                    If ((Local0 != 0xFFFFFFFF))
                    {
                        Return (Local0)
                    }
                }

                ADBG ("PBSS: EC not available")
                Return (0x64)
            }

            Method (DPSP, 0, Serialized)
            {
                Return (\_SB.PPPR)
            }

            Method (RBHF, 0, NotSerialized)
            {
                If (CondRefOf (\_SB.DPTF.RBHF))
                {
                    Local0 = \_SB.DPTF.RBHF ()
                    If ((Local0 != 0xFFFFFFFF))
                    {
                        Return (Local0)
                    }
                }

                ADBG ("RBHF: EC not available")
                Return (0xFFFFFFFF)
            }

            Method (VBNL, 0, NotSerialized)
            {
                If (CondRefOf (\_SB.DPTF.VBNL))
                {
                    Local0 = \_SB.DPTF.VBNL ()
                    If ((Local0 != 0xFFFFFFFF))
                    {
                        Return (Local0)
                    }
                }

                ADBG ("VBNL: EC not available")
                Return (0xFFFFFFFF)
            }

            Method (CMPP, 0, NotSerialized)
            {
                If (CondRefOf (\_SB.DPTF.CMPP))
                {
                    Local0 = \_SB.DPTF.CMPP ()
                    If ((Local0 != 0xFFFFFFFF))
                    {
                        Return (Local0)
                    }
                }

                ADBG ("CMPP: EC not available")
                Return (0xFFFFFFFF)
            }

            If ((TTEF == One))
            {
                Method (PCAP, 0, NotSerialized)
                {
                    Return (\_SB.DPTF.PCCE ())
                }

                Method (GRBD, 0, NotSerialized)
                {
                    Return (\_SB.DPTF.GRBC ())
                }

                Method (SPBD, 2, Serialized)
                {
                    Local0 = DerefOf (Arg1 [Zero])
                    Local1 = DerefOf (Arg1 [One])
                    Local2 = DerefOf (Arg1 [0x02])
                    Local3 = DerefOf (Arg1 [0x03])
                    Local4 = (Local3 << 0x18)
                    Local5 = (Local2 << 0x10)
                    Local4 |= Local5
                    Local5 = (Local1 << 0x08)
                    Local4 |= Local5
                    Local4 |= Local0
                    DerefOf (PBDP [One]) [Zero] = Local4
                }

                Method (GPBD, 0, NotSerialized)
                {
                    Return (PBDP) /* \_SB_.IETM.BAT1.PBDP */
                }

                Method (GPDE, 0, NotSerialized)
                {
                    Local1 = DerefOf (DerefOf (PBDP [One]) [Zero])
                    Return (Local1)
                }
            }
        }
    }

    Scope (\_SB.IETM)
    {
        Device (SEN1)
        {
            Name (_UID, "SEN1")  // _UID: Unique ID
            Method (_HID, 0, NotSerialized)  // _HID: Hardware ID
            {
                Return (\_SB.PLDT.GHID (_UID))
            }

            Name (_STR, Unicode ("CPU NTC"))  // _STR: Description String
            Name (CTYP, Zero)
            Name (PFLG, Zero)
            Name (GTSH, 0x14)
            Method (_TMP, 0, Serialized)  // _TMP: Temperature
            {
                If (\_SB.PC00.LPCB.LXEC.ECAV)
                {
                    If ((Acquire (\_SB.PC00.LPCB.LXEC.ECMT, 0xA000) == Zero))
                    {
                        Local0 = \_SB.PC00.LPCB.LXEC.CVTS /* External reference */
                        Release (\_SB.PC00.LPCB.LXEC.ECMT)
                        Return (\_SB.IETM.CTOK (Local0))
                    }
                }
            }

            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (0x0F)
            }

            Name (PATC, 0x02)
            Method (PAT0, 1, Serialized)
            {
            }

            Method (PAT1, 1, Serialized)
            {
            }

            Method (_TSP, 0, Serialized)  // _TSP: Thermal Sampling Period
            {
                Return (0x64)
            }
        }

        Device (SEN2)
        {
            Name (_UID, "SEN2")  // _UID: Unique ID
            Method (_HID, 0, NotSerialized)  // _HID: Hardware ID
            {
                Return (\_SB.PLDT.GHID (_UID))
            }

            Name (_STR, Unicode ("DDR NTC"))  // _STR: Description String
            Name (CTYP, Zero)
            Name (PFLG, Zero)
            Name (GTSH, 0x14)
            Method (_TMP, 0, Serialized)  // _TMP: Temperature
            {
                If (\_SB.PC00.LPCB.LXEC.ECAV)
                {
                    If ((Acquire (\_SB.PC00.LPCB.LXEC.ECMT, 0xA000) == Zero))
                    {
                        Local0 = \_SB.PC00.LPCB.LXEC.DDRS /* External reference */
                        Release (\_SB.PC00.LPCB.LXEC.ECMT)
                        Return (\_SB.IETM.CTOK (Local0))
                    }
                }
            }

            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (0x0F)
            }

            Name (PATC, 0x02)
            Method (PAT0, 1, Serialized)
            {
            }

            Method (PAT1, 1, Serialized)
            {
            }

            Method (_TSP, 0, Serialized)  // _TSP: Thermal Sampling Period
            {
                Return (0x64)
            }
        }

        Device (SEN3)
        {
            Name (_UID, "SEN3")  // _UID: Unique ID
            Method (_HID, 0, NotSerialized)  // _HID: Hardware ID
            {
                Return (\_SB.PLDT.GHID (_UID))
            }

            Name (_STR, Unicode ("CPU VR NTC"))  // _STR: Description String
            Name (CTYP, Zero)
            Name (PFLG, Zero)
            Name (GTSH, 0x14)
            Method (_TMP, 0, Serialized)  // _TMP: Temperature
            {
                If (\_SB.PC00.LPCB.LXEC.ECAV)
                {
                    If ((Acquire (\_SB.PC00.LPCB.LXEC.ECMT, 0xA000) == Zero))
                    {
                        Local0 = \_SB.PC00.LPCB.LXEC.ESVT /* External reference */
                        Release (\_SB.PC00.LPCB.LXEC.ECMT)
                        Return (\_SB.IETM.CTOK (Local0))
                    }
                }
            }

            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (0x0F)
            }

            Name (PATC, 0x02)
            Method (PAT0, 1, Serialized)
            {
            }

            Method (PAT1, 1, Serialized)
            {
            }

            Method (_TSP, 0, Serialized)  // _TSP: Thermal Sampling Period
            {
                Return (0x64)
            }
        }

        Device (SEN4)
        {
            Name (_UID, "SEN4")  // _UID: Unique ID
            Method (_HID, 0, NotSerialized)  // _HID: Hardware ID
            {
                Return (\_SB.PLDT.GHID (_UID))
            }

            Name (_STR, Unicode ("5V VR NTC"))  // _STR: Description String
            Name (CTYP, Zero)
            Name (PFLG, Zero)
            Name (GTSH, 0x14)
            Method (_TMP, 0, Serialized)  // _TMP: Temperature
            {
                If (\_SB.PC00.LPCB.LXEC.ECAV)
                {
                    If ((Acquire (\_SB.PC00.LPCB.LXEC.ECMT, 0xA000) == Zero))
                    {
                        Local0 = \_SB.PC00.LPCB.LXEC.FVTS /* External reference */
                        Release (\_SB.PC00.LPCB.LXEC.ECMT)
                        Return (\_SB.IETM.CTOK (Local0))
                    }
                }
            }

            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (0x0F)
            }

            Name (PATC, 0x02)
            Method (PAT0, 1, Serialized)
            {
            }

            Method (PAT1, 1, Serialized)
            {
            }

            Method (_TSP, 0, Serialized)  // _TSP: Thermal Sampling Period
            {
                Return (0x64)
            }
        }

        Device (SEN5)
        {
            Name (_UID, "SEN5")  // _UID: Unique ID
            Method (_HID, 0, NotSerialized)  // _HID: Hardware ID
            {
                Return (\_SB.PLDT.GHID (_UID))
            }

            Name (_STR, Unicode ("Ambient NTC"))  // _STR: Description String
            Name (CTYP, Zero)
            Name (PFLG, Zero)
            Name (GTSH, 0x14)
            Method (_TMP, 0, Serialized)  // _TMP: Temperature
            {
                If (\_SB.PC00.LPCB.LXEC.ECAV)
                {
                    If ((Acquire (\_SB.PC00.LPCB.LXEC.ECMT, 0xA000) == Zero))
                    {
                        Local0 = \_SB.PC00.LPCB.LXEC.ABNT /* External reference */
                        Release (\_SB.PC00.LPCB.LXEC.ECMT)
                        Return (\_SB.IETM.CTOK (Local0))
                    }
                }
            }

            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (0x0F)
            }

            Name (PATC, 0x02)
            Method (PAT0, 1, Serialized)
            {
            }

            Method (PAT1, 1, Serialized)
            {
            }

            Method (_TSP, 0, Serialized)  // _TSP: Thermal Sampling Period
            {
                Return (0x64)
            }
        }

        Device (SEN6)
        {
            Name (_UID, "SEN6")  // _UID: Unique ID
            Method (_HID, 0, NotSerialized)  // _HID: Hardware ID
            {
                Return (\_SB.PLDT.GHID (_UID))
            }

            Name (_STR, Unicode ("Charger VR NTC"))  // _STR: Description String
            Name (CTYP, Zero)
            Name (PFLG, Zero)
            Name (GTSH, 0x14)
            Method (_TMP, 0, Serialized)  // _TMP: Temperature
            {
                If (\_SB.PC00.LPCB.LXEC.ECAV)
                {
                    If ((Acquire (\_SB.PC00.LPCB.LXEC.ECMT, 0xA000) == Zero))
                    {
                        Local0 = \_SB.PC00.LPCB.LXEC.CHTS /* External reference */
                        Release (\_SB.PC00.LPCB.LXEC.ECMT)
                        Return (\_SB.IETM.CTOK (Local0))
                    }
                }
            }

            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (0x0F)
            }

            Name (PATC, 0x02)
            Method (PAT0, 1, Serialized)
            {
            }

            Method (PAT1, 1, Serialized)
            {
            }

            Method (_TSP, 0, Serialized)  // _TSP: Thermal Sampling Period
            {
                Return (0x64)
            }
        }

        Device (SEN7)
        {
            Name (_UID, "SEN7")  // _UID: Unique ID
            Method (_HID, 0, NotSerialized)  // _HID: Hardware ID
            {
                Return (\_SB.PLDT.GHID (_UID))
            }

            Name (_STR, Unicode ("TypeC NTC"))  // _STR: Description String
            Name (CTYP, Zero)
            Name (PFLG, Zero)
            Name (GTSH, 0x14)
            Method (_TMP, 0, Serialized)  // _TMP: Temperature
            {
                If (\_SB.PC00.LPCB.LXEC.ECAV)
                {
                    If ((Acquire (\_SB.PC00.LPCB.LXEC.ECMT, 0xA000) == Zero))
                    {
                        Local0 = \_SB.PC00.LPCB.LXEC.TCTS /* External reference */
                        Release (\_SB.PC00.LPCB.LXEC.ECMT)
                        Return (\_SB.IETM.CTOK (Local0))
                    }
                }
            }

            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (0x0F)
            }

            Name (PATC, 0x02)
            Method (PAT0, 1, Serialized)
            {
            }

            Method (PAT1, 1, Serialized)
            {
            }

            Method (_TSP, 0, Serialized)  // _TSP: Thermal Sampling Period
            {
                Return (0x64)
            }
        }
    }

    Scope (\_SB.PC00.TCPU)
    {
        Name (PFLG, Zero)
        Method (_STA, 0, NotSerialized)  // _STA: Status
        {
            If ((\_SB.DTTE == One))
            {
                Return (0x0F)
            }
            Else
            {
                Return (Zero)
            }
        }

        OperationRegion (CPWR, SystemMemory, ((\_SB.PC00.MC.MHBR << 0x12) + 0x5000), 0x1000)
        Field (CPWR, ByteAcc, NoLock, Preserve)
        {
            Offset (0x930), 
            PTDP,   15, 
            Offset (0x932), 
            PMIN,   15, 
            Offset (0x934), 
            PMAX,   15, 
            Offset (0x936), 
            TMAX,   7, 
            Offset (0x938), 
            PWRU,   4, 
            Offset (0x939), 
            EGYU,   5, 
            Offset (0x93A), 
            TIMU,   4, 
            Offset (0x958), 
            Offset (0x95C), 
            LPMS,   1, 
            Offset (0x978), 
            PCTP,   8, 
            Offset (0x998), 
            RP0C,   8, 
            RP1C,   8, 
            RPNC,   8, 
            Offset (0xF3C), 
            TRAT,   8, 
            Offset (0xF40), 
            PTD1,   15, 
            Offset (0xF42), 
            TRA1,   8, 
            Offset (0xF44), 
            PMX1,   15, 
            Offset (0xF46), 
            PMN1,   15, 
            Offset (0xF48), 
            PTD2,   15, 
            Offset (0xF4A), 
            TRA2,   8, 
            Offset (0xF4C), 
            PMX2,   15, 
            Offset (0xF4E), 
            PMN2,   15, 
            Offset (0xF50), 
            CTCL,   2, 
                ,   29, 
            Offset (0xF54), 
            MNTR,   8
        }

        Name (XPCC, Zero)
        Method (PPCC, 0, Serialized)
        {
            If (((XPCC == Zero) && CondRefOf (\_SB.CBMI)))
            {
                CPLX ()
                XPCC = One
            }

            Return (NPCC) /* \_SB_.PC00.TCPU.NPCC */
        }

        Name (NPCC, Package (0x03)
        {
            0x02, 
            Package (0x06)
            {
                Zero, 
                0x88B8, 
                0xAFC8, 
                0x6D60, 
                0x7D00, 
                0x03E8
            }, 

            Package (0x06)
            {
                One, 
                0xDBBA, 
                0xDBBA, 
                Zero, 
                Zero, 
                0x03E8
            }
        })
        Method (CPNU, 2, Serialized)
        {
            Name (CNVT, Zero)
            Name (PPUU, Zero)
            Name (RMDR, Zero)
            If ((PWRU == Zero))
            {
                PPUU = One
            }
            Else
            {
                PPUU = (PWRU-- << 0x02)
            }

            Divide (Arg0, PPUU, RMDR, CNVT) /* \_SB_.PC00.TCPU.CPNU.CNVT */
            If ((Arg1 == Zero))
            {
                Return (CNVT) /* \_SB_.PC00.TCPU.CPNU.CNVT */
            }
            Else
            {
                CNVT *= 0x03E8
                RMDR *= 0x03E8
                RMDR /= PPUU
                CNVT += RMDR /* \_SB_.PC00.TCPU.CPNU.RMDR */
                Return (CNVT) /* \_SB_.PC00.TCPU.CPNU.CNVT */
            }
        }

        Method (CPLX, 0, NotSerialized)
        {
            \_SB.PC00.TCPU.NPCC [Zero] = 0x02
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [Zero] = Zero
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [One] = 0x7D
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [0x02] = CPNU (\_SB.PL1X, One)
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [0x03] = (\_SB.PLWX * 0x03E8)
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [0x04] = ((\_SB.PLWX * 0x03E8
                ) + 0x0FA0)
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [0x05] = PPSZ /* \_SB_.PPSZ */
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [Zero] = One
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [One] = CPNU (\_SB.PL2X, One)
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [0x02] = CPNU (\_SB.PL2X, One)
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [0x03] = Zero
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [0x04] = Zero
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [0x05] = PPSZ /* \_SB_.PPSZ */
        }

        Name (LSTM, Zero)
        Name (_PPC, Zero)  // _PPC: Performance Present Capabilities
        Method (SPUR, 1, NotSerialized)
        {
            ADBG (Concatenate ("SPUR, Arg0=", ToDecimalString (Arg0)))
            If ((Arg0 <= \TCNT))
            {
                If ((\_SB.PAGD._STA () == 0x0F))
                {
                    \_SB.PAGD._PUR [One] = Arg0
                    Notify (\_SB.PAGD, 0x80) // Status Change
                }
            }
        }

        Method (PCCC, 0, Serialized)
        {
            PCCX [Zero] = One
            Switch (ToInteger (CPNU (PTDP, Zero)))
            {
                Case (0x39)
                {
                    DerefOf (PCCX [One]) [Zero] = 0xA7F8
                    DerefOf (PCCX [One]) [One] = 0x00017318
                }
                Case (0x2F)
                {
                    DerefOf (PCCX [One]) [Zero] = 0x9858
                    DerefOf (PCCX [One]) [One] = 0x00014C08
                }
                Case (0x25)
                {
                    DerefOf (PCCX [One]) [Zero] = 0x7148
                    DerefOf (PCCX [One]) [One] = 0xD6D8
                }
                Case (0x19)
                {
                    DerefOf (PCCX [One]) [Zero] = 0x3E80
                    DerefOf (PCCX [One]) [One] = 0x7D00
                }
                Case (0x0F)
                {
                    DerefOf (PCCX [One]) [Zero] = 0x36B0
                    DerefOf (PCCX [One]) [One] = 0x7D00
                }
                Case (0x0B)
                {
                    DerefOf (PCCX [One]) [Zero] = 0x36B0
                    DerefOf (PCCX [One]) [One] = 0x61A8
                }
                Default
                {
                    DerefOf (PCCX [One]) [Zero] = 0xFF
                    DerefOf (PCCX [One]) [One] = 0xFF
                }

            }

            Return (PCCX) /* \_SB_.PC00.TCPU.PCCX */
        }

        Name (PCCX, Package (0x02)
        {
            0x80000000, 
            Package (0x02)
            {
                0x80000000, 
                0x80000000
            }
        })
        Name (KEFF, Package (0x1E)
        {
            Package (0x02)
            {
                0x01BC, 
                Zero
            }, 

            Package (0x02)
            {
                0x01CF, 
                0x27
            }, 

            Package (0x02)
            {
                0x01E1, 
                0x4B
            }, 

            Package (0x02)
            {
                0x01F3, 
                0x6C
            }, 

            Package (0x02)
            {
                0x0206, 
                0x8B
            }, 

            Package (0x02)
            {
                0x0218, 
                0xA8
            }, 

            Package (0x02)
            {
                0x022A, 
                0xC3
            }, 

            Package (0x02)
            {
                0x023D, 
                0xDD
            }, 

            Package (0x02)
            {
                0x024F, 
                0xF4
            }, 

            Package (0x02)
            {
                0x0261, 
                0x010B
            }, 

            Package (0x02)
            {
                0x0274, 
                0x011F
            }, 

            Package (0x02)
            {
                0x032C, 
                0x01BD
            }, 

            Package (0x02)
            {
                0x03D7, 
                0x0227
            }, 

            Package (0x02)
            {
                0x048B, 
                0x026D
            }, 

            Package (0x02)
            {
                0x053E, 
                0x02A1
            }, 

            Package (0x02)
            {
                0x05F7, 
                0x02C6
            }, 

            Package (0x02)
            {
                0x06A8, 
                0x02E6
            }, 

            Package (0x02)
            {
                0x075D, 
                0x02FF
            }, 

            Package (0x02)
            {
                0x0818, 
                0x0311
            }, 

            Package (0x02)
            {
                0x08CF, 
                0x0322
            }, 

            Package (0x02)
            {
                0x179C, 
                0x0381
            }, 

            Package (0x02)
            {
                0x2DDC, 
                0x039C
            }, 

            Package (0x02)
            {
                0x44A8, 
                0x039E
            }, 

            Package (0x02)
            {
                0x5C35, 
                0x0397
            }, 

            Package (0x02)
            {
                0x747D, 
                0x038D
            }, 

            Package (0x02)
            {
                0x8D7F, 
                0x0382
            }, 

            Package (0x02)
            {
                0xA768, 
                0x0376
            }, 

            Package (0x02)
            {
                0xC23B, 
                0x0369
            }, 

            Package (0x02)
            {
                0xDE26, 
                0x035A
            }, 

            Package (0x02)
            {
                0xFB7C, 
                0x034A
            }
        })
        Name (CEUP, Package (0x06)
        {
            0x80000000, 
            0x80000000, 
            0x80000000, 
            0x80000000, 
            0x80000000, 
            0x80000000
        })
        Method (_TMP, 0, Serialized)  // _TMP: Temperature
        {
            Return (\_SB.IETM.CTOK (PCTP))
        }

        Method (_DTI, 1, NotSerialized)  // _DTI: Device Temperature Indication
        {
            LSTM = Arg0
            Notify (\_SB.PC00.TCPU, 0x91) // Device-Specific
        }

        Method (_NTT, 0, NotSerialized)  // _NTT: Notification Temperature Threshold
        {
            Return (0x0ADE)
        }

        Name (PTYP, Zero)
        Method (_PSS, 0, NotSerialized)  // _PSS: Performance Supported States
        {
            If (CondRefOf (\_SB.PR00._PSS))
            {
                Return (\_SB.PR00._PSS ())
            }
            Else
            {
                Return (Package (0x02)
                {
                    Package (0x06)
                    {
                        Zero, 
                        Zero, 
                        Zero, 
                        Zero, 
                        Zero, 
                        Zero
                    }, 

                    Package (0x06)
                    {
                        Zero, 
                        Zero, 
                        Zero, 
                        Zero, 
                        Zero, 
                        Zero
                    }
                })
            }
        }

        Method (_TSS, 0, NotSerialized)  // _TSS: Throttling Supported States
        {
            If (CondRefOf (\_SB.PR00._TSS))
            {
                Return (\_SB.PR00._TSS ())
            }
            Else
            {
                Return (Package (0x01)
                {
                    Package (0x05)
                    {
                        One, 
                        Zero, 
                        Zero, 
                        Zero, 
                        Zero
                    }
                })
            }
        }

        Method (_TPC, 0, NotSerialized)  // _TPC: Throttling Present Capabilities
        {
            If (CondRefOf (\_SB.PR00._TPC))
            {
                Return (\_SB.PR00._TPC) /* External reference */
            }
            Else
            {
                Return (Zero)
            }
        }

        Method (_PTC, 0, NotSerialized)  // _PTC: Processor Throttling Control
        {
            Return (Package (0x02)
            {
                ResourceTemplate ()
                {
                    Register (FFixedHW, 
                        0x00,               // Bit Width
                        0x00,               // Bit Offset
                        0x0000000000000000, // Address
                        ,)
                }, 

                ResourceTemplate ()
                {
                    Register (FFixedHW, 
                        0x00,               // Bit Width
                        0x00,               // Bit Offset
                        0x0000000000000000, // Address
                        ,)
                }
            })
        }

        Method (_TSD, 0, NotSerialized)  // _TSD: Throttling State Dependencies
        {
            If (CondRefOf (\_SB.PR00._TSD))
            {
                Return (\_SB.PR00._TSD ())
            }
            Else
            {
                Return (Package (0x01)
                {
                    Package (0x05)
                    {
                        0x05, 
                        Zero, 
                        Zero, 
                        0xFC, 
                        Zero
                    }
                })
            }
        }

        Method (_TDL, 0, NotSerialized)  // _TDL: T-State Depth Limit
        {
            If ((CondRefOf (\_SB.PR00._TSS) && CondRefOf (\_SB.CFGD)))
            {
                If ((\_SB.CFGD & 0x2000))
                {
                    Return ((SizeOf (\_SB.PR00.TSMF) - One))
                }
                Else
                {
                    Return ((SizeOf (\_SB.PR00.TSMC) - One))
                }
            }
            Else
            {
                Return (Zero)
            }
        }

        Method (_PDL, 0, NotSerialized)  // _PDL: P-state Depth Limit
        {
            If (CondRefOf (\_SB.PR00._PSS))
            {
                If ((\_SB.OSCP & 0x0400))
                {
                    Return ((SizeOf (\_SB.PR00.TPSS) - One))
                }
                Else
                {
                    Return ((SizeOf (\_SB.PR00.LPSS) - One))
                }
            }
            Else
            {
                Return (Zero)
            }
        }

        Name (TJMX, 0x6E)
        Method (_TSP, 0, Serialized)  // _TSP: Thermal Sampling Period
        {
            Return (Zero)
        }

        Method (_AC0, 0, Serialized)  // _ACx: Active Cooling, x=0-9
        {
            Local1 = \_SB.IETM.CTOK (TJMX)
            Local1 -= 0x0A
            If ((LSTM >= Local1))
            {
                Return ((Local1 - 0x14))
            }
            Else
            {
                Return (Local1)
            }
        }

        Method (_AC1, 0, Serialized)  // _ACx: Active Cooling, x=0-9
        {
            Local1 = \_SB.IETM.CTOK (TJMX)
            Local1 -= 0x1E
            If ((LSTM >= Local1))
            {
                Return ((Local1 - 0x14))
            }
            Else
            {
                Return (Local1)
            }
        }

        Method (_AC2, 0, Serialized)  // _ACx: Active Cooling, x=0-9
        {
            Local1 = \_SB.IETM.CTOK (TJMX)
            Local1 -= 0x28
            If ((LSTM >= Local1))
            {
                Return ((Local1 - 0x14))
            }
            Else
            {
                Return (Local1)
            }
        }

        Method (_AC3, 0, Serialized)  // _ACx: Active Cooling, x=0-9
        {
            Local1 = \_SB.IETM.CTOK (TJMX)
            Local1 -= 0x37
            If ((LSTM >= Local1))
            {
                Return ((Local1 - 0x14))
            }
            Else
            {
                Return (Local1)
            }
        }

        Method (_AC4, 0, Serialized)  // _ACx: Active Cooling, x=0-9
        {
            Local1 = \_SB.IETM.CTOK (TJMX)
            Local1 -= 0x46
            If ((LSTM >= Local1))
            {
                Return ((Local1 - 0x14))
            }
            Else
            {
                Return (Local1)
            }
        }

        Method (_PSV, 0, Serialized)  // _PSV: Passive Temperature
        {
            Return (\_SB.IETM.CTOK (TJMX))
        }

        Method (_CRT, 0, Serialized)  // _CRT: Critical Temperature
        {
            Return (\_SB.IETM.CTOK (TJMX))
        }

        Method (_CR3, 0, Serialized)  // _CR3: Warm/Standby Temperature
        {
            Return (\_SB.IETM.CTOK (TJMX))
        }

        Method (_HOT, 0, Serialized)  // _HOT: Hot Temperature
        {
            Return (\_SB.IETM.CTOK (TJMX))
        }

        Method (UVTH, 1, Serialized)
        {
            If (CondRefOf (\_SB.DPTF.UVTH))
            {
                \_SB.DPTF.UVTH (Arg0)
                Return (Zero)
            }

            ADBG ("UVTH not available")
        }
    }

    Scope (\_SB.IETM)
    {
        Name (CTSP, Package (0x01)
        {
            ToUUID ("e145970a-e4c1-4d73-900e-c9c5a69dd067") /* Unknown UUID */
        })
    }

    Scope (\_SB.PC00.TCPU)
    {
        Name (MAXT, Zero)
        Method (TDPC, 0, NotSerialized)
        {
            Return (MAXT) /* \_SB_.PC00.TCPU.MAXT */
        }
    }

    Scope (\_SB.IETM)
    {
        Name (DP2P, Package (0x01)
        {
            ToUUID ("9e04115a-ae87-4d1c-9500-0f3e340bfe75") /* Unknown UUID */
        })
        Name (DPSP, Package (0x01)
        {
            ToUUID ("42a441d6-ae6a-462b-a84b-4a8ce79027d3") /* Unknown UUID */
        })
        Name (DASP, Package (0x01)
        {
            ToUUID ("3a95c389-e4b8-4629-a526-c52c88626bae") /* Unknown UUID */
        })
        Name (DA2P, Package (0x01)
        {
            ToUUID ("0e56fab6-bdfc-4e8c-8246-40ecfd4d74ea") /* Unknown UUID */
        })
        Name (DCSP, Package (0x01)
        {
            ToUUID ("97c68ae7-15fa-499c-b8c9-5da81d606e0a") /* Unknown UUID */
        })
        Name (RFIP, Package (0x01)
        {
            ToUUID ("c4ce1849-243a-49f3-b8d5-f97002f38e6a") /* Unknown UUID */
        })
        Name (POBP, Package (0x01)
        {
            ToUUID ("f5a35014-c209-46a4-993a-eb56de7530a1") /* Unknown UUID */
        })
        Name (DAPP, Package (0x01)
        {
            ToUUID ("63be270f-1c11-48fd-a6f7-3af253ff3e2d") /* Unknown UUID */
        })
        Name (DVSP, Package (0x01)
        {
            ToUUID ("6ed722a7-9240-48a5-b479-31eef723d7cf") /* Unknown UUID */
        })
        Name (DPID, Package (0x01)
        {
            ToUUID ("42496e14-bc1b-46e8-a798-ca915464426f") /* Unknown UUID */
        })
    }

    Scope (\_SB.IETM)
    {
        Method (TEVT, 2, Serialized)
        {
            Switch (ToString (Arg0, Ones))
            {
                Case ("IETM")
                {
                    Notify (\_SB.IETM, Arg1)
                }
                Case ("TCPU")
                {
                    Notify (\_SB.PC00.TCPU, Arg1)
                }

            }

            If (CondRefOf (\_SB.PC00.LPCB.H_EC))
            {
                Switch (ToString (Arg0, Ones))
                {
                    Case ("CHRG")
                    {
                        Notify (\_SB.IETM.CHRG, Arg1)
                    }
                    Case ("TFN1")
                    {
                        Notify (\_SB.IETM.TFN1, Arg1)
                    }
                    Case ("TPWR")
                    {
                        Notify (\_SB.IETM.TPWR, Arg1)
                    }
                    Case ("SEN1")
                    {
                        Notify (\_SB.IETM.SEN1, Arg1)
                    }
                    Case ("SEN2")
                    {
                        Notify (\_SB.IETM.SEN2, Arg1)
                    }
                    Case ("SEN3")
                    {
                        Notify (\_SB.IETM.SEN3, Arg1)
                    }
                    Case ("SEN4")
                    {
                        Notify (\_SB.IETM.SEN4, Arg1)
                    }
                    Case ("SEN5")
                    {
                        Notify (\_SB.IETM.SEN5, Arg1)
                    }
                    Case ("SEN6")
                    {
                        Notify (\_SB.IETM.SEN6, Arg1)
                    }
                    Case ("SEN7")
                    {
                        Notify (\_SB.IETM.SEN7, Arg1)
                    }

                }
            }
        }
    }

    ADBG ("[Dptf DptfTabl SSDT][AcpiTableExit]")
    Debug = "[Dptf DptfTabl SSDT][AcpiTableExit]"
    Debug = Timer
}

