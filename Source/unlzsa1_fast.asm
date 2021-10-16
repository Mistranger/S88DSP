;
;  Speed-optimized LZSA1 decompressor by spke & uniabis (113 bytes)
;
;  ver.00 by spke for LZSA 0.5.4 (03-24/04/2019, 134 bytes);
;  ver.01 by spke for LZSA 0.5.6 (25/04/2019, 110(-24) bytes, +0.2% speed);
;  ver.02 by spke for LZSA 1.0.5 (24/07/2019, added support for backward decompression);
;  ver.03 by uniabis (30/07/2019, 109(-1) bytes, +3.5% speed);
;  ver.04 by spke (31/07/2019, small re-organization of macros);
;  ver.05 by uniabis (22/08/2019, 107(-2) bytes, same speed);
;  ver.06 by spke for LZSA 1.0.7 (27/08/2019, 111(+4) bytes, +2.1% speed);
;  ver.07 by spke for LZSA 1.1.0 (25/09/2019, added full revision history);
;  ver.08 by spke for LZSA 1.1.2 (22/10/2019, re-organized macros and added an option for unrolled copying of long matches);
;  ver.09 by spke for LZSA 1.2.1 (02/01/2020, 109(-2) bytes, same speed);
;  ver.10 by spke (07/04/2021, 113(+4) bytes, +5% speed)
;
;  The data must be compressed using the command line compressor by Emmanuel Marty
;  The compression is done as follows:
;
;  lzsa.exe -f1 -r <sourcefile> <outfile>
;
;  where option -r asks for the generation of raw (frame-less) data.
;
;  The decompression is done in the standard way:
;
;  ld hl,FirstByteOfCompressedData
;  ld de,FirstByteOfMemoryForDecompressedData
;  call DecompressLZSA1
;
;  Backward compression is also supported; you can compress files backward using:
;
;  lzsa.exe -f1 -r -b <sourcefile> <outfile>
;
;  and decompress the resulting files using:
;
;  ld hl,LastByteOfCompressedData
;  ld de,LastByteOfMemoryForDecompressedData
;  call DecompressLZSA1
;
;  (do not forget to uncomment the BACKWARD_DECOMPRESS option in the decompressor).
;
;  Of course, LZSA compression algorithms are (c) 2019 Emmanuel Marty,
;  see https://github.com/emmanuel-marty/lzsa for more information
;
;  Drop me an email if you have any comments/ideas/suggestions: zxintrospec@gmail.com
;
;  This software is provided 'as-is', without any express or implied
;  warranty.  In no event will the authors be held liable for any damages
;  arising from the use of this software.
;
;  Permission is granted to anyone to use this software for any purpose,
;  including commercial applications, and to alter it and redistribute it
;  freely, subject to the following restrictions:
;
;  1. The origin of this software must not be misrepresented; you must not
;     claim that you wrote the original software. If you use this software
;     in a product, an acknowledgment in the product documentation would be
;     appreciated but is not required.
;  2. Altered source versions must be plainly marked as such, and must not be
;     misrepresented as being the original software.
;  3. This notice may not be removed or altered from any source distribution.
    Relaxed        on   
    
    SECTION Lzsa1Unpack
UNROLL_LONG_MATCHES equ 1                        ; uncomment for faster decompression of very compressible data (+51 byte)
;    DEFINE    BACKWARD_DECOMPRESS                        ; uncomment to decompress backward compressed data (-3% speed, +5 bytes)
    PUBLIC DecompressLZSA1
    IFNDEF    BACKWARD_DECOMPRESS

NEXT_HL:    MACRO 
        inc hl
        ENDM

ADD_OFFSET:    MACRO
        ; HL = DE+HL
        add hl,de
        ENDM

COPY1:        MACRO 
        ldi
        ENDM

COPYBC:        MACRO COPYBC
        ldir
        ENDM

    ELSE

NEXT_HL:    MACRO 
        dec hl
        ENDM

ADD_OFFSET:    MACRO 
        ; HL = DE-HL
        ld a,e 
        sub l 
        ld l,a
        ld a,d 
        sbc h 
        ld h,a                        ; 6*4 = 24t / 6 bytes
        ENDM

COPY1:        MACRO 
        ldd
        ENDM

COPYBC:        MACRO 
        lddr
        ENDM

    ENDIF

DecompressLZSA1:
        ld b,0 
        jr ReadToken

    IFNDEF    UNROLL_LONG_MATCHES

