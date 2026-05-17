/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20251212 (64-bit version)
 * Copyright (c) 2000 - 2025 Intel Corporation
 * 
 * Disassembly of APIC.aml
 *
 * ACPI Data Table [APIC]
 *
 * Format: [HexOffset DecimalOffset ByteLength]  FieldName : FieldValue (in hex)
 */

[000h 0000 004h]                   Signature : "APIC"    [Multiple APIC Description Table (MADT)]
[004h 0004 004h]                Table Length : 00000158
[008h 0008 001h]                    Revision : 06
[009h 0009 001h]                    Checksum : 5A
[00Ah 0010 006h]                      Oem ID : "HONOR"
[010h 0016 008h]                Oem Table ID : "PTL"
[018h 0024 004h]                Oem Revision : 00000002
[01Ch 0028 004h]             Asl Compiler ID : "ACPI"
[020h 0032 004h]       Asl Compiler Revision : 00040000

[024h 0036 004h]          Local Apic Address : FEE00000
[028h 0040 004h]       Flags (decoded below) : 00000001
                         PC-AT Compatibility : 1

[02Ch 0044 001h]               Subtable Type : 09 [Processor Local x2APIC]
[02Dh 0045 001h]                      Length : 10
[02Eh 0046 002h]                    Reserved : 0000
[030h 0048 004h]         Processor x2Apic ID : 00000000
[034h 0052 004h]       Flags (decoded below) : 00000001
                           Processor Enabled : 1
[038h 0056 004h]               Processor UID : 00000000

[03Ch 0060 001h]               Subtable Type : 09 [Processor Local x2APIC]
[03Dh 0061 001h]                      Length : 10
[03Eh 0062 002h]                    Reserved : 0000
[040h 0064 004h]         Processor x2Apic ID : 00000008
[044h 0068 004h]       Flags (decoded below) : 00000001
                           Processor Enabled : 1
[048h 0072 004h]               Processor UID : 00000001

[04Ch 0076 001h]               Subtable Type : 09 [Processor Local x2APIC]
[04Dh 0077 001h]                      Length : 10
[04Eh 0078 002h]                    Reserved : 0000
[050h 0080 004h]         Processor x2Apic ID : 00000010
[054h 0084 004h]       Flags (decoded below) : 00000001
                           Processor Enabled : 1
[058h 0088 004h]               Processor UID : 00000002

[05Ch 0092 001h]               Subtable Type : 09 [Processor Local x2APIC]
[05Dh 0093 001h]                      Length : 10
[05Eh 0094 002h]                    Reserved : 0000
[060h 0096 004h]         Processor x2Apic ID : 00000018
[064h 0100 004h]       Flags (decoded below) : 00000001
                           Processor Enabled : 1
[068h 0104 004h]               Processor UID : 00000003

[06Ch 0108 001h]               Subtable Type : 09 [Processor Local x2APIC]
[06Dh 0109 001h]                      Length : 10
[06Eh 0110 002h]                    Reserved : 0000
[070h 0112 004h]         Processor x2Apic ID : 00000020
[074h 0116 004h]       Flags (decoded below) : 00000001
                           Processor Enabled : 1
[078h 0120 004h]               Processor UID : 00000004

[07Ch 0124 001h]               Subtable Type : 09 [Processor Local x2APIC]
[07Dh 0125 001h]                      Length : 10
[07Eh 0126 002h]                    Reserved : 0000
[080h 0128 004h]         Processor x2Apic ID : 00000022
[084h 0132 004h]       Flags (decoded below) : 00000001
                           Processor Enabled : 1
[088h 0136 004h]               Processor UID : 00000005

[08Ch 0140 001h]               Subtable Type : 09 [Processor Local x2APIC]
[08Dh 0141 001h]                      Length : 10
[08Eh 0142 002h]                    Reserved : 0000
[090h 0144 004h]         Processor x2Apic ID : 00000024
[094h 0148 004h]       Flags (decoded below) : 00000001
                           Processor Enabled : 1
