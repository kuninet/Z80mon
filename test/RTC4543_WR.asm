;
; RTC4543SA WRITE Test
;
    org 5000h
;
; usage : >G 5000 yymmddWhhmmss (W:1 - Sun,2 - Mon...)
;

; 入力パラメーター
;   B   : パラメーター数
;   DE  : 入力パラメーターテーブルへのポインタ

NULL    EQU 00h
;
PPI_CTL EQU 0Bh
PPI_A EQU 08h
PPI_C EQU 0Ah
;
CE_ON   EQU 09h
CE_OFF  EQU 08h
WR_ON   EQU 0bh
WR_OFF  EQU 0ah
CLK_ON  EQU 0dh
CLK_OFF EQU 0ch
;
START:
    INC DE
    INC DE
    LD A,(DE)
    LD (DATE_STR_PTR),A
    INC DE
    LD A,(DE)
    LD (DATE_STR_PTR+1),A
;
    LD HL,(DATE_STR_PTR)
    CALL STRLEN
    CP 13
    JP NZ,PARAM_ERR_OUT
;
;    CALL STRCHK
;    CALL NC,MAIN    ; 文字種が正しければメイン処理へ
    CALL MAIN    ; 文字種が正しければメイン処理へ
    RET
;
;------------------------------------
; 処理メイン
;------------------------------------
MAIN:
    CALL INIT8255
    CALL WR_ON_SET
    CALL CE_ON_SET
;
    LD HL,(DATE_STR_PTR)
    LD B,13
    LD DE,12
    ADD HL,DE      ; 指定文字列の最後をポイント
;
_MAIN_LOOP:
    LD A,(HL)
    SUB A,30h       ; 数字の文字コードをBCDへ
;
    LD C,4          ; 4bit分処理
_OUT_LOOP:
    RRC A
    JP C,_ON_OUT
    PUSH AF
    LD A,00h
    JR _RTC_OUT
_ON_OUT:
    PUSH AF
    LD A,01h
_RTC_OUT:
    OUT (PPI_A),A
    CALL CLK1       ; 1Clock
    POP AF
    DEC C
    JR NZ,_OUT_LOOP
;
    DEC HL
    DEC B
    JR NZ,_MAIN_LOOP
;
    CALL CE_OFF_SET
    CALL WR_OFF_SET
;
    RET
;
;------------------------------------
; 1クロック ON→OFF
;------------------------------------
CLK1:
    LD A,CLK_ON
    OUT (PPI_CTL),A
    LD A,A          ; DUMMY
    LD A,A          ; DUMMY
    LD A,A          ; DUMMY
    LD A,A          ; DUMMY
    LD A,CLK_OFF
    OUT (PPI_CTL),A
    RET

;------------------------------------
; WRピン ON
;------------------------------------
WR_ON_SET:
    LD A,WR_ON
    OUT (PPI_CTL),A
    RET
;------------------------------------
; WRピン OFF
;------------------------------------
WR_OFF_SET:
    LD A,WR_OFF
    OUT (PPI_CTL),A
    RET

;------------------------------------
; CEピン ON
;------------------------------------
CE_ON_SET:
    LD A,CE_ON
    OUT (PPI_CTL),A
    RET
;------------------------------------
; WRピン OFF
;------------------------------------
CE_OFF_SET:
    LD A,CE_OFF
    OUT (PPI_CTL),A
    RET

;------------------------------------
; 8255初期化 ポートA OUT、ポートC OUT
;------------------------------------
INIT8255:
    LD A,80h
    OUT (PPI_CTL),A
    LD A,00h
    OUT (PPI_A),A
    OUT (PPI_C),A
;
    RET
;------------------------------------
; 文字種が数字? ERRORだったらキャリーフラグON
;------------------------------------
STRCHK:
    PUSH HL
;
    LD A,(HL)
    OR A        ; 文字列終了($00)チェック
    RET Z
;
    CP '0'
    JP M,_STR_CHK_ERR
    CP ':'
    JP M,_STR_CHK_NORM
;
_STR_CHK_ERR:
    CALL PARAM_ERR_OUT
    SCF                     ; キャリーフラグON
_STR_CHK_NORM:
    POP HL
    RET
;------------------------------------
; (strlen) 文字列長をAレジスタへ返す
;------------------------------------
STRLEN:
	PUSH HL
	PUSH BC
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
	POP BC
	POP HL
	RET
;
;------------------------------------
; 文字列 コンソール出力
;------------------------------------
STR_PR:
    PUSH HL
    LD A,(HL)
    OR A
    JR Z,_STR_PR_EXIT
    RST 08h
    INC HL
    JR STR_PR
;
_STR_PR_EXIT:
    POP HL
    RET
;
;------------------------------------
; CRLF コンソール出力
;------------------------------------
CRLF_PR:
    PUSH AF
    LD A,0Dh
    RST 08h
    LD A,0Ah
    RST 08h
    POP AF
    RET
;
;------------------------------------
; パラメーターエラー出力
;------------------------------------
PARAM_ERR_OUT:
    LD HL,PARAM_ERR_MSG
    CALL STR_PR
    RET
;
PARAM_ERR_MSG DB "*** PARAMATER ERROR",13,10,0
;
; RAM
DATE_STR_PTR    DS 2
