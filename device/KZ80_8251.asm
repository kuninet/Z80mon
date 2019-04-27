;
; KZ80_1MSRAM/IOB用モジュール
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
RTS0:	POP	HL
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
; 初期化
;------------------------------------------------------------------------------
INIT:		
    LD  SP,STACK
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
	EI
;
    JP MAIN
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
