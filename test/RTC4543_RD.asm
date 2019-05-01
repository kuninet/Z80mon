;
; RTC4543SA READ Test
;
    org 6000h
;
NULL    EQU 00h
;
PPI_CTL EQU 0C3h
PPI_A EQU 0C0h
PPI_C EQU 0C2h
;
CE_ON   EQU 09h
CE_OFF  EQU 08h
WR_ON   EQU 0bh
WR_OFF  EQU 0ah
CLK_ON  EQU 0dh
CLK_OFF EQU 0ch
;
;------------------------------------
; 処理メイン
;------------------------------------
MAIN:
    CALL OUT_CLEAR
    CALL INIT8255
    CALL WR_OFF_SET
    CALL CE_ON_SET
;
    LD B,13
    LD HL,OUT_END-1
;
; 秒 取得 
    LD C,4
    CALL GET_DATA
    CALL SET_RESULT
    LD C,3
    CALL GET_DATA
    CALL SET_RESULT
; -- FDT受け捨て
    LD C,1
    CALL GET_DATA
;
; 分 取得 
    LD C,4
    CALL GET_DATA
    CALL SET_RESULT
    LD C,3
    CALL GET_DATA
    CALL SET_RESULT
; -- ユーザービット受け捨て
    LD C,1
    CALL GET_DATA
;
; 時 取得 
    LD C,4
    CALL GET_DATA
    CALL SET_RESULT
    LD C,2
    CALL GET_DATA
    CALL SET_RESULT
; -- ユーザービット受け捨て
    LD C,2
    CALL GET_DATA
;
; 曜日 取得 
    LD C,3
    CALL GET_DATA
    CALL SET_RESULT
; -- ユーザービット受け捨て
    LD C,1
    CALL GET_DATA
; 日 取得 
    LD C,4
    CALL GET_DATA
    CALL SET_RESULT
    LD C,2
    CALL GET_DATA
    CALL SET_RESULT
; -- ユーザービット受け捨て
    LD C,2
    CALL GET_DATA
;
; 月 取得 
    LD C,4
    CALL GET_DATA
    CALL SET_RESULT
    LD C,1
    CALL GET_DATA
    CALL SET_RESULT
; -- ユーザービット受け捨て
    LD C,3
    CALL GET_DATA
;
; 年 取得 
    LD C,4
    CALL GET_DATA
    CALL SET_RESULT
    LD C,4
    CALL GET_DATA
    CALL SET_RESULT
;
    LD HL,OUT_MSG
    CALL STR_PR
    CALL CRLF_PR
;
    CALL CE_OFF_SET
;
    RET
;

;------------------------------------
; 結果文字セット
;------------------------------------
SET_RESULT:
    ADD A,30h   ; 数字文字コードへ
    LD (HL),A
    DEC HL
    RET

;------------------------------------
; 指定ビット(Cレジスタ)分 読み出し Aレジスタへ
;------------------------------------
GET_DATA:
    LD D,C
    INC D
    LD B,0
_GET_DATA_LOOP:
    CALL CLK1
;
    IN A,(PPI_A)
    AND 01h
    CALL NZ,_SHIFT_BIT
    ADD A,B
    LD B,A
    DEC C
    RET Z
    JR _GET_DATA_LOOP

_SHIFT_BIT:
    PUSH BC
    PUSH AF
    LD A,D
    SUB A,C
    LD C,A
    POP AF
_SHIFT_BIT_LOOP:
    DEC C
    JR Z,_SHIFT_BIT_END
    SLA A
    JR _SHIFT_BIT_LOOP
_SHIFT_BIT_END:
    POP BC
    RET

;------------------------------------
; 出力域クリア
;------------------------------------
OUT_CLEAR:
    LD HL,OUT_MSG
    LD DE,OUT_MSG+1
    LD BC,OUT_LEN-1
    LD A,0
    LD (HL),A
    LDIR
    RET

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
; 8255初期化 ポートA IN、ポートC OUT
;------------------------------------
INIT8255:
    LD A,90h
    OUT (PPI_CTL),A
    LD A,00h
    OUT (PPI_C),A
;
    RET
;------------------------------------
; 文字列 コンソール出力
;------------------------------------
STR_PR:
    PUSH HL
_STR_PR_LOOP:
    LD A,(HL)
    OR A
    JR Z,_STR_PR_EXIT
    RST 08h
    INC HL
    JR _STR_PR_LOOP
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
OUT_MSG DS 13
OUT_END DS 1
OUT_LEN EQU $-OUT_MSG