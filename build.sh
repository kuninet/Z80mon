asl -cpu Z80 -L Z80mon.asm
p2hex -r \$-\$ -F Intel Z80mon.p
p2bin -r 0000h-7fffh Z80mon.p
