;
; Test Program w/PARAM
;
    org 5000h
;
; 入力パラメーター
; --------------
;   B  : 引数の個数
;   DE : 引数ポインタテーブルのTOP
;

START:

_LOOP:
    LD A,(DE)
    LD L,A
    INC DE
    LD A,(DE)
    LD H,A
;
    CALL STR_PR
    CALL CRLF_PR
    INC DE
    DJNZ _LOOP
;
    RET
;
STR_PR:
    LD A,(HL)
    OR A
    RET Z
    RST 08h
    INC HL
    JR STR_PR
;
CRLF_PR:
    LD A,0Dh
    RST 08h
    LD A,0Ah
    RST 08h
    RET
;