CopyMatch2:    ld c,a
.UseC        ex (sp),hl 
        jr CopyMatch.UseC

    ENDIF

NoLiterals:    xor (hl) 
        NEXT_HL 
        jp m,LongOffset

ShortOffset:    push hl
        ld l,(hl) 
        ld h,0xFF

         ; short matches have length 0+3..14+3
        add a,3
        cp 15+3 
        jr nc,LongerMatch

        ; placed here this saves a JP per iteration
CopyMatch:    ld c,a                                ; BC = len, DE = dest, HL = offset, SP -> [src]
.UseC        ADD_OFFSET                            ; BC = len, DE = dest, HL = dest-offset, SP->[src]
        COPY1 
        COPY1 
        COPYBC                        ; BC = 0, DE = dest
.popSrc        pop hl 
        NEXT_HL                        ; HL = src
    
ReadToken:    ; first a byte token "O|LLL|MMMM" is read from the stream,
        ; where LLL is the number of literals and MMMM is
        ; a length of the match that follows after the literals
        ld a,(hl) 
        and a,0x70 
        jr z,NoLiterals

        cp 0x70 
        jr z,MoreLiterals                    ; LLL=7 means 7+ literals...
        rrca 
        rrca 
        rrca 
        rrca 
        ld c,a                ; LLL<7 means 0..6 literals...

        ld a,(hl) 
        NEXT_HL
        COPYBC

        ; the top bit of token is set if the offset contains two bytes
        and 0x8F 
        jp p,ShortOffset

LongOffset:    ; read second byte of the offset
        ld c,(hl) 
        NEXT_HL 
        push hl 
        ld h,(hl) 
        ld l,c
        add a,-125
        cp 15+3 
        jp c,CopyMatch

    IFNDEF    UNROLL_LONG_MATCHES

        ; MMMM=15 indicates a multi-byte number of literals
LongerMatch:    ex (sp),hl 
        NEXT_HL 
        add a,(hl) 
        jr nc,CopyMatch2

        ; the codes are designed to overflow;
        ; the overflow value 1 means read 1 extra byte
        ; and overflow value 0 means read 2 extra bytes
.code1        ld b,a 
        NEXT_HL 
        ld c,(hl) 
        jr nz,CopyMatch2.UseC
.code0        NEXT_HL 
        ld b,(hl)

        ; the two-byte match length equal to zero
        ; designates the end-of-data marker
        ld a,b 
        or c 
        jr nz,CopyMatch2.UseC
        pop bc 
        ret

    ELSE

        ; MMMM=15 indicates a multi-byte number of literals
LongerMatch:    ex (sp),hl 
        NEXT_HL 
        add a,(hl) 
        jr c,VeryLongMatch

        ld c,a
.UseC        ex (sp),hl
        ADD_OFFSET
        COPY1 
        COPY1

        ; this is an unrolled equivalent of LDIR
        xor a 
        sub c
        and 16-1 
        add a,a
        ld (.jrOffset),a 
        jr nz,$+2
.jrOffset    EQU $-1
.fastLDIR    rept     16
        COPY1
        endm
        jp pe,.fastLDIR
        jr CopyMatch.popSrc

VeryLongMatch:    ; the codes are designed to overflow;
        ; the overflow value 1 means read 1 extra byte
        ; and overflow value 0 means read 2 extra bytes
.code1        ld b,a 
        NEXT_HL 
        ld c,(hl) 
        jr nz,LongerMatch.UseC
.code0        NEXT_HL 
        ld b,(hl)

        ; the two-byte match length equal to zero
        ; designates the end-of-data marker
        ld a,b 
        or c 
        jr nz,LongerMatch.UseC
        pop bc 
        ret

    ENDIF

MoreLiterals:    ; there are three possible situations here
        xor (hl) 
        NEXT_HL 
        EX AF,AF'
        ld a,7 
        add a,(hl) 
        jr c,ManyLiterals

CopyLiterals:    ld c,a
.UseC        NEXT_HL 
        COPYBC

        EX AF,AF'
        jp p,ShortOffset 
        jr LongOffset

ManyLiterals:
.code1        ld b,a 
        NEXT_HL 
        ld c,(hl) 
        jr nz,CopyLiterals.UseC
.code0        NEXT_HL 
        ld b,(hl) 
        jr CopyLiterals.UseC

    ENDSECTION