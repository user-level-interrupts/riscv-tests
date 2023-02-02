# See LICENSE for license details.

#*****************************************************************************
# uli.S
#-----------------------------------------------------------------------------
#
# Tests basic user level interrupt delegation and handling.
# Verifies that a user-mode software interrupt (USIP) can be
# triggered by writing to the USIP bit of the mstatus/utatus CSR and is
# processed by a handler in U-mode (utvec).
#

#include "riscv_test.h"
#include "test_macros.h"

# start in machine mode
RVTEST_RV64M
RVTEST_CODE_BEGIN

  li TESTNUM, 2

1:

  # clear registers
  csrwi sideleg, 0
  csrwi mip, 0
  li t0, UIP_USIP
  csrc mie, t0

  # set flag
  li a5, 0xdeadbeef
  csrw pid, a5

  csrwi mip, MIP_USIP
  csrwi mie, MIP_USIP
  csrsi ustatus, MSTATUS_UIE
  csrsi mstatus, MSTATUS_SIE

  # delegate software interrupts to user mode
  csrwi mideleg, MIP_USIP
  csrwi sideleg, MIP_USIP
  la t0, stvec_handler
  csrw stvec, t0
  la t0, utvec_handler
  csrw utvec, t0

  # enter user mode
  la t0, do_interrupt
  csrw mepc, t0
  li t0, MSTATUS_MPP
  csrc mstatus, t0
  li t1, (MSTATUS_MPP & ~MSTATUS_MPP) * PRV_U
  csrs mstatus, t1
  li t0, 100
  li a0, 1
  li a1, 0
  mret

do_interrupt:
  # csrsi sstatus, MSTATUS_SIE
  # loop until interrupt is delivered
  sub t0, t0, a0
  bne t0, a1, do_interrupt
  # wfi is generally an illegal instruction in U-mode
  j fail

  TEST_PASSFAIL

# For now, simply verifies that we reach the installed handler
#  .align 2
#  .global mtvec_handler
#mtvec_handler:
#  li a5, 0x01abcdef
#  csrw pid, a5
#  j fail

# For now, simply verifies that we reach the installed handler
#  .align 2
#  .global stvec_handler
#stvec_handler:
#  li a5, 0xfeedbead
#  csrw pid, a5
#  j fail

# For now, simply verifies that we reach the installed handler
  .align 2
  .global utvec_handler
utvec_handler:
  li a5, 0xcafeb0ba
  csrw pid, a5
  j pass

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END
