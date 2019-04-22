;-----------------------------------------------------------------------
; Z80 Monitor KUNI-NET
;-----------------------------------------------------------------------
; 以下のルーチンはSBC8080データパックのASMソースを参考にさせていただきました。
;  SERINT 	8251シリアル割り込みルーチン
;  CIN		シリアル1文字入力ルーチン
;  COUT		シリアル1文字出力ルーチン
;  CKINCHAR	シリアルバッファチェックルーチン

CR		EQU	0DH
LF		EQU	0AH
ESC		EQU	1BH
CTRLC	EQU	03H
CLS		EQU	0CH
SPC		EQU	20h
NULL	EQU 00h
BEEP	EQU 07h
BS		EQU 08h
TAB		EQU 09h
DEL		EQU 7Fh
;
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
; RAM バッファ & STACK
;------------------------------------------------------------------------------
		ORG	4000h
;
SERBUF	DS	BUFSIZ
SERINP	DS	2
SERRDP	DS	2
SERCNT	DS	1
BASFLG	DS	1
;
INBUF   DS  20
INMAX   EQU  $-INBUF
INEND   DS  1
;
ARGC	DS	1
ARGV_1	DS	2
ARGV_2	DS	2
ARGV_3	DS	2
ARG_MAX	EQU ($-ARGV_1)/2
ARG_AREA_LEN EQU $-ARGC
;
    	DS	32
STACK   	EQU    $



		ORG	0000h
;------------------------------------------------------------------------------
; RST00 リセット
;------------------------------------------------------------------------------
RST00		DI		
		JP	INIT	

;------------------------------------------------------------------------------
; RST08 1文字送信
;------------------------------------------------------------------------------
	ORG	0008H
RST08		JP	COUT

;------------------------------------------------------------------------------
; RST10 1文字受信
;------------------------------------------------------------------------------
	ORG	0010H
RST10		JP	CIN

;------------------------------------------------------------------------------
; RST18 入力バッファチェック
;------------------------------------------------------------------------------
	ORG	0018H
RST18		JP	CKINCHAR

;------------------------------------------------------------------------------
; RST38 8251A割り込みルーチン
;------------------------------------------------------------------------------
	ORG	0038H
RST38:	JP	SERINT 

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

;==============================================================================
;------------------------------------------------------------------------------
; 1文字入力 英字大文字対応
;------------------------------------------------------------------------------
GETC:
    RST 10h
    CP 'a'
    RET M
    CP 'z'+1
    RET P
    SUB A,20H
    RET

;------------------------------------------------------------------------------
; 文字列入力 エコーバックつき
;------------------------------------------------------------------------------
STRIN:
; INBUF クリア
    LD A,00H
    LD (INBUF),A
    LD HL,INBUF
    LD DE,INBUF+1
    LD BC,INMAX
    LDIR
;
    LD HL,INBUF
;
_STRIN_LOOP:
    CALL GETC
    CP 0Dh
    JR Z,_STRIN_END
    CP BS
    JR Z,_BS_RTN
	CP DEL
    JR Z,_BS_RTN
	CP ESC
	JR Z,_ESC_RTN
;
; バッファENDにきた?
	LD B,A
	LD DE,INEND
	LD A,D
	CP H
	JR NZ,_CHAR_SET
	LD A,E
	CP L
	JR Z,_WARN_BEEP
	LD A,B
_CHAR_SET:
    LD (HL),A
    INC HL
    call CPRINT
    JR _STRIN_LOOP
;
_WARN_BEEP:
	LD A,BEEP
	RST 08h
    JR _STRIN_LOOP
;
_ESC_RTN:
	CCF
	RET
;
_BS_RTN:
	LD DE,INBUF
	LD A,D
	CP H
	JR NZ,_BS_RTN2
	LD A,E
	CP L
	JR Z,_WARN_BEEP
;
_BS_RTN2:
    PUSH HL
    LD HL,BSTXT
    CALL STRPR
    POP HL
    DEC HL
    LD (HL),00h
    JR _STRIN_LOOP