[098h 0152 004h]               Processor UID : 00000006

[09Ch 0156 001h]               Subtable Type : 09 [Processor Local x2APIC]
[09Dh 0157 001h]                      Length : 10
[09Eh 0158 002h]                    Reserved : 0000
[0A0h 0160 004h]         Processor x2Apic ID : 00000026
[0A4h 0164 004h]       Flags (decoded below) : 00000001
                           Processor Enabled : 1
[0A8h 0168 004h]               Processor UID : 00000007

[0ACh 0172 001h]               Subtable Type : 09 [Processor Local x2APIC]
[0ADh 0173 001h]                      Length : 10
[0AEh 0174 002h]                    Reserved : 0000
[0B0h 0176 004h]         Processor x2Apic ID : 00000028
[0B4h 0180 004h]       Flags (decoded below) : 00000001
                           Processor Enabled : 1
[0B8h 0184 004h]               Processor UID : 00000008

[0BCh 0188 001h]               Subtable Type : 09 [Processor Local x2APIC]
[0BDh 0189 001h]                      Length : 10
[0BEh 0190 002h]                    Reserved : 0000
[0C0h 0192 004h]         Processor x2Apic ID : 0000002A
[0C4h 0196 004h]       Flags (decoded below) : 00000001
                           Processor Enabled : 1
[0C8h 0200 004h]               Processor UID : 00000009

[0CCh 0204 001h]               Subtable Type : 09 [Processor Local x2APIC]
[0CDh 0205 001h]                      Length : 10
[0CEh 0206 002h]                    Reserved : 0000
[0D0h 0208 004h]         Processor x2Apic ID : 0000002C
[0D4h 0212 004h]       Flags (decoded below) : 00000001
                           Processor Enabled : 1
[0D8h 0216 004h]               Processor UID : 0000000A

[0DCh 0220 001h]               Subtable Type : 09 [Processor Local x2APIC]
[0DDh 0221 001h]                      Length : 10
[0DEh 0222 002h]                    Reserved : 0000
[0E0h 0224 004h]         Processor x2Apic ID : 0000002E
[0E4h 0228 004h]       Flags (decoded below) : 00000001
                           Processor Enabled : 1
[0E8h 0232 004h]               Processor UID : 0000000B

[0ECh 0236 001h]               Subtable Type : 09 [Processor Local x2APIC]
[0EDh 0237 001h]                      Length : 10
[0EEh 0238 002h]                    Reserved : 0000
[0F0h 0240 004h]         Processor x2Apic ID : 00000040
[0F4h 0244 004h]       Flags (decoded below) : 00000001
                           Processor Enabled : 1
[0F8h 0248 004h]               Processor UID : 0000000C

[0FCh 0252 001h]               Subtable Type : 09 [Processor Local x2APIC]
[0FDh 0253 001h]                      Length : 10
[0FEh 0254 002h]                    Reserved : 0000
[100h 0256 004h]         Processor x2Apic ID : 00000042
[104h 0260 004h]       Flags (decoded below) : 00000001
                           Processor Enabled : 1
[108h 0264 004h]               Processor UID : 0000000D

[10Ch 0268 001h]               Subtable Type : 09 [Processor Local x2APIC]
[10Dh 0269 001h]                      Length : 10
[10Eh 0270 002h]                    Reserved : 0000
[110h 0272 004h]         Processor x2Apic ID : 00000044
[114h 0276 004h]       Flags (decoded below) : 00000001
                           Processor Enabled : 1
[118h 0280 004h]               Processor UID : 0000000E

[11Ch 0284 001h]               Subtable Type : 09 [Processor Local x2APIC]
[11Dh 0285 001h]                      Length : 10
[11Eh 0286 002h]                    Reserved : 0000
[120h 0288 004h]         Processor x2Apic ID : 00000046
[124h 0292 004h]       Flags (decoded below) : 00000001
                           Processor Enabled : 1
[128h 0296 004h]               Processor UID : 0000000F

