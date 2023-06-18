# bl30.bin patch for enabling JTAG on the SD card port on the Radxa Zero

## Background

On the S905Y2 SoC, JTAG is accessible through two separate ports:

* JTAG\_A, accessible on GPIOAO\_6 through GPIOAO\_9
* JTAG\_B, accessible on GPIOC\_0, GPIOC\_1, GPIOC\_4 and GPIOC\_5

JTAG\_B is designed to be accessible on the SD card port. GPIOAO\_6 and GPIOAO\_7 are not accessible in the Radxa Zero, at least not without HW modifications, making it necessary to use JTAG\_B.

## bl31.img/bl30.bin JTAG code

There is an SMC (Secure Monitor Call) numbered 0x82000040 which can be used to enable JTAG. Calling it with the argument 0x2 in x1 enables JTAG for the A53 CPU. However, this enables JTAG\_A and there is no support for enabling JTAG\_B.

The implementation for the SMC is in bl31.img, but this just uses a mailbox to communicate with bl30.bin which is code running on the Cortex-M3.

To enable JTAG for A53 in bl30.bin, the following is done:
1. Pin mux registers are set up to enable the appropriate functions on GPIO pins in question
2. Two undocumentted registers are written: the bits 0xffff are set in 0xFF634648, and 0x400 is set in 0xFF634668
3. The bits 0x5300 are set in AO\_SEC\_JTAG\_SCP\_CNTL to disable JTAG for PWD\_SCP and M\_3 (0x3 in bits 8:10) and select A53 for JTAG\_A TDO (0x5 in bits 14:12).

The last register does not seem to be accessible from the Cortex-A53 and seems to need to be written from the Cortex-M3, necessitating a patch for bl30.bin.

Unfortunately, there is no full datasheet for S905Y2 available, however Hardkernel provides one for S905X3. It's close enough in most regards, the main difference in the JTAG section is that the S905X3 has an A55 CPU where the S905Y2 has an A53. This has made it possible to figure out what registers to set to enable JTAG\_B.

## Solution

To select A53 for JTAG\_B TDO in AO\_SEC\_JTAG\_SCP\_CNTL, 0x5 has to be written in bits 18:16 instead of 14:12. jtag\_sel\_a53\_in also has to be set to 1 to enable JTAG\_B TDI. This patch also sets jtag\_sel\_pwd\_scp\_in and jtag\_sel\_m3\_in to JTAG\_B, but it does not attempt to enable M4 or M3 TDO for JTAG\_B. It also doesn't set up the pin muxes for JTAG\_B. bl30.bin sets the pin mux functions for JTAG\_A in AO\_RTI\_PINMUX\_REG0 and AO\_RTI\_PINMUX\_REG1, but for JTAG\_B the pin mux functions in PERIPHS\_PIN\_MUX\_9 need to be set up.

## Building

First, make sure that you have bare-metal crosscompilation tools for ARM 32-bit, arm-none-eabi-as etc. On Debian, this can be installed by installing the binutils-arm-none-eabi package.

1. Clone <https://github.com/radxa/fip.git> 
2. Make sure the md5sum of radxa-zero/bl30.bin is 7d5693a25a56613ee29b579a7ff1b03d, otherwise check out commit 5b8beba2f50ce06219c4e4844101226a81aef854.
3. Copy radxa-zero/bl30.bin from it to the directory where you cloned this git
4. run `make` in this git
5. Replace radxa-zero/bl30.bin in the radxa/fip git with bl30.bin.patched that was generated
6. run `make` in the radxa/fip git
7. See <https://wiki.radxa.com/Zero/dev/u-boot> for how to boot with a custom u-boot. I personally use `boot-g21.py`.

## TODO
* Support JTAG M3/M4
* Set up pin mux registers for JTAG\_B
	* I don't know if EL1 is enough for writing the pin mux registers, my own bare metal code is doing this from EL2.
	* The easiest way to write to PERIPHS\_PIN\_MUX\_9 without writing any code may be to use the `nm` command in u-boot.
* Look into convenient ways of calling the SMC
	* It can only be called in EL1 (kernel space) or higher
	* There seems to exist a way to call a SMC in u-boot. Might be the easiest way without writing any code. See CMD\_SMC in <https://github.com/u-boot/u-boot/blob/master/cmd/Kconfig>
