;
; Test Program w/PARAM
;
    org 5000h
;
PARAM1 EQU 4082h
PARAM2 EQU 4084h
PARAM3 EQU 4086h

START:
    LD HL,(PARAM1)
    CALL STR_PR
    CALL CRLF_PR
;
    LD HL,(PARAM2)
    CALL STR_PR
    CALL CRLF_PR
;
    LD HL,(PARAM3)
    CALL STR_PR
    CALL CRLF_PR
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