;
_STRIN_END:
    CALL CRLF_PRINT
    RET

;------------------------------------------------------------------------------
; 文字列出力
;------------------------------------------------------------------------------
STRPR:
    LD A,(HL)
    OR A
    RET Z
    CALL CPRINT
    INC HL
    JR STRPR

;------------------------------------------------------------------------------
; 文字出力 (CRLF対応)
; IN: A - キャラクタ
; RET: なし
;------------------------------------------------------------------------------
CPRINT:
    CP 0Dh
    JR Z,CRLF_PRINT
    RST 08h
    RET

;------------------------------------------------------------------------------
; CRLF出力 (CRLF対応)
;------------------------------------------------------------------------------
CRLF_PRINT:
    LD A,0DH
    RST 08H
    LD A,0AH
    RST 08h
    RET

;------------------------------------------------------------------------------
; ブランク出力 
;------------------------------------------------------------------------------
SPC_PRINT:
    LD A,SPC
    RST 08H
    RET

;------------------------------------------------------------------------------
; Hex2桁出力
;------------------------------------------------------------------------------
HEX2OUT:
	PUSH BC
	LD B,A
	SRL A
	SRL A
	SRL A
	SRL A
	CALL _HEX_CNV_PR
	LD A,B
	AND 0Fh
	CALL _HEX_CNV_PR
	POP BC
	RET
;
_HEX_CNV_PR:	
	ADD A,90h
	DAA
	ADC	A,40h
	DAA
	RST 08h
	RET


;==============================================================================
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
;--------------------------------------------------------------------------------
; メイン
;--------------------------------------------------------------------------------
MAIN:
    LD HL,OPENMSG
    CALL STRPR
_MAIN_LOOP:
	LD HL,_MAIN_LOOP
	PUSH HL
;
    LD A,'>'
    RST 08h
    LD IX,CMD_TBL
	CALL GETC
    RST 08H
;
_CMD_LOOP:
	PUSH AF
    LD A,(IX+0)
	OR A
	JR Z,_ERROR_EXIT
	LD B,A
	POP AF
    CP B
	JR NZ,_NEXT_CMD
    LD L,(IX+1)
	LD H,(IX+2)
	JP (HL)
;
_NEXT_CMD:
	INC IX
	INC IX
	INC IX
	JR _CMD_LOOP
;;
_ERROR_EXIT
	CALL CRLF_PRINT
	LD HL,HATENA_MSG
	CALL STRPR
	CALL CRLF_PRINT
	RET

;================================================================================
; ヘルプ出力
;================================================================================
HELP_OUT:
    LD HL,HELP_MSG
	JR _PRINT_END
;
;================================================================================
; バージョン出力
;================================================================================
VERSION_OUT:
    LD HL,VERMSG
	JR _PRINT_END
;
;--------------------------------------------------------------------------------
; メッセージ出力してメインへリターン
;--------------------------------------------------------------------------------
_PRINT_END:
	CALL CRLF_PRINT
    CALL STRPR
	CALL CRLF_PRINT
    RET

;--------------------------------------------------------------------------------
; HEX4桁出力
;--------------------------------------------------------------------------------
HEX4OUT:
	PUSH AF
	LD A,H
	CALL HEX2OUT
	LD A,L
	CALL HEX2OUT
	POP AF
	RET

;--------------------------------------------------------------------------------
; 入力行パース
;--------------------------------------------------------------------------------
PARSER:
; 編集エリア初期化
	LD HL,ARGC
	LD A,0
	LD (HL),A
	LD DE,ARGC+1
	LD BC,ARG_AREA_LEN-1
	LDIR
; 入力パラメーター パース開始
	LD C,A
	LD HL,INBUF-1
	LD IX,ARGV_1
;
_PARSE_LOOP:
	INC HL
	LD A,(HL)
	CP NULL
	RET Z
	CP SPC
	JR Z,_PARSE_LOOP
    INC C
	LD A,C
	CP ARG_MAX+1
	JR NC,_PARSE_ERR
	LD (ARGC),A
	LD (IX+0),L
	LD (IX+1),H
	INC IX
	INC IX
