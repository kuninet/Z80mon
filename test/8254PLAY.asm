;
; i8254 演奏 Test (チャネル2使用)
;
;==============================================
;使用例)
;>Z 7000 CDEFGABO5C
;>Z 7000 CDEFEDCR4EFGAGFER4O4CR4CR4CR4CR4L8CCDDEEFFL4EDC
;

    org 7000h
;
PIT_C2	EQU 1Ah
PIT_CWR	EQU 1Bh
;
C2_MODE0  EQU 0B0h 
C2_MODE3  EQU 0B6h 
;
SOUND_WAIT EQU 60000
SOUND_WAIT8 EQU 30000
NO_SOUND_WAIT EQU 100
PARAM2 EQU 40A6h
;
;------------------------------------
; 処理メイン
;------------------------------------
MAIN:
;
    LD HL,START_MSG
    CALL STR_PR
;
    LD A,4
    CALL OCT_TBL_SET
    LD HL,SOUND_WAIT
    LD A,L
    LD (SOUND_WAIT_TIME),A
    LD A,H
    LD (SOUND_WAIT_TIME+1),A
;
    LD HL,(PARAM2)
;
_MAIN_LOOP:
    LD DE,_MAIN_LOOP_NEXT
    PUSH DE
;
    LD A,(HL)
    OR A
    JR Z,_MAIN_LOOP_EXIT
;
    CP 'O'
    JR Z,OCT_CHG
;
    CP 'R'
    JR Z,REST
;
    CP 'L'
    JR Z,LEN_SET
;
    JR SRCH_OUT
_MAIN_LOOP_NEXT:
    INC HL
    JR _MAIN_LOOP
;
_MAIN_LOOP_EXIT:
    POP DE
    LD HL,END_MSG
    CALL STR_PR
    RET
;
;------------------------------------
; 音の長さセット
;------------------------------------
LEN_SET:
    INC HL
    LD A,(HL)
    PUSH HL
    CP '4'
    JR Z,_LEN_4
    CP '8'
    JR Z,_LEN_8
    JR _LEN_SET_END
;
_LEN_4:
    LD HL,SOUND_WAIT
    LD A,L
    LD (SOUND_WAIT_TIME),A
    LD A,H
    LD (SOUND_WAIT_TIME+1),A
    JR _LEN_SET_END
;
_LEN_8
    LD HL,SOUND_WAIT8
    LD A,L
    LD (SOUND_WAIT_TIME),A
    LD A,H
    LD (SOUND_WAIT_TIME+1),A
;
_LEN_SET_END:
    POP HL
    RET
;
;------------------------------------
; 休符
;------------------------------------
REST:
    INC HL
    LD A,(HL)
    CP '4'
    JR Z,_WAIT_4
    CP '8'
    JR Z,_WAIT_8
    RET
;
_WAIT_4:
    LD BC,SOUND_WAIT
    JP WAIT
_WAIT_8
    LD BC,SOUND_WAIT8
    JP WAIT

;------------------------------------
; オクターブ変更
;------------------------------------
OCT_CHG:
    INC HL
    LD A,(HL)
    SUB 30h
    CALL OCT_TBL_SET
    RET
;
;------------------------------------
; オクターブテーブルセット
;------------------------------------
OCT_TBL_SET:
    PUSH BC
    LD B,A
    LD IY,OCT_TBL
_OCT_SET_LOOP:
    DEC B
    JR Z,_OCT_SET_EXIT
    INC IY
    INC IY
    LD A,(IY+0)
    CP 0FFh
    JR Z,_OCT_SET_ERR
    JR _OCT_SET_LOOP
;
_OCT_SET_ERR:
    LD IY,OCT4
_OCT_SET_EXIT:
    POP BC
    RET

;------------------------------------
; 音検索検索&発声
;------------------------------------
SRCH_OUT:
    LD E,(IY+0)
    LD D,(IY+1)
    PUSH DE
    POP IX
    LD D,7
_SRCH_LOOP:
    LD A,(IX+0)
    CP (HL)
    JR Z,_SOUND_OUT
    INC IX
    INC IX
    INC IX
    DEC D
    JR NZ,_SRCH_LOOP
    RET
;
_SOUND_OUT:
    LD A,(IX+0)
    RST 08h
    CALL CRLF_PR
    CALL OUT_PIT
    RET
;------------------------------------
; 1音発声
;------------------------------------
OUT_PIT:
    LD A,C2_MODE3
    OUT (PIT_CWR),A 
    LD A,(IX+1)
    OUT (PIT_C2),A
    LD A,(IX+2)
    OUT (PIT_C2),A
    LD BC,(SOUND_WAIT_TIME)
    CALL WAIT
;
    LD A,C2_MODE0
    OUT (PIT_CWR),A
    LD BC,NO_SOUND_WAIT
    CALL WAIT
;
    RET
;
;------------------------------------
; WAIT
;------------------------------------
WAIT:
    LD A,A     ; DUMMY
    DEC BC
    LD A,C
    OR B
    RET Z
    JR WAIT
;
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
START_MSG DB "++ 8254 PLAY START ++",13,10,0
END_MSG DB "-- 8254 PLAY END --",13,10,0
;
OCT_TBL:
    DW 0000h
    DW 0000h
    DW 0000h
    DW OCT4
    DW OCT5
    DW 0FFFFh
;
;-----
; 音程データ
;-----
SOUND_DATA:
OCT4:
; ド
    DB "C"
    DW 1258h
; レ
    DB "D"
    DW 1058h
; ミ
    DB "E"
    DW 0E8Fh
; ファ
    DB "F"
    DW 0DBEh
; ソ
    DB "G"
    DW 0C3Eh
; ラ
    DB "A"
    DW 0AE8h
; シ
    DB "B"
    DW 9B8h
OCT5:
; ド
    DB "C"
    DW 92Ch
; レ
    DB "D"
    DW 82Ch
; ミ
    DB "E"
    DW 747h
; ファ
    DB "F"
    DW 6Dfh
; ソ
    DB "G"
    DW 61Fh
; ラ
    DB "A"
    DW 574h
; シ
    DB "B"
    DW 4DCh
;END
    DB 00h
    DW 0000h
; 変数
SOUND_WAIT_TIME DS 2
    END