[12Ch 0300 001h]               Subtable Type : 01 [I/O APIC]
[12Dh 0301 001h]                      Length : 0C
[12Eh 0302 001h]                 I/O Apic ID : 02
[12Fh 0303 001h]                    Reserved : 00
[130h 0304 004h]                     Address : FEC00000
[134h 0308 004h]                   Interrupt : 00000000

[138h 0312 001h]               Subtable Type : 02 [Interrupt Source Override]
[139h 0313 001h]                      Length : 0A
[13Ah 0314 001h]                         Bus : 00
[13Bh 0315 001h]                      Source : 00
[13Ch 0316 004h]                   Interrupt : 00000002
[140h 0320 002h]       Flags (decoded below) : 0000
                                    Polarity : 0
                                Trigger Mode : 0

[142h 0322 001h]               Subtable Type : 02 [Interrupt Source Override]
[143h 0323 001h]                      Length : 0A
[144h 0324 001h]                         Bus : 00
[145h 0325 001h]                      Source : 09
[146h 0326 004h]                   Interrupt : 00000009
[14Ah 0330 002h]       Flags (decoded below) : 000D
                                    Polarity : 1
                                Trigger Mode : 3

[14Ch 0332 001h]               Subtable Type : 0A [Local x2APIC NMI]
[14Dh 0333 001h]                      Length : 0C
[14Eh 0334 002h]       Flags (decoded below) : 000D
                                    Polarity : 1
                                Trigger Mode : 3
[150h 0336 004h]               Processor UID : FFFFFFFF
[154h 0340 001h]        Interrupt Input LINT : 01
[155h 0341 003h]                    Reserved : 000000

Raw Table Data: Length 344 (0x158)

    0000: 41 50 49 43 58 01 00 00 06 5A 48 4F 4E 4F 52 00  // APICX....ZHONOR.
    0010: 50 54 4C 00 00 00 00 00 02 00 00 00 41 43 50 49  // PTL.........ACPI
    0020: 00 00 04 00 00 00 E0 FE 01 00 00 00 09 10 00 00  // ................
    0030: 00 00 00 00 01 00 00 00 00 00 00 00 09 10 00 00  // ................
    0040: 08 00 00 00 01 00 00 00 01 00 00 00 09 10 00 00  // ................
    0050: 10 00 00 00 01 00 00 00 02 00 00 00 09 10 00 00  // ................
    0060: 18 00 00 00 01 00 00 00 03 00 00 00 09 10 00 00  // ................
    0070: 20 00 00 00 01 00 00 00 04 00 00 00 09 10 00 00  //  ...............
    0080: 22 00 00 00 01 00 00 00 05 00 00 00 09 10 00 00  // "...............
    0090: 24 00 00 00 01 00 00 00 06 00 00 00 09 10 00 00  // $...............
    00A0: 26 00 00 00 01 00 00 00 07 00 00 00 09 10 00 00  // &...............
    00B0: 28 00 00 00 01 00 00 00 08 00 00 00 09 10 00 00  // (...............
    00C0: 2A 00 00 00 01 00 00 00 09 00 00 00 09 10 00 00  // *...............
    00D0: 2C 00 00 00 01 00 00 00 0A 00 00 00 09 10 00 00  // ,...............
    00E0: 2E 00 00 00 01 00 00 00 0B 00 00 00 09 10 00 00  // ................
    00F0: 40 00 00 00 01 00 00 00 0C 00 00 00 09 10 00 00  // @...............
    0100: 42 00 00 00 01 00 00 00 0D 00 00 00 09 10 00 00  // B...............
    0110: 44 00 00 00 01 00 00 00 0E 00 00 00 09 10 00 00  // D...............
    0120: 46 00 00 00 01 00 00 00 0F 00 00 00 01 0C 02 00  // F...............
    0130: 00 00 C0 FE 00 00 00 00 02 0A 00 00 02 00 00 00  // ................
    0140: 00 00 02 0A 00 09 09 00 00 00 0D 00 0A 0C 0D 00  // ................
    0150: FF FF FF FF 01 00 00 00                          // ........