_PARAM_LOOP:
	INC HL
	LD A,(HL)
	CP NULL
	RET Z
	CP SPC
	JR NZ,_PARAM_LOOP
	LD A,NULL
	LD (HL),A
	JR _PARSE_LOOP
;
_PARSE_ERR:
	CCF
	RET

;--------------------------------------------------------------------------------
; HEX 2桁キャラクタ → Aレジスタ
;--------------------------------------------------------------------------------
HEX2BIN:
	LD A,(HL)
	CALL _ATOBIN
	RET C
	SLA A
	SLA A
	SLA A
	SLA A
	LD B,A
	INC HL
	LD A,(HL)
	CALL _ATOBIN
	RET C
	ADD A,B
	RET
;
_ATOBIN:
	CP '0'
	RET C
	CP '9'+1
	JR C,_ATOBIN1
	CP 'A'
	RET C
	CP 'F'+1
	CCF
	RET C
	ADD A,09H
_ATOBIN1:
	AND 0Fh
	RET
;

;--------------------------------------------------------------------------------
; 4バイト16進数文字列→バイナリ(HL)へ
;--------------------------------------------------------------------------------
HEX4BIN:
	CALL HEX2BIN
	RET C
	LD D,A
	INC HL
	CALL HEX2BIN
	RET C
	LD E,A
	PUSH DE
	POP HL
	RET
;
;================================================================================
; メモリーダンプ
;================================================================================
MEM_DUMP:
    CALL SPC_PRINT
;
    CALL STRIN
	CALL PARSER
	JR C,_PARAM_ERR
; 入力パラメータ数チェック
	LD A,(ARGC)
	CP 2
	JR NZ,_PARAM_ERR
; 開始アドレス取得
	LD HL,(ARGV_1)
	CALL HEX4BIN
	JR C,_PARAM_ERR
	PUSH HL
	POP IX
; 終了アドレス取得
	LD HL,(ARGV_2)
	CALL HEX4BIN
	JR C,_PARAM_ERR
	PUSH HL
	POP DE
	PUSH IX
	POP HL
; ダンプ実施
_DUMP_LOOP:
	RST 18h
	JR Z,_DUMP_GO
	RST 10h
	CP ESC
	JR Z,_ABORT_DUMP
_DUMP_GO:
	PUSH HL
	CALL DUMP16
	POP HL
	CALL ASC16
	CALL CRLF_PRINT
; 終了判定
	LD A,D
	CP H
	RET M   ; メインループへ
	LD A,E
	CP L
	JP M,_DUMP_END_CHECK
	JR _DUMP_LOOP
;
_DUMP_END_CHECK:
	LD A,D
	CP H
	JR NZ,_DUMP_LOOP
	RET
;
_PARAM_ERR:
	LD HL,PARAM_ERRMSG
	JP _PRINT_END
;
_ABORT_DUMP:
	LD HL,ABORT_MSG
	JP _PRINT_END
;--------------------------------------------------------------------------------
; 16バイト分 ASCII出力
;--------------------------------------------------------------------------------
ASC16:
	CALL SPC_PRINT
	LD A,':'
	RST 08h
	CALL SPC_PRINT
	LD C,10h
;
_ASC16_LOOP:
	LD A,(HL)
	CP ' '
	JP M,_ASC16_DOT
	CP 7Fh
	JP M,_ASC16_PRINT
_ASC16_DOT:
	LD A,'.'
_ASC16_PRINT:
	RST 08h	
	INC HL
	DEC C
	RET Z
	JR _ASC16_LOOP

;--------------------------------------------------------------------------------
; アドレス部分出力
;--------------------------------------------------------------------------------
ADDR_OUT:
	CALL HEX4OUT
	CALL SPC_PRINT
	LD A,':'
	RST 08h
	CALL SPC_PRINT
	RET

;--------------------------------------------------------------------------------
; 16バイト分 HEXダンプ出力
;--------------------------------------------------------------------------------
DUMP16:
	CALL ADDR_OUT
	LD C,10h
