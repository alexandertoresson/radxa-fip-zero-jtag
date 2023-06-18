.syntax unified /* use unified assembler syntax */
.code 16        /* assemble in Thumb-2  (.thumb" can also be used) */
.globl _start
_start:
orr.w	r2, r2, #0x0300 /* Disable pwd_scp_jtagin & m3_jtag_in */
b.w 0x10007430 /* Jump to piece of code with fixup */
