;
; KZ80_1MSRAM/IOB用モジュール
;    シリアル　SIO
;--------------------------------------------------------

SIOA_D		EQU	00h
SIOA_C		EQU	02h
SIOB_D		EQU	01h
SIOB_C		EQU	03h
;
BUFSIZ	EQU	3FH
BUFFUL	EQU	30H
BUFEMP	EQU	5
;
RTSHIG	EQU	0E8H
RTSLOW	EQU	0EAH

;------------------------------------------------------------------------------
; SIO割り込みルーチン
;------------------------------------------------------------------------------
SERINT: 
	PUSH	AF
	PUSH	HL
	SUB	A
	OUT (SIOA_C),A
	IN	A,(SIOA_C)
	AND	00000001B
	JP	Z,RTS0
	IN	A,(SIOA_D)
	PUSH	AF
	LD	A,(SERCNT)
	CP	BUFSIZ
	JP	NZ,NOTFUL
	POP	AF
	JP	RTS0
NOTFUL:	LD	HL,(SERINP)
	INC	HL
	LD	A,L
	CP	SERINP & 0FFH
	JP	NZ,NOTWRP
	LD	HL,SERBUF
NOTWRP:	LD	(SERINP),HL
	POP	AF
	LD	(HL),A
	LD	A,(SERCNT)
	INC	A
	LD	(SERCNT),A
	CP	BUFFUL
	JP	C,RTS0
	LD   A,5
	OUT  (SIOA_C),A
	LD	A,RTSHIG
	OUT	(SIOA_C),A
RTS0:	POP	HL
	POP	AF
	EI
	RETI

;------------------------------------------------------------------------------
; 1文字入力(バッファから)
;------------------------------------------------------------------------------
CIN:
	LD	A,(SERCNT)
	CP	00H
	JP	Z,CIN
	PUSH	HL
	LD	HL,(SERRDP)
	INC	HL
	LD	A,L
	CP	SERINP & 0FFH
	JP	NZ,NRWRAP
	LD	HL,SERBUF
NRWRAP:	DI
	LD	(SERRDP),HL
	LD	A,(SERCNT)
	DEC	A
	LD	(SERCNT),A
	CP	BUFEMP
	JP	NC,RTS1
	LD   A,5
	OUT  (SIOA_C),A
	LD	A,RTSLOW
	OUT	(SIOA_C),A
RTS1:	LD	A,(HL)
	EI
	POP	HL
	RET	

;------------------------------------------------------------------------------
; 1文字出力
;------------------------------------------------------------------------------
COUT:		PUSH	AF
COUT1:
	SUB	A
	OUT 	(SIOA_C),A
	IN	A,(SIOA_C)
	AND	04H     
	JP	Z,COUT1
	POP	AF
	OUT	(SIOA_D),A
	RET

;------------------------------------------------------------------------------
; 入力バッファチェック
;------------------------------------------------------------------------------
CKINCHAR	LD	A,(SERCNT)
	CP	00H
	RET

;------------------------------------------------------------------------------
; 初期化
;------------------------------------------------------------------------------
INIT:		
    LD  SP,STACK
	LD	HL,SERBUF
	LD	(SERINP),HL
	LD	(SERRDP),HL
	XOR	A
	LD	(SERCNT),A
;
	LD	A,00h
	LD	I,A
	IM	2

;
	LD B,SIOA_INIT_CNT
	LD HL,SIOA_INIT
	LD C,SIOA_C
	OTIR
;
	LD B,SIOB_INIT_CNT
	LD HL,SIOB_INIT
	LD C,SIOB_C
	OTIR
	EI
;
    JP MAIN
;
SIOA_INIT	DB 00h,18h,04h,44h,01h,18h,03h,0c1h,05h,RTSLOW
SIOA_INIT_CNT EQU $-SIOA_INIT
;
SIOB_INIT	DB 02h,60h
SIOB_INIT_CNT EQU $-SIOB_INIT
;
; KZ80-1MSRAM用 RAM 4000h〜
;
    ORG 4000h
;
SERBUF	DS	BUFSIZ
SERINP	DS	2
SERRDP	DS	2
SERCNT	DS	1
;
DEVICE_RAM_END EQU $
