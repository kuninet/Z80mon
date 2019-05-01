asl -cpu Z80 -L test/test.asm
p2hex -r \$-\$ -F Intel test/test.p

asl -cpu Z80 -L test/test_param.asm
p2hex -r \$-\$ -F Intel test/test_param.p

asl -cpu Z80 -L -D KZ80 -OLIST lst/Z80mon_KZ80.lst -o p/Z80mon_KZ80.p Z80mon.asm
p2hex -r \$-\$ -F Intel p/Z80mon_KZ80.p obj/Z80mon_KZ80.hex 
p2bin -r 0000h-7fffh p/Z80mon_KZ80.p obj/Z80mon_KZ80.bin

asl -cpu Z80 -L -D SBC8080SUB -OLIST lst/Z80mon_8080SUB.lst -o p/Z80mon_8080SUB.p Z80mon.asm
p2hex -r \$-\$ -F Intel p/Z80mon_8080SUB.p obj/Z80mon_8080SUB.hex 
p2bin -r 0000h-7fffh p/Z80mon_8080SUB.p obj/Z80mon_8080SUB.bin

asl -cpu Z80 -L -D MC6850 -OLIST lst/Z80mon_6850.lst -o p/Z80mon_6850.p Z80mon.asm
p2hex -r \$-\$ -F Intel p/Z80mon_6850.p obj/Z80mon_6850.hex 
p2bin -r 0000h-7fffh p/Z80mon_6850.p obj/Z80mon_6850.bin
