asl -cpu Z80 -L test/test.asm
p2hex -r \$-\$ -F Intel test/test.p

asl -cpu Z80 -L test/test_param.asm
p2hex -r \$-\$ -F Intel test/test_param.p

asl -cpu Z80 -L test/RTC4543_WR.asm
p2hex -r \$-\$ -F Intel test/RTC4543_WR.p

asl -cpu Z80 -L test/RTC4543_RD.asm
p2hex -r \$-\$ -F Intel test/RTC4543_RD.p

asl -cpu Z80 -L test/8254PLAY.asm
p2hex -r \$-\$ -F Intel test/8254PLAY.p

asl -cpu Z80 -L -D KZ80 -OLIST lst/Z80mon_KZ80.lst -o p/Z80mon_KZ80.p Z80mon.asm
p2hex -r \$-\$ -F Intel p/Z80mon_KZ80.p obj/Z80mon_KZ80.hex 
p2bin -r 0000h-7fffh p/Z80mon_KZ80.p obj/Z80mon_KZ80.bin

asl -cpu Z80 -L -D SBC8080SUB -OLIST lst/Z80mon_8080SUB.lst -o p/Z80mon_8080SUB.p Z80mon.asm
p2hex -r \$-\$ -F Intel p/Z80mon_8080SUB.p obj/Z80mon_8080SUB.hex 
p2bin -r 0000h-7fffh p/Z80mon_8080SUB.p obj/Z80mon_8080SUB.bin

asl -cpu Z80 -L -D MC6850 -OLIST lst/Z80mon_6850.lst -o p/Z80mon_6850.p Z80mon.asm
p2hex -r \$-\$ -F Intel p/Z80mon_6850.p obj/Z80mon_6850.hex 
p2bin -r 0000h-7fffh p/Z80mon_6850.p obj/Z80mon_6850.bin

asl -cpu Z80 -L -D i8259_8254 -OLIST lst/Z80mon_8259_8254.lst -o p/Z80mon_8259_8254.p Z80mon.asm
p2hex -r \$-\$ -F Intel p/Z80mon_8259_8254.p obj/Z80mon_8259_8254.hex 
p2bin -r 0000h-7fffh p/Z80mon_8259_8254.p obj/Z80mon_8259_8254.bin