
.ifndef ::__PIPETILES_H_
::__PIPETILES_H_ = 1

.setcpu "65816"
.include "includes/import_export.inc"
.include "includes/registers.inc"
.include "includes/config.inc"

.enum PIPE_DIRECTION
	UP
	DOWN
	LEFT
	RIGHT
.endenum

.struct PipeBlock
	tilePos		.addr

	upPtr		.addr
	upAnimation	.addr
	upExit		.byte

	downPtr		.addr
	downAnimation	.addr
	downExit	.byte

	leftPtr		.addr
	leftAnimation	.addr
	leftExit	.byte

	rightPtr	.addr
	rightAnimation	.addr
	rightExit	.byte
.endstruct

IMPORT_MODULE PipeGame
	;; Sets up the PPU, tiles, etc
	;; REQUIRES: 8 bit A, 16 bit Index, DB Access Registrers
	;; SETS: DP = 0
	ROUTINE Init

	;; Copies the buffer to the PPU
	;; REQUIRES: 8 bit A, 16 bit Index, DB Access registers
	ROUTINE	VBlank

	;; Updates the game start.
	;; Should be called one per frame
	;; REQUIRES: 8 bit A, 16 bit Index, DB = $7E
	ROUTINE	Update

	;; Completely redraws the buffer
	;; REQUIRES: 8 bit A, 16 bit Index, DB = $7E
	ROUTINE	RedrawBuffer

ENDMODULE

.endif ; __PIPETILES_H_

; vim: ft=asm:

