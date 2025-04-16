    .syntax unified
    .text

    /*
     * Arguments:
     *   r0 - source memory ptr
     *   r1 - target memory ptr
     *   r2 - count of bytes
     */

    .global copy
copy:
    /*
     * These two NOPs here are a safety precaution, added by Pekka Nikander
     * while debugging the STM32F05x support.  They may not be needed, but
     * there were strange problems with simpler programs, like a program
     * that had just a breakpoint or a program that first moved zero to register r2
     * and then had a breakpoint.  So, it appears safest to have these two nops.
     *
     * Feel free to remove them, if you dare, but then please do test the result
     * rigorously.  Also, if you remove these, it may be a good idea first to
     * #if 0 them out, with a comment when these were taken out, and to remove
     * these only a few months later...  But YMMV.
     */
    nop
    nop

    # subtract flash_origin and divide by 4, to get a FLASH word address
    ldr r3, flash_origin
    subs r1, r1, r3
    lsrs r1, #2

    # load address of IRQRAW register
    ldr r7, flash_irqraw
    movs r5, #1

loop:
    # clear CMDDONE in IRQRAW (@0x10)
    str r5, [r7]

    # set ADDRESS (@ 0x18)
    mov r6, r7
    adds r6, r6, 0x08
    str r1, [r6]

    # fill DATA0 (@ 0x40)
    adds r6, r6, 0x28
    ldr r4, [r0]
    str r4, [r6]
    adds r0, r0, #0x4

    # fill DATA1 (@ 0x44)
    adds r6, r6, #0x4
    ldr r4, [r0]
    str r4, [r6]
    adds r0, r0, #0x4

    # fill DATA2 (@ 0x48)
    adds r6, r6, #0x4
    ldr r4, [r0]
    str r4, [r6]
    adds r0, r0, #0x4

    # fill DATA3 (@ 0x4C)
    adds r6, r6, #0x4
    ldr r4, [r0]
    str r4, [r6]
    adds r0, r0, #0x4

    # write BURSTWRITE to COMMAND (@ 0x00)
    subs r6, r6, #0x4C
    movs r4, #0xCC
    str r4, [r6]

wait:
    # get IRQRAW
    ldr r4, [r7]

    # wait until CMDDONE flag is set
    tst r4, r5
    beq wait

    # add 4 words to ADDRESS
    adds r1, r1, #4
    # subtract 16 bytes from count
    subs r2, r2, #16
    # loop if count > 0
    bgt loop

exit:
    bkpt

    .align 4
flash_irqraw:
    .word 0x40001010
flash_origin:
    .word 0x10040000
