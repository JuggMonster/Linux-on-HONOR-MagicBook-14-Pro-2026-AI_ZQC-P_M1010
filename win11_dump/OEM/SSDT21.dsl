/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20251212 (64-bit version)
 * Copyright (c) 2000 - 2025 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of SSDT21.aml
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x000013D9 (5081)
 *     Revision         0x01
 *     Checksum         0xA1
 *     OEM ID           "HONOR"
 *     OEM Table ID     "WmiTable"
 *     OEM Revision     0x00001000 (4096)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20200717 (538969879)
 */
DefinitionBlock ("", "SSDT", 1, "HONOR", "WmiTable", 0x00001000)
{
    External (AVMF, MethodObj)    // 1 Arguments
    External (DTGT, MethodObj)    // 1 Arguments
    External (GADI, MethodObj)    // 1 Arguments
    External (GAIT, MethodObj)    // 1 Arguments
    External (GAOP, MethodObj)    // 1 Arguments
    External (GBAD, MethodObj)    // 1 Arguments
    External (GBAF, MethodObj)    // 1 Arguments
    External (GBAI, MethodObj)    // 1 Arguments
    External (GBCM, MethodObj)    // 1 Arguments
    External (GBTM, MethodObj)    // 1 Arguments
    External (GBTT, MethodObj)    // 1 Arguments
    External (GCFD, MethodObj)    // 1 Arguments
    External (GCII, MethodObj)    // 1 Arguments
    External (GCPL, MethodObj)    // 1 Arguments
    External (GCS_, MethodObj)    // 1 Arguments
    External (GCTS, MethodObj)    // 1 Arguments
    External (GCVA, MethodObj)    // 1 Arguments
    External (GDBV, MethodObj)    // 1 Arguments
    External (GDDS, MethodObj)    // 1 Arguments
    External (GDJC, MethodObj)    // 1 Arguments
    External (GDNF, MethodObj)    // 1 Arguments
    External (GDPM, MethodObj)    // 1 Arguments
    External (GDXD, MethodObj)    // 1 Arguments
    External (GEAG, MethodObj)    // 1 Arguments
    External (GECL, MethodObj)    // 1 Arguments
    External (GECV, MethodObj)    // 1 Arguments
    External (GEPH, MethodObj)    // 1 Arguments
    External (GESL, MethodObj)    // 1 Arguments
    External (GFCC, MethodObj)    // 1 Arguments
    External (GFCI, MethodObj)    // 1 Arguments
    External (GFNM, MethodObj)    // 1 Arguments
    External (GFNS, MethodObj)    // 1 Arguments
    External (GFRS, MethodObj)    // 1 Arguments
    External (GGSM, MethodObj)    // 1 Arguments
    External (GHCS, MethodObj)    // 1 Arguments
    External (GHMD, MethodObj)    // 1 Arguments
    External (GILC, MethodObj)    // 1 Arguments
    External (GKBM, MethodObj)    // 1 Arguments
    External (GKBT, MethodObj)    // 1 Arguments
    External (GKEY, MethodObj)    // 1 Arguments
    External (GLCF, MethodObj)    // 1 Arguments
    External (GLED, MethodObj)    // 1 Arguments
    External (GLGO, MethodObj)    // 1 Arguments
    External (GLIV, MethodObj)    // 1 Arguments
    External (GLOG, MethodObj)    // 1 Arguments
    External (GMIR, MethodObj)    // 1 Arguments
    External (GNTB, MethodObj)    // 1 Arguments
    External (GOAR, MethodObj)    // 1 Arguments
    External (GODP, MethodObj)    // 1 Arguments
    External (GOLR, MethodObj)    // 1 Arguments
    External (GOSF, MethodObj)    // 1 Arguments
    External (GPCI, MethodObj)    // 1 Arguments
    External (GPDV, MethodObj)    // 1 Arguments
    External (GPFM, MethodObj)    // 1 Arguments
    External (GPLO, MethodObj)    // 1 Arguments
    External (GPOB, MethodObj)    // 1 Arguments
    External (GPPT, MethodObj)    // 1 Arguments
    External (GPSI, MethodObj)    // 1 Arguments
    External (GRCS, MethodObj)    // 1 Arguments
    External (GSTP, MethodObj)    // 1 Arguments
    External (GSWL, MethodObj)    // 1 Arguments
    External (GTCC, MethodObj)    // 1 Arguments
    External (GTDG, MethodObj)    // 1 Arguments
    External (GTMP, MethodObj)    // 1 Arguments
    External (GTPS, MethodObj)    // 1 Arguments
    External (GTSI, MethodObj)    // 1 Arguments
    External (GTSS, MethodObj)    // 1 Arguments
    External (GTUB, MethodObj)    // 1 Arguments
    External (GVCG, MethodObj)    // 1 Arguments
    External (GVER, MethodObj)    // 1 Arguments
    External (GVNT, MethodObj)    // 1 Arguments
    External (GVRF, MethodObj)    // 1 Arguments
    External (GWAT, MethodObj)    // 1 Arguments
    External (HPDG, MethodObj)    // 1 Arguments
    External (IBTI, MethodObj)    // 1 Arguments
    External (IFCI, MethodObj)    // 1 Arguments
    External (ISIA, MethodObj)    // 1 Arguments
    External (MGMT, MethodObj)    // 1 Arguments
    External (RSBT, MethodObj)    // 1 Arguments
    External (SAKB, MethodObj)    // 1 Arguments
    External (SAOP, MethodObj)    // 1 Arguments
    External (SBAD, MethodObj)    // 1 Arguments
    External (SBCM, MethodObj)    // 1 Arguments
    External (SBTT, MethodObj)    // 1 Arguments
    External (SCFM, MethodObj)    // 1 Arguments
    External (SCTS, MethodObj)    // 1 Arguments
    External (SDBV, MethodObj)    // 1 Arguments
    External (SDDS, MethodObj)    // 1 Arguments
    External (SDNF, MethodObj)    // 1 Arguments
    External (SDPM, MethodObj)    // 1 Arguments
    External (SECL, MethodObj)    // 1 Arguments
    External (SECV, MethodObj)    // 1 Arguments
    External (SFIF, MethodObj)    // 1 Arguments
    External (SFNM, MethodObj)    // 1 Arguments
    External (SFNS, MethodObj)    // 1 Arguments
    External (SFRS, MethodObj)    // 1 Arguments
    External (SKBL, MethodObj)    // 1 Arguments
    External (SKBM, MethodObj)    // 1 Arguments
    External (SKBT, MethodObj)    // 1 Arguments
    External (SLED, MethodObj)    // 1 Arguments
    External (SLGO, MethodObj)    // 1 Arguments
    External (SLOG, MethodObj)    // 1 Arguments
    External (SMLS, MethodObj)    // 1 Arguments
    External (SNTB, MethodObj)    // 1 Arguments
    External (SOAR, MethodObj)    // 1 Arguments
    External (SODP, MethodObj)    // 1 Arguments
    External (SOSF, MethodObj)    // 1 Arguments
    External (SPDV, MethodObj)    // 1 Arguments
    External (SPFM, MethodObj)    // 1 Arguments
    External (SPLO, MethodObj)    // 1 Arguments
    External (SPLV, MethodObj)    // 1 Arguments
    External (SPPF, MethodObj)    // 1 Arguments
    External (SPPM, MethodObj)    // 1 Arguments
    External (SSLR, MethodObj)    // 1 Arguments
    External (SSTP, MethodObj)    // 1 Arguments
    External (SSWL, MethodObj)    // 1 Arguments
    External (STMP, MethodObj)    // 1 Arguments
    External (STMT, MethodObj)    // 1 Arguments
    External (STPS, MethodObj)    // 1 Arguments
    External (STSS, MethodObj)    // 1 Arguments
    External (STUB, MethodObj)    // 1 Arguments
    External (SVRF, MethodObj)    // 1 Arguments
    External (SWAT, MethodObj)    // 1 Arguments
    External (WKEY, MethodObj)    // 1 Arguments
    External (WLCF, MethodObj)    // 1 Arguments

    OperationRegion (HNVS, SystemMemory, 0x6FDBE000, 0x00002180)
    Field (HNVS, AnyAcc, NoLock, Preserve)
    {
        DAIN,   512, 
        DAOU,   2048, 
        DIN2,   33024, 
        DOU2,   33024
    }

    Scope (\_SB)
    {
        Mutex (MUTW, 0x00)
        Device (WMI1)
        {
            Name (_HID, EisaId ("PNP0C14") /* Windows Management Instrumentation Device */)  // _HID: Hardware ID
            Name (_UID, "HWMI")  // _UID: Unique ID
            Name (WMEN, Zero)
            Name (_WDG, Buffer (0x3C)
            {
                /* 0000 */  0x5B, 0x0F, 0xBC, 0xAB, 0xA1, 0x8E, 0xD1, 0x11,  // [.......
                /* 0008 */  0xA0, 0x00, 0xC9, 0x06, 0x29, 0x10, 0x00, 0x00,  // ....)...
                /* 0010 */  0x41, 0x41, 0x02, 0x02, 0x5C, 0x0F, 0xBC, 0xAB,  // AA..\...
                /* 0018 */  0xA1, 0x8E, 0xD1, 0x11, 0xA0, 0x00, 0xC9, 0x06,  // ........
                /* 0020 */  0x29, 0x10, 0x00, 0x00, 0xA0, 0x00, 0x01, 0x08,  // ).......
                /* 0028 */  0x21, 0x12, 0x90, 0x05, 0x66, 0xD5, 0xD1, 0x11,  // !...f...
                /* 0030 */  0xB2, 0xF0, 0x00, 0xA0, 0xC9, 0x06, 0x29, 0x10,  // ......).
                /* 0038 */  0x42, 0x41, 0x01, 0x00                           // BA..
            })
            Name (WQBA, Buffer (0x0444)
            {
                /* 0000 */  0x46, 0x4F, 0x4D, 0x42, 0x01, 0x00, 0x00, 0x00,  // FOMB....
                /* 0008 */  0x34, 0x04, 0x00, 0x00, 0x5C, 0x10, 0x00, 0x00,  // 4...\...
                /* 0010 */  0x44, 0x53, 0x00, 0x01, 0x1A, 0x7D, 0xDA, 0x54,  // DS...}.T
                /* 0018 */  0x18, 0xD0, 0x87, 0x00, 0x01, 0x06, 0x18, 0x42,  // .......B
                /* 0020 */  0x10, 0x05, 0x10, 0x12, 0xE4, 0x82, 0x42, 0x04,  // ......B.
                /* 0028 */  0x8A, 0x40, 0x24, 0x69, 0x0E, 0x60, 0x30, 0x1A,  // .@$i.`0.
                /* 0030 */  0x40, 0x24, 0x09, 0x42, 0x7C, 0x54, 0x80, 0x10,  // @$.B|T..
                /* 0038 */  0x08, 0x49, 0x14, 0x60, 0x5E, 0x80, 0x6E, 0x01,  // .I.`^.n.
                /* 0040 */  0x86, 0x05, 0xD8, 0x16, 0x60, 0x5A, 0x80, 0x63,  // ....`Z.c
                /* 0048 */  0x20, 0xF5, 0xEF, 0x0F, 0x2D, 0x10, 0x89, 0x80,  //  ...-...
                /* 0050 */  0xA4, 0x52, 0x20, 0x24, 0x54, 0x80, 0x72, 0x01,  // .R $T.r.
                /* 0058 */  0xBE, 0x05, 0x68, 0x47, 0x94, 0x64, 0x01, 0x96,  // ..hG.d..
                /* 0060 */  0x61, 0x44, 0x60, 0xAF, 0x02, 0x6C, 0x0A, 0x30,  // aD`..l.0
                /* 0068 */  0x89, 0x86, 0x20, 0x28, 0x67, 0x18, 0x28, 0x78,  // .. (g.(x
                /* 0070 */  0x03, 0xB2, 0x41, 0x30, 0xD1, 0x83, 0x40, 0x89,  // ..A0..@.
                /* 0078 */  0x19, 0x0D, 0x99, 0x41, 0xE7, 0x73, 0x11, 0xFC,  // ...A.s..
                /* 0080 */  0x49, 0x14, 0x2E, 0x40, 0x3A, 0x86, 0x46, 0x70,  // I..@:.Fp
                /* 0088 */  0x44, 0x09, 0x3A, 0x1C, 0x92, 0x64, 0x23, 0x48,  // D.:..d#H
                /* 0090 */  0x90, 0x00, 0x85, 0xF0, 0xF2, 0x29, 0xC0, 0x29,  // .....).)
                /* 0098 */  0x8A, 0x34, 0x0A, 0xB0, 0x0E, 0x27, 0xD8, 0x98,  // .4...'..
                /* 00A0 */  0x1C, 0x29, 0xCA, 0x41, 0x9C, 0x8D, 0xC1, 0x7A,  // .).A...z
                /* 00A8 */  0x46, 0x11, 0xD0, 0xA9, 0x70, 0x82, 0xE8, 0x87,  // F...p...
                /* 00B0 */  0x82, 0x91, 0x01, 0x21, 0x8F, 0x02, 0xAC, 0xA2,  // ...!....
                /* 00B8 */  0x69, 0x2E, 0x09, 0xEC, 0x5E, 0x80, 0xC1, 0x59,  // i...^..Y
                /* 00C0 */  0x08, 0xE1, 0x48, 0x0A, 0x13, 0xA0, 0x59, 0x80,  // ..H...Y.
                /* 00C8 */  0x35, 0x01, 0x8A, 0x05, 0xD8, 0x12, 0x20, 0x6E,  // 5..... n
                /* 00D0 */  0x48, 0x9A, 0x4C, 0x63, 0x28, 0x82, 0x88, 0x70,  // H.Lc(..p
                /* 00D8 */  0x9C, 0x51, 0x8C, 0x19, 0x30, 0x82, 0x51, 0x8E,  // .Q..0.Q.
                /* 00E0 */  0xA6, 0x39, 0x10, 0x69, 0x13, 0xA0, 0x0C, 0x44,  // .9.i...D
                /* 00E8 */  0x68, 0xB1, 0x18, 0x82, 0xED, 0x0F, 0x82, 0x8C,  // h.......
                /* 00F0 */  0x1C, 0x77, 0x04, 0xF0, 0x78, 0x4E, 0x2A, 0xF2,  // .w..xN*.
                /* 00F8 */  0x01, 0x7A, 0x14, 0x09, 0x3C, 0xAA, 0xF3, 0x2B,  // .z..<..+
                /* 0100 */  0x17, 0x57, 0xE2, 0x51, 0x85, 0x71, 0x02, 0x09,  // .W.Q.q..
                /* 0108 */  0x1C, 0xEC, 0x44, 0x20, 0x09, 0x20, 0x8A, 0x04,  // ..D . ..
                /* 0110 */  0x8F, 0x1A, 0x78, 0x82, 0xE3, 0xF7, 0xD0, 0x8E,  // ..x.....
                /* 0118 */  0xF3, 0xA8, 0x8F, 0xF3, 0x04, 0xCE, 0xD5, 0x23,  // .......#
                /* 0120 */  0xA8, 0xF3, 0x54, 0x40, 0xC6, 0xC0, 0xB0, 0x12,  // ..T@....
                /* 0128 */  0xFC, 0x21, 0xF8, 0x24, 0x80, 0x77, 0x0D, 0xA8,  // .!.$.w..
                /* 0130 */  0xFF, 0xFF, 0xFD, 0xE0, 0x49, 0x80, 0x0D, 0x39,  // ....I..9
                /* 0138 */  0x1C, 0x66, 0xBC, 0x9E, 0xF8, 0x71, 0x7A, 0x94,  // .f...qz.
                /* 0140 */  0x47, 0xC2, 0x20, 0x8E, 0xE8, 0xE0, 0xB0, 0x43,  // G. ....C
                /* 0148 */  0x3E, 0x99, 0x23, 0x2B, 0x55, 0x80, 0xD9, 0x13,  // >.#+U...
                /* 0150 */  0x82, 0x2C, 0x02, 0x69, 0x3C, 0x3E, 0x14, 0x78,  // .,.i<>.x
                /* 0158 */  0x3E, 0x6F, 0x01, 0x09, 0x2C, 0x7F, 0x10, 0xA8,  // >o..,...
                /* 0160 */  0x91, 0x19, 0xDA, 0xE3, 0x7E, 0x24, 0x60, 0x87,  // ....~$`.
                /* 0168 */  0x85, 0xC3, 0x62, 0x62, 0x0F, 0x13, 0x7C, 0x3C,  // ..bb..|<
                /* 0170 */  0xA0, 0xBF, 0x15, 0x1C, 0x7F, 0x84, 0xD3, 0xF7,  // ........
                /* 0178 */  0x7C, 0x4D, 0x50, 0x20, 0x30, 0x7A, 0x40, 0xF6,  // |MP 0z@.
                /* 0180 */  0x2B, 0x00, 0x21, 0x78, 0x99, 0x23, 0xD2, 0x31,  // +.!x.#.1
                /* 0188 */  0x20, 0x42, 0x82, 0xF7, 0x86, 0xB8, 0x07, 0xFE,  //  B......
                /* 0190 */  0xBC, 0xC0, 0x20, 0xC2, 0xBC, 0x35, 0x78, 0x04,  // .. ..5x.
                /* 0198 */  0x47, 0xC3, 0x44, 0x1E, 0x26, 0xD0, 0x03, 0xE0,  // G.D.&...
                /* 01A0 */  0xA7, 0x80, 0xF8, 0x61, 0x4F, 0xE6, 0x00, 0x0E,  // ...aO...
                /* 01A8 */  0x27, 0xCA, 0x39, 0x1C, 0x8F, 0xAF, 0x10, 0x46,  // '.9....F
                /* 01B0 */  0x88, 0xFF, 0x6C, 0xF0, 0x9C, 0xE1, 0x6B, 0xC3,  // ..l...k.
                /* 01B8 */  0x09, 0x3D, 0x46, 0x9C, 0xD2, 0xCB, 0x80, 0x09,  // .=F.....
                /* 01C0 */  0x86, 0xF5, 0x30, 0x50, 0x16, 0xF7, 0x3D, 0x20,  // ..0P..= 
                /* 01C8 */  0x1B, 0x2B, 0xF5, 0xA1, 0x83, 0xC6, 0xA5, 0xD2,  // .+......
                /* 01D0 */  0x80, 0x70, 0xD8, 0x4F, 0x16, 0x26, 0x18, 0x12,  // .p.O.&..
                /* 01D8 */  0x4C, 0x27, 0x12, 0x1E, 0x8F, 0x42, 0x22, 0x68,  // L'...B"h
                /* 01E0 */  0x34, 0x1E, 0x83, 0x3B, 0xF6, 0xC1, 0x84, 0x82,  // 4..;....
                /* 01E8 */  0x18, 0xD0, 0x99, 0x20, 0x64, 0x64, 0x14, 0xF4,  // ... dd..
                /* 01F0 */  0x20, 0xC0, 0x67, 0xF0, 0x52, 0xF1, 0xC8, 0xE0,  //  .g.R...
                /* 01F8 */  0x53, 0x47, 0x94, 0x13, 0x72, 0x02, 0x08, 0x1D,  // SG..r...
                /* 0200 */  0x1E, 0x3C, 0x42, 0x1F, 0x04, 0xF8, 0x09, 0xC5,  // .<B.....
                /* 0208 */  0x37, 0x03, 0x63, 0xFB, 0xD0, 0xE0, 0xFF, 0xFF,  // 7.c.....
                /* 0210 */  0x3F, 0x85, 0x0E, 0x96, 0x8C, 0xE9, 0x2C, 0x9F,  // ?.....,.
                /* 0218 */  0x0A, 0x7C, 0x00, 0xB0, 0x1A, 0x38, 0x14, 0xB4,  // .|...8..
                /* 0220 */  0x8F, 0x1C, 0x9C, 0xA0, 0xAC, 0x3B, 0x01, 0xF4,  // .....;..
                /* 0228 */  0xF1, 0x1C, 0x88, 0x07, 0x74, 0x4C, 0x09, 0xEA,  // ....tL..
                /* 0230 */  0xBB, 0x12, 0x80, 0x02, 0xC8, 0x87, 0x00, 0x2B,  // .......+
                /* 0238 */  0xBD, 0x07, 0xD0, 0x29, 0x84, 0x08, 0x13, 0xCD,  // ...)....
                /* 0240 */  0xE8, 0xFC, 0xB8, 0xE1, 0x21, 0xF3, 0x28, 0x30,  // ....!.(0
                /* 0248 */  0x1A, 0xB2, 0x41, 0x3C, 0x30, 0xC7, 0x81, 0x90,  // ..A<0...
                /* 0250 */  0x93, 0xA3, 0x04, 0x6A, 0xAC, 0x9E, 0x50, 0x67,  // ...j..Pg
                /* 0258 */  0xB7, 0x11, 0x8D, 0xE0, 0xCD, 0xC5, 0x07, 0x83,  // ........
                /* 0260 */  0x77, 0x09, 0x1F, 0x13, 0xD8, 0xB0, 0x1F, 0x39,  // w......9
                /* 0268 */  0x60, 0x9D, 0x59, 0x3C, 0x78, 0x4F, 0xC4, 0xA3,  // `.Y<xO..
                /* 0270 */  0xC6, 0x0F, 0x97, 0x8F, 0xC6, 0x47, 0x0A, 0xF8,  // .....G..
                /* 0278 */  0xD3, 0xE5, 0xF3, 0xF1, 0xF0, 0xC8, 0xC9, 0x00,  // ........
                /* 0280 */  0x7D, 0x5E, 0xF0, 0xC9, 0xC0, 0xE7, 0x85, 0x83,  // }^......
                /* 0288 */  0xF1, 0xCD, 0x80, 0x13, 0x0C, 0x71, 0x34, 0xA0,  // .....q4.
                /* 0290 */  0xC3, 0x02, 0xD7, 0xD9, 0x80, 0x2F, 0xCB, 0xA3,  // ...../..
                /* 0298 */  0x83, 0x77, 0x74, 0xF0, 0xDD, 0x00, 0xFE, 0xFF,  // .wt.....
                /* 02A0 */  0xFF, 0x6E, 0x80, 0x3B, 0x7E, 0x80, 0xE3, 0x6E,  // .n.;~..n
                /* 02A8 */  0x00, 0x13, 0x1E, 0x73, 0xB2, 0xB0, 0x85, 0xF1,  // ...s....
                /* 02B0 */  0xD0, 0x61, 0xF1, 0x63, 0x81, 0xEF, 0x1A, 0x6F,  // .a.c...o
                /* 02B8 */  0x4E, 0xBE, 0x8B, 0xE0, 0xC6, 0xF4, 0x5A, 0xE0,  // N.....Z.
                /* 02C0 */  0x73, 0x80, 0x61, 0x3D, 0x5E, 0x0E, 0x6B, 0xB4,  // s.a=^.k.
                /* 02C8 */  0xB0, 0x27, 0xFE, 0x94, 0xE2, 0x1B, 0x8E, 0x27,  // .'.....'
                /* 02D0 */  0xE6, 0x1B, 0x02, 0x3B, 0xDB, 0x80, 0x03, 0x10,  // ...;....
                /* 02D8 */  0xEF, 0xFD, 0x5A, 0x43, 0x26, 0x60, 0x40, 0x36,  // ..ZC&`@6
                /* 02E0 */  0xC7, 0x87, 0x28, 0xB0, 0x1C, 0x0D, 0x8E, 0xF3,  // ..(.....
                /* 02E8 */  0xDC, 0x5E, 0x9C, 0xF8, 0x19, 0x0A, 0x06, 0x81,  // .^......
                /* 02F0 */  0xA3, 0x9F, 0x53, 0x50, 0x63, 0x70, 0xE0, 0x73,  // ..SPcp.s
                /* 02F8 */  0x0A, 0xA4, 0x21, 0x3C, 0x22, 0x3D, 0xA8, 0x00,  // ..!<"=..
                /* 0300 */  0x26, 0x04, 0xAD, 0x41, 0x07, 0x15, 0xFE, 0xFF,  // &..A....
                /* 0308 */  0x3F, 0xA8, 0x00, 0xFC, 0x3C, 0x1B, 0xF8, 0xA0,  // ?...<...
                /* 0310 */  0x02, 0xDC, 0xFE, 0xFF, 0x07, 0x15, 0x70, 0xAE,  // ......p.
                /* 0318 */  0xDD, 0x07, 0x15, 0x70, 0x0D, 0x8D, 0x1F, 0x54,  // ...p...T
                /* 0320 */  0x80, 0xA7, 0xE0, 0x83, 0x0A, 0x68, 0x6F, 0x26,  // .....ho&
                /* 0328 */  0x9E, 0x81, 0xAF, 0x80, 0xBE, 0x3B, 0xF2, 0xD3,  // .....;..
                /* 0330 */  0x0A, 0x9C, 0x18, 0x6F, 0x04, 0x83, 0x78, 0xC8,  // ...o..x.
                /* 0338 */  0x12, 0x0E, 0x83, 0x3A, 0x78, 0x02, 0xEF, 0xE3,  // ...:x...
                /* 0340 */  0x86, 0x07, 0x0B, 0x8E, 0x81, 0x3E, 0x7B, 0xF8,  // .....>{.
                /* 0348 */  0x2C, 0xE0, 0x61, 0xBE, 0x19, 0x46, 0x31, 0xC4,  // ,.a..F1.
                /* 0350 */  0xFF, 0x3F, 0xE4, 0x71, 0x3D, 0x0F, 0x30, 0xA8,  // .?.q=.0.
                /* 0358 */  0x47, 0x80, 0xB7, 0x83, 0x58, 0x46, 0x39, 0xB7,  // G...XF9.
                /* 0360 */  0x58, 0x07, 0x10, 0xE7, 0xF9, 0xC1, 0x48, 0x81,  // X.....H.
                /* 0368 */  0x82, 0x1C, 0x44, 0x8C, 0x40, 0x3E, 0x5C, 0xF8,  // ..D.@>\.
                /* 0370 */  0xE8, 0x09, 0xAE, 0x19, 0x3C, 0x7A, 0x02, 0xE3,  // ....<z..
                /* 0378 */  0xC8, 0x8F, 0x09, 0x9D, 0x09, 0x7C, 0xF4, 0x04,  // .....|..
                /* 0380 */  0xF8, 0x11, 0x1D, 0x42, 0xFF, 0xFF, 0x73, 0x10,  // ...B..s.
                /* 0388 */  0x6E, 0x14, 0x3E, 0x6C, 0x44, 0x3C, 0x8C, 0xD3,  // n.>lD<..
                /* 0390 */  0x36, 0xC1, 0xA8, 0x83, 0xA6, 0xA2, 0x8E, 0x2A,  // 6......*
                /* 0398 */  0xA8, 0xC3, 0x85, 0x8F, 0x2A, 0xEC, 0xB0, 0xF0,  // ....*...
                /* 03A0 */  0xFA, 0x60, 0x88, 0x27, 0x34, 0xCC, 0x01, 0xC0,  // .`.'4...
                /* 03A8 */  0x47, 0x0A, 0x70, 0x8C, 0x04, 0x73, 0x9A, 0xF0,  // G.p..s..
                /* 03B0 */  0x29, 0xC2, 0x47, 0x62, 0xDF, 0x27, 0x7C, 0xF2,  // ).Gb.'|.
                /* 03B8 */  0x30, 0x8C, 0x91, 0x8C, 0xE7, 0x23, 0x05, 0x1E,  // 0....#..
                /* 03C0 */  0x32, 0xD0, 0x2B, 0x05, 0xEE, 0x74, 0x04, 0x46,  // 2.+..t.F
                /* 03C8 */  0x79, 0xE7, 0x56, 0xD0, 0x9D, 0x3E, 0x30, 0xC7,  // y.V..>0.
                /* 03D0 */  0x56, 0x60, 0x72, 0xF5, 0xF0, 0x10, 0xF8, 0x59,  // V`r....Y
                /* 03D8 */  0xC2, 0x43, 0xE0, 0x03, 0x78, 0x04, 0x39, 0x3B,  // .C..x.9;
                /* 03E0 */  0x1F, 0x86, 0xCE, 0x09, 0x77, 0x56, 0xE1, 0x53,  // ....wV.S
                /* 03E8 */  0xC2, 0x0D, 0x00, 0xA3, 0xD0, 0xA6, 0x4F, 0x8D,  // ......O.
                /* 03F0 */  0x46, 0xAD, 0x1A, 0x94, 0xA9, 0x51, 0xA6, 0x41,  // F....Q.A
                /* 03F8 */  0xAD, 0x3E, 0x95, 0x1A, 0x33, 0x66, 0xE4, 0x70,  // .>..3f.p
                /* 0400 */  0xE0, 0xB7, 0x83, 0x0E, 0x07, 0x8E, 0x04, 0x42,  // .......B
                /* 0408 */  0xC5, 0x9C, 0x6C, 0x04, 0x66, 0x65, 0x20, 0x02,  // ..l.fe .
                /* 0410 */  0xB2, 0x90, 0xF7, 0x91, 0x80, 0x2C, 0x0B, 0x44,  // .....,.D
                /* 0418 */  0xFF, 0x7F, 0x20, 0x47, 0x04, 0xA2, 0x81, 0x81,  // .. G....
                /* 0420 */  0x68, 0xF8, 0xE3, 0xAD, 0x80, 0xAC, 0x64, 0x25,  // h.....d%
                /* 0428 */  0x02, 0x72, 0x70, 0x10, 0x01, 0x59, 0x86, 0x89,  // .rp..Y..
                /* 0430 */  0x61, 0x50, 0x10, 0x01, 0x39, 0x20, 0x10, 0x15,  // aP..9 ..
                /* 0438 */  0x6A, 0x03, 0x84, 0xC5, 0x04, 0xA1, 0x01, 0x75,  // j......u
                /* 0440 */  0x80, 0xB0, 0xFF, 0x3F                           // ...?
            })
            Method (WMAA, 3, Serialized)
            {
                Acquire (MUTW, 0xFFFF)
                Local0 = Arg2
                CreateByteField (Local0, Zero, MFID)
                CreateByteField (Local0, One, SFID)
                If ((Arg1 == 0x02))
                {
                    Name (WRP2, Package (0x02)
                    {
                        Buffer (0x04){}, 
                        Buffer (0x1020){}
                    })
                    Local1 = DerefOf (WRP2 [One])
                    CreateByteField (Local1, Zero, STA2)
                    STA2 = 0xEE
                    If ((MFID == 0x06))
                    {
                        If ((SFID == 0x21))
                        {
                            Local1 = GKEY (Local0)
                        }
                        ElseIf ((SFID == 0x22))
                        {
                            Local1 = WKEY (Local0)
                        }
                        ElseIf ((SFID == 0x23))
                        {
                            Local1 = GLCF (Local0)
                        }
                        ElseIf ((SFID == 0x24))
                        {
                            Local1 = WLCF (Local0)
                        }
                    }

                    WRP2 [One] = Local1
                    Release (MUTW)
                    Return (WRP2) /* \_SB_.WMI1.WMAA.WRP2 */
                }

                If ((Arg1 != One))
                {
                    Release (MUTW)
                    Return (Zero)
                }

                Name (WMRP, Package (0x02)
                {
                    Buffer (0x04){}, 
                    Buffer (0x0100){}
                })
                Local1 = DerefOf (WMRP [One])
                CreateByteField (Local1, Zero, STAT)
                STAT = 0xEE
                Switch (MFID)
                {
                    Case (One)
                    {
                        Switch (SFID)
                        {
                            Case (One)
                            {
                                Local1 = GVER (Local0)
                            }

                        }
                    }
                    Case (0x02)
                    {
                        Switch (SFID)
                        {
                            Case (One)
                            {
                                Local1 = GTSI (Local0)
                            }
                            Case (0x02)
                            {
                                Local1 = GTMP (Local0)
                            }
                            Case (0x03)
                            {
                                Local1 = STMT (Local0)
                            }
                            Case (0x04)
                            {
                                Local1 = GPSI (Local0)
                            }
                            Case (0x05)
                            {
                                Local1 = GPCI (Local0)
                            }
                            Case (0x06)
                            {
                                Local1 = GLIV (Local0)
                            }
                            Case (0x08)
                            {
                                Local1 = GFNS (Local0)
                            }
                            Case (0x09)
                            {
                                Local1 = GCVA (Local0)
                            }
                            Case (0x0B)
                            {
                                Local1 = STMP (Local0)
                            }
                            Case (0x0C)
                            {
                                Local1 = GBAI (Local0)
                            }
                            Case (0x0D)
                            {
                                Local1 = GCII (Local0)
                            }
                            Case (0x0E)
                            {
                                Local1 = GADI (Local0)
                            }
                            Case (0x0F)
                            {
                                Local1 = GTPS (Local0)
                            }
                            Case (0x10)
                            {
                                Local1 = STPS (Local0)
                            }
                            Case (0x11)
                            {
                                Local1 = GRCS (Local0)
                            }
                            Case (0x12)
                            {
                                Local1 = GEAG (Local0)
                            }
                            Case (0x13)
                            {
                                Local1 = GESL (Local0)
                            }
                            Case (0x14)
                            {
                                Local1 = GTSS (Local0)
                            }
                            Case (0x15)
                            {
                                Local1 = STSS (Local0)
                            }
                            Case (0x16)
                            {
                                Local1 = GPOB (Local0)
                            }

                        }
                    }
                    Case (0x03)
                    {
                        Switch (SFID)
                        {
                            Case (0x0B)
                            {
                                Local1 = GPPT (Local0)
                            }
                            Case (0x0C)
                            {
                                Local1 = GCPL (Local0)
                            }
                            Case (0x0D)
                            {
                                Local1 = SPLV (Local0)
                            }
                            Case (0x0E)
                            {
                                Local1 = GODP (Local0)
                            }
                            Case (0x0F)
                            {
                                Local1 = SODP (Local0)
                            }
                            Case (0x10)
                            {
                                Local1 = SBTT (Local0)
                            }
                            Case (0x11)
                            {
                                Local1 = GBTT (Local0)
                            }
                            Case (0x12)
                            {
                                Local1 = SBAD (Local0)
                            }
                            Case (0x13)
                            {
                                Local1 = GBAD (Local0)
                            }
                            Case (0x14)
                            {
                                Local1 = GAIT (Local0)
                            }
                            Case (0x15)
                            {
                                Local1 = SBCM (Local0)
                            }
                            Case (0x16)
                            {
                                Local1 = GBCM (Local0)
                            }

                        }
                    }
                    Case (0x04)
                    {
                        Switch (SFID)
                        {
                            Case (0x06)
                            {
                                Local1 = GFRS (Local0)
                            }
                            Case (0x07)
                            {
                                Local1 = SFRS (Local0)
                            }
                            Case (0x0B)
                            {
                                Local1 = SMLS (Local0)
                            }
                            Case (0x0C)
                            {
                                Local1 = GFNM (Local0)
                            }
                            Case (0x0D)
                            {
                                Local1 = SFNM (Local0)
                            }
                            Case (0x0E)
                            {
                                Local1 = GTUB (Local0)
                            }
                            Case (0x0F)
                            {
                                Local1 = STUB (Local0)
                            }
                            Case (0x12)
                            {
                                Local1 = GPFM (Local0)
                            }
                            Case (0x13)
                            {
                                Local1 = SPFM (Local0)
                            }
                            Case (0x14)
                            {
                                Local1 = SFNS (Local0)
                            }
                            Case (0x16)
                            {
                                Local1 = GVNT (Local0)
                            }
                            Case (0x17)
                            {
                                Local1 = GCFD (Local0)
                            }

                        }
                    }
                    Case (0x05)
                    {
                        Switch (SFID)
                        {
                            Case (One)
                            {
                                Local1 = GSTP (Local0)
                            }
                            Case (0x02)
                            {
                                Local1 = SSTP (Local0)
                            }

                        }
                    }
                    Case (0x06)
                    {
                        Switch (SFID)
                        {
                            Case (One)
                            {
                                Local1 = SLGO (Local0)
                            }
                            Case (0x02)
                            {
                                Local1 = GLGO (Local0)
                            }
                            Case (0x03)
                            {
                                Local1 = SLOG (Local0)
                            }
                            Case (0x04)
                            {
                                Local1 = GLOG (Local0)
                            }
                            Case (0x05)
                            {
                                Local1 = SLED (Local0)
                            }
                            Case (0x06)
                            {
                                Local1 = GLED (Local0)
                            }
                            Case (0x07)
                            {
                                Local1 = GNTB (Local0)
                            }
                            Case (0x08)
                            {
                                Local1 = SNTB (Local0)
                            }
                            Case (0x09)
                            {
                                Local1 = SSWL (Local0)
                            }
                            Case (0x0A)
                            {
                                Local1 = GSWL (Local0)
                            }
                            Case (0x0B)
                            {
                                Local1 = SECL (Local0)
                            }
                            Case (0x0C)
                            {
                                Local1 = GECL (Local0)
                            }
                            Case (0x0D)
                            {
                                Local1 = SPDV (Local0)
                            }
                            Case (0x0E)
                            {
                                Local1 = GPDV (Local0)
                            }
                            Case (0x0F)
                            {
                                Local1 = SOSF (Local0)
                            }
                            Case (0x10)
                            {
                                Local1 = GOSF (Local0)
                            }
                            Case (0x11)
                            {
                                Local1 = SKBT (Local0)
                            }
                            Case (0x12)
                            {
                                Local1 = GKBT (Local0)
                            }
                            Case (0x13)
                            {
                                Local1 = GKBM (Local0)
                            }
                            Case (0x14)
                            {
                                Local1 = SKBM (Local0)
                            }
                            Case (0x15)
                            {
                                Local1 = SKBL (Local0)
                            }
                            Case (0x16)
                            {
                                Local1 = GECV (Local0)
                            }
                            Case (0x17)
                            {
                                Local1 = SECV (Local0)
                            }
                            Case (0x18)
                            {
                                Local1 = SDBV (Local0)
                            }
                            Case (0x19)
                            {
                                Local1 = SAKB (Local0)
                            }
                            Case (0x1A)
                            {
                                Local1 = GBAF (Local0)
                            }
                            Case (0x1B)
                            {
                                Local1 = GEPH (Local0)
                            }
                            Case (0x1C)
                            {
                                Local1 = GBTM (Local0)
                            }
                            Case (0x1D)
                            {
                                Local1 = SPLO (Local0)
                            }
                            Case (0x1E)
                            {
                                Local1 = GPLO (Local0)
                            }
                            Case (0x1F)
                            {
                                Local1 = GFCC (Local0)
                            }
                            Case (0x20)
                            {
                                Local1 = MGMT (Local0)
                            }
                            Case (0x25)
                            {
                                Local1 = SAOP (Local0)
                            }
                            Case (0x26)
                            {
                                Local1 = GAOP (Local0)
                            }
                            Case (0x27)
                            {
                                Local1 = SWAT (Local0)
                            }
                            Case (0x28)
                            {
                                Local1 = GWAT (Local0)
                            }
                            Case (0x29)
                            {
                                Local1 = HPDG (Local0)
                            }
                            Case (0x2A)
                            {
                                Local1 = GTDG (Local0)
                            }
                            Case (0x2B)
                            {
                                Local1 = GDPM (Local0)
                            }
                            Case (0x2C)
                            {
                                Local1 = GGSM (Local0)
                            }
                            Case (0x31)
                            {
                                Local1 = GDDS (Local0)
                            }
                            Case (0x32)
                            {
                                Local1 = SDDS (Local0)
                            }
                            Case (0x33)
                            {
                                Local1 = SCTS (Local0)
                            }
                            Case (0x34)
                            {
                                Local1 = GCTS (Local0)
                            }
                            Case (0x35)
                            {
                                Local1 = DTGT (Local0)
                            }
                            Case (0x36)
                            {
                                Local1 = GOLR (Local0)
                            }
                            Case (0x37)
                            {
                                Local1 = GCS (Local0)
                            }
                            Case (0x38)
                            {
                                Local1 = AVMF (Local0)
                            }
                            Case (0x39)
                            {
                                Local1 = RSBT (Local0)
                            }
                            Case (0x3A)
                            {
                                Local1 = SDPM (Local0)
                            }
                            Case (0x3B)
                            {
                                Local1 = GHMD (Local0)
                            }
                            Case (0x3C)
                            {
                                Local1 = GDJC (Local0)
                            }
                            Case (0x3D)
                            {
                                Local1 = GDBV (Local0)
                            }
                            Case (0x3E)
                            {
                                Local1 = GHCS (Local0)
                            }
                            Case (0x3F)
                            {
                                Local1 = GILC (Local0)
                            }
                            Case (0x30)
                            {
                                Local1 = GDXD (Local0)
                            }
                            Case (0x2D)
                            {
                                Local1 = SOAR (Local0)
                            }
                            Case (0x2E)
                            {
                                Local1 = GOAR (Local0)
                            }
                            Case (0x2F)
                            {
                                Local1 = GVCG (Local0)
                            }
                            Case (0x40)
                            {
                                Local1 = SFIF (Local0)
                            }
                            Case (0x41)
                            {
                                Local1 = GMIR (Local0)
                            }
                            Case (0x42)
                            {
                                Local1 = SSLR (Local0)
                            }

                        }
                    }
                    Case (0x07)
                    {
                        Switch (SFID)
                        {
                            Case (One)
                            {
                                Local1 = SDNF (Local0)
                            }
                            Case (0x02)
                            {
                                Local1 = GDNF (Local0)
                            }
                            Case (0x05)
                            {
                                Local1 = ISIA (Local0)
                            }
                            Case (0x08)
                            {
                                Local1 = IFCI (Local0)
                            }
                            Case (0x09)
                            {
                                Local1 = IBTI (Local0)
                            }
                            Case (0x0A)
                            {
                                Local1 = GTCC (Local0)
                            }
                            Case (0x0B)
                            {
                                Local1 = GFCI (Local0)
                            }
                            Case (0x0C)
                            {
                                Local1 = SCFM (Local0)
                            }
                            Case (0x0D)
                            {
                                Local1 = SPPM (Local0)
                            }
                            Case (0x0E)
                            {
                                Local1 = SPPF (Local0)
                            }
                            Case (0x0F)
                            {
                                Local1 = SVRF (Local0)
                            }
                            Case (0x10)
                            {
                                Local1 = GVRF (Local0)
                            }

                        }
                    }

                }

                WMRP [One] = Local1
                Release (MUTW)
                Return (WMRP) /* \_SB_.WMI1.WMAA.WMRP */
            }

            Method (_WED, 1, NotSerialized)  // _Wxx: Wake Event, xx=0x00-0xFF
            {
                Return (WMEN) /* \_SB_.WMI1.WMEN */
            }
        }
    }
}

