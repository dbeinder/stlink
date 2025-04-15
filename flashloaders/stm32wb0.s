    .syntax unified
    .text

    /*
     * Arguments:
     *   r0 - source memory ptr
     *   r1 - target memory ptr
     *   r2 - count of bytes

     * Register usage:
     *   r0 - SRAM source pointer (incrementing)
     *   r1 - FLASH word address (incrementing)
     *   r2 - remaining bytes count (decrementing)
     *   r3 - scratch
     *   r4 - scratch
     *   r5 - scratch
     *   r6 - scratch
     *   r7 - roving FLASH peripheral pointer
     */

    .global copy
copy:
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

    # fill ADDRESS (@ 0x18)
    adds r7, r7, #0x08
    str r1, [r7]

    # fill DATA0-3 (@ 0x40 - 0x4C)
    adds r7, r7, #0x28
    ldmia r0!, { r3, r4, r5, r6 }
    stmia r7!, { r3, r4, r5, r6 }
    # r7 is now 0x50

    # write BURSTWRITE to COMMAND (@ 0x00)
    subs r7, r7, #0x50
    movs r4, #0xCC
    str r4, [r7]

    # move r7 back to IRQRAW
    adds r7, r7, #0x10
    movs r5, #1

wait:
    # wait until CMDDONE flag is set in IRQRAW
    ldr r4, [r7]
    tst r4, r5
    beq wait

    # add 4 to flash word address, subtract 16 bytes from count
    adds r1, r1, #4
    subs r2, r2, #16

    # loop if count > 0
    bgt loop

exit:
    bkpt

    .align 2
flash_irqraw:
    .word 0x40001010
flash_origin:
    .word 0x10040000