_DUMP16_LOOP:
	CALL DUMP_AT
	CALL SPC_PRINT
	INC HL
	DEC C
	RET Z
	JR _DUMP16_LOOP

;--------------------------------------------------------------------------------
; 1バイト分 HEXダンプ出力
;--------------------------------------------------------------------------------
DUMP_AT:
	LD A,(HL)
	CALL HEX2OUT
	RET

;--------------------------------------------------------------------------------
; strlen
;--------------------------------------------------------------------------------
STR_LEN:
	LD C,0
_STR_LEN_LOOP:
	LD A,(HL)
	CP NULL
	JR Z,_STR_LEN_EXIT
	INC HL
	INC C
	JR _STR_LEN_LOOP
;
_STR_LEN_EXIT:
	LD A,C
	RET
;
;--------------------------------------------------------------------------------
; メモリー変更コマンド
;--------------------------------------------------------------------------------
MEM_CHANGE:
    CALL SPC_PRINT
;
    CALL STRIN
	CALL PARSER
;
; 入力パラメータ数チェック
	LD A,(ARGC)
	CP 1
	JR NZ,_PARAM_ERR
;
; 開始アドレス取得
	LD HL,(ARGV_1)
	CALL HEX4BIN
	JR C,_PARAM_ERR
	PUSH HL
	POP IX
;
	CALL CRLF_PRINT
_MEM_CHANGE_LOOP:
	PUSH IX
	POP HL
	CALL ADDR_OUT
	LD A,(IX+0)
	CALL HEX2OUT
	LD A,'-'
	CALL CPRINT
	PUSH IX
;
    CALL STRIN
	JP C,_MEM_CHANGE_EXIT
	CALL PARSER
; 入力パラメータ数/レングスチェック
	LD A,(ARGC)
	CP 0
	JR Z,_NEXT_ADDR
	CP 1
	JR NZ,_HATENA_OUT
	LD HL,(ARGV_1)
	CALL STR_LEN
	CP 2
	JR NZ,_HATENA_OUT
	LD HL,(ARGV_1)
	CALL HEX2BIN
	JR C,_HATENA_OUT
	POP IX
	LD (IX+0),A
	INC IX
	JR _MEM_CHANGE_LOOP
;
_NEXT_ADDR:
	POP IX
	INC IX
	JR _MEM_CHANGE_LOOP
;
_HATENA_OUT:
	LD HL,HATENA_MSG
	CALL STRPR
	POP IX
	JR _MEM_CHANGE_LOOP
;
_MEM_CHANGE_EXIT:
	CALL CRLF_PRINT
	RET ;ESCキーでメイン処理へ
;
;--------------------------------------------------------------------------------
; コマンドテーブル
;--------------------------------------------------------------------------------
CMD_TBL:
    DB 'H'
    DW HELP_OUT
    DB '?'
    DW HELP_OUT
    DB 'V'
    DW VERSION_OUT
    DB 'D'
    DW MEM_DUMP
    DB 'M'
    DW MEM_CHANGE
; TABLE END
    DB 00h
;
;--------------------------------------------------------------------------------
; メッセージなど
;--------------------------------------------------------------------------------
VERNAME EQU "KUNI-NET Z80 MONITOR v0.1"
VERMSG  DB VERNAME,CR,0
OPENMSG DB CR,CR,"** ",VERNAME," **",CR,0
BSTXT	DB BS,SPC,BS,0
HELP_MSG DB "- - - COMMAND HELP - - -",CR
         DB "M XXXX ",TAB,TAB,"MEMORY EDIT",CR
         DB "D XXXX XXXX ",TAB,"MEMORY DUMP",CR
         DB "H ",TAB,TAB,"HELP MESSGAE",CR
         DB "V ",TAB,TAB,"VERSION INFOMATION",CR,0
PARAM_ERRMSG DB BEEP,"** PARAMETER ERR",CR,0
ABORT_MSG DB BEEP,"** MEM DUMP ABORTED END",CR,0
HATENA_MSG DB CR,"?",CR,0
