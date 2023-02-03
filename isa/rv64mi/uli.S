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

  # clear CSR registers for a clean slate
  csrwi sideleg, 0
  csrwi mip, 0
  li t0, UIP_USIP
  csrc mie, t0

  # set initial flag
  li a5, 0xdeadbeef
  csrw pid, a5

  # Enable supervisor and user interrupts (cascading)
  csrsi mstatus, MSTATUS_UIE
  csrsi mstatus, MSTATUS_SIE

  # Enable user software interrupts
  csrwi mie, MIP_USIP
  
  # delegate software interrupts to user mode
  csrwi mideleg, MIP_USIP
  csrwi sideleg, MIP_USIP

  # install ULI handler
  la t0, utvec_handler
  csrw utvec, t0

  # enter user mode
  la t0, do_interrupt
  csrw mepc, t0
  li t0, MSTATUS_MPP
  csrc mstatus, t0
  li t1, (MSTATUS_MPP & ~MSTATUS_MPP) * PRV_U
  csrs mstatus, t1
  mret

do_interrupt:
  # write user software interrupt pending bit
  csrwi uip, MIP_USIP

  # verify flag set by ULI handler
  li a5, 0xcafeb0ba
  csrr a4, pid
  bne a4, a5, fail
  j pass

  # macro for pass/fail routines
  TEST_PASSFAIL

# ULI handler
  .align 2
  .global utvec_handler
utvec_handler:
  # set flag value 
  li a5, 0xcafeb0ba
  csrw pid, a5
  # clear pending interrupt bit and return
  csrci uip, MIP_USIP
  uret

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END
