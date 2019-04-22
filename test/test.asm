;
; Test Program
;

    org 5000h

START:
    LD HL,HELLO_MSG
    CALL STR_PR
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
HELLO_MSG DB "HELLO WORLD",13,10,0