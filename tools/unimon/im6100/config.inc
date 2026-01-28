;;; -*- asm -*-
;;;
;;; Universal Monitor IM6100 config file (sample)
;;;

;;; use modifications for TangNano6100MEM
;;; by Ryo Mukai
USE_TANGNANO	= 1	; for TangNano6100MEM
USE_CP		= 1	; use control panel memory

;;;
;;; CPU
;;;

;;;
;;; Memory
;;;

ENTRY:	EQU	00100		; Entry table (must fit in ZERO page)
WORK_B:	EQU	00120		; Work area (must fit in ZERO page)
PROG_B:	EQU	05000		; Program area (must be writable)

BUFLEN:	EQU	16

;;;
;;; Options
;;;

USE_HEXCMD = 1			; L(oad) command
	
;;;
;;; Console Driver
;;;

;;; EMILY Board (Shared Memory)

USE_DEV_EMILY = 0
	IF USE_DEV_EMILY
	;;
SMBASE:	EQU 00160
	ENDIF

