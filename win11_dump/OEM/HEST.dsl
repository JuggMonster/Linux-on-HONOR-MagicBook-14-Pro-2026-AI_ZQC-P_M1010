/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20251212 (64-bit version)
 * Copyright (c) 2000 - 2025 Intel Corporation
 * 
 * Disassembly of HEST.aml
 *
 * ACPI Data Table [HEST]
 *
 * Format: [HexOffset DecimalOffset ByteLength]  FieldName : FieldValue (in hex)
 */

[000h 0000 004h]                   Signature : "HEST"    [Hardware Error Source Table]
[004h 0004 004h]                Table Length : 00000054
[008h 0008 001h]                    Revision : 02
[009h 0009 001h]                    Checksum : F3
[00Ah 0010 006h]                      Oem ID : "HONOR"
[010h 0016 008h]                Oem Table ID : "PTL"
[018h 0024 004h]                Oem Revision : 00000002
[01Ch 0028 004h]             Asl Compiler ID : "ACPI"
[020h 0032 004h]       Asl Compiler Revision : 00040000

[024h 0036 004h]          Error Source Count : 00000001

[028h 0040 002h]               Subtable Type : 0007 [PCI Express AER (AER Endpoint)]
[02Ah 0042 002h]                   Source Id : 0000
[02Ch 0044 002h]                    Reserved : 0000
[02Eh 0046 001h]       Flags (decoded below) : 03
                              Firmware First : 1
                                      Global : 1
[02Fh 0047 001h]                     Enabled : 00
[030h 0048 004h]      Records To Preallocate : 00000001
[034h 0052 004h]     Max Sections Per Record : 00000001
[038h 0056 004h]                         Bus : 00000000
[03Ch 0060 002h]                      Device : 0000
[03Eh 0062 002h]                    Function : 0000
[040h 0064 002h]               DeviceControl : 0007
[042h 0066 002h]                    Reserved : 0000
[044h 0068 004h]          Uncorrectable Mask : 00000000
[048h 0072 004h]      Uncorrectable Severity : 00062030
[04Ch 0076 004h]            Correctable Mask : 00008000
[050h 0080 004h]       Advanced Capabilities : 00000000

Raw Table Data: Length 84 (0x54)

    0000: 48 45 53 54 54 00 00 00 02 F3 48 4F 4E 4F 52 00  // HESTT.....HONOR.
    0010: 50 54 4C 00 00 00 00 00 02 00 00 00 41 43 50 49  // PTL.........ACPI
    0020: 00 00 04 00 01 00 00 00 07 00 00 00 00 00 03 00  // ................
    0030: 01 00 00 00 01 00 00 00 00 00 00 00 00 00 00 00  // ................
    0040: 07 00 00 00 00 00 00 00 30 20 06 00 00 80 00 00  // ........0 ......
    0050: 00 00 00 00                                      // ....
