;
; KZ80_IOBv2用 モジュール
;    割り込み  8259
;    タイマー  8254
;    シリアル　8251x1
;    パラレル  8255x1
;--------------------------------------------------------
; 以下のルーチンはSBC8080データパックのASMソースを参考にさせていただきました。
;  SERINT 	8251シリアル割り込みルーチン
;  CIN		シリアル1文字入力ルーチン
;  COUT		シリアル1文字出力ルーチン
;  CKINCHAR	シリアルバッファチェックルーチン

UARTRD	EQU	00H
UARTRC	EQU	01H
;
PICRC	EQU	10h
PICRD	EQU	11h
;
PIT_C0	EQU 18h
PIT_C1	EQU 19h
PIT_C2	EQU 1Ah
PIT_CWR	EQU 1Bh
;
PIT_TIMER_INIT EQU 30000
;
;
BUFSIZ	EQU	3FH
BUFFUL	EQU	30H
BUFEMP	EQU	5
;
RTSHIG	EQU	00010111B
RTSLOW	EQU	00110111B

;------------------------------------------------------------------------------
; 8251割り込みルーチン
;------------------------------------------------------------------------------
SERINT:	PUSH	AF
	PUSH	HL
	IN	A,(UARTRC)
	AND	00000010B
	JP	Z,RTS0
	IN	A,(UARTRD)
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
	LD	A,RTSHIG
	OUT	(UARTRC),A
RTS0:
	LD A,00100000b
	OUT (PICRC),A	
	POP	HL
	POP	AF

	EI
	RET

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
	LD	A,RTSLOW
	OUT	(UARTRC),A
RTS1:	LD	A,(HL)
	EI
	POP	HL
	RET	

;------------------------------------------------------------------------------
; 1文字出力
;------------------------------------------------------------------------------
COUT:		PUSH	AF
COUT1:	IN	A,(UARTRC)
	AND	01H     
	JP	Z,COUT1
	POP	AF
	OUT	(UARTRD),A
	RET

;------------------------------------------------------------------------------
; 入力バッファチェック
;------------------------------------------------------------------------------
CKINCHAR	LD	A,(SERCNT)
	CP	00H
	RET

;------------------------------------------------------------------------------
; PIT 8254 割り込み処理
;------------------------------------------------------------------------------
; PIT1
INT_VECTOR4_RTN:
	PUSH AF
	PUSH HL
	CALL PIT_C1_INIT
	JR PIT_INT_EXIT
; PIT0
INT_VECTOR5_RTN:
	PUSH AF
	PUSH HL
	CALL PIT_C0_INIT
;
PIT_INT_EXIT:
	LD A,00100000b
	OUT (PICRC),A
	POP HL
	POP AF
	EI
	RET
;------------------------------------------------------------------------------
; PIT 8254 初期化
;------------------------------------------------------------------------------
PIT_INIT:
; COUNTER INIT 
	CALL PIT_C0_INIT
	CALL PIT_C1_INIT
	RET
;
; PIT TIMER SET
;
PIT_C0_INIT:
	LD HL,(TIMER_COUNT)
	LD A,00110000b
	OUT (PIT_CWR),A
	LD A,H
	OUT (PIT_C0),A
	LD A,L
	OUT (PIT_C0),A
	RET
;
PIT_C1_INIT:
	LD HL,(TIMER_COUNT)
	LD A,01110000b
	OUT (PIT_CWR),A
	LD A,H
	OUT (PIT_C1),A
	LD A,L
	OUT (PIT_C1),A
	RET

;------------------------------------------------------------------------------
; 初期化
;------------------------------------------------------------------------------
INIT:		
    LD  SP,STACK
; Intrrupt VECTOR SET
	LD HL,HOOKAREA
	LD DE,RST00HOOK
	LD BC,32
	LDIR
;
	LD	HL,SERBUF
	LD	(SERINP),HL
	LD	(SERRDP),HL
	XOR	A
	LD	(SERCNT),A
	OUT	(UARTRC),A
	OUT	(UARTRC),A
	OUT	(UARTRC),A
	LD	A,01000000B
	OUT	(UARTRC),A
	LD	A,01001110B
	OUT	(UARTRC),A
	LD	A,RTSLOW
	OUT	(UARTRC),A
;
; 8259 INIT
	LD A,00010010b
	OUT (PICRC),A
	XOR A
	OUT (PICRD),A
; 
; 8254 INIT
	LD HL,PIT_TIMER_INIT
	LD (TIMER_COUNT),HL
	CALL PIT_INIT
;
	EI
;
    JP MAIN
;
;------------------------------------------------------------------------------
HOOKAREA: 
; RST00
	DB 0C3h
	DW INIT
	DB 00H
; RST08
	DB 0C3h
	DW COUT
	DB 00H
; RST10
	DB 0C3h
	DW CIN
	DB 00H
; RST18
	DB 0C3h
	DW CKINCHAR
	DB 00H
; RST20
	DB 0C3h
	DW INT_VECTOR4_RTN
	DB 00H
; RST28
	DB 0C3h
	DW INT_VECTOR5_RTN
	DB 00H
; RST30
	DB 0C3h
	DW 0000h
	DB 00H
; RST38
	DB 0C3h
	DW SERINT
	DB 00H
;
DEVICE_END EQU $
;
; KZ80-1MSRAM用 RAM 4000h〜
;
    ORG 4000h
;

;
RST00HOOK DS 4
RST08HOOK DS 4
RST10HOOK DS 4
RST18HOOK DS 4
RST20HOOK DS 4
RST28HOOK DS 4
RST30HOOK DS 4
RST38HOOK DS 4
;
TIMER_COUNT DS 2
;
SERBUF	DS	BUFSIZ
SERINP	DS	2
SERRDP	DS	2
SERCNT	DS	1
;
DEVICE_RAM_END EQU $

