.syntax unified /* use unified assembler syntax */
.code 16        /* assemble in Thumb-2  (.thumb" can also be used) */
.globl _start
_start:
orr.w	r2, r2, #0x50000 /* set jtag_pad_b_out sel to A53 */
orr.w	r2, r2, #0x7 /* set jtag_sel_A53_in, jtag_sel_pwd_scp_in and jtag_sel_m3_in to pad_b */
str	r2, [r3, #0]
pop	{r4, r5, r6, pc}
