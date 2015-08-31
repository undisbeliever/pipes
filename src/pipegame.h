
.ifndef ::__PIPETILES_H_
::__PIPETILES_H_ = 1

.setcpu "65816"
.include "includes/import_export.inc"
.include "includes/registers.inc"
.include "includes/config.inc"

.enum PIPE_DIRECTION
	UP	= 1
	DOWN	= 2
	LEFT	= 4
	RIGHT	= 8
.endenum

PIPE_ANIMATION_COUNT = 15

.struct PipeBlockAnimation
	;; Address of the pipe AFTER the animation is completed
	;; If 0 then water cannot enter this pipe from this direction
	pipeBlockPtr	.addr

	;; The starting address of the first animation frame
	;; within `PipeTileMap`.
	;; This address is incremented by 4 bytes each frame and
	;; lasts for PIPE_ANIMATION_COUNT frames.
	animationTile	.addr

	;; The direction of the water (PIPE_EXIT) after animation has completed
	exitDirection	.byte
.endstruct

.struct PipeBlock
	;; The address within the `PipeTileMap` of the tile to display.
	tilePos		.addr

	;; The address of the metasprite representing this pipe
	metaSpritePtr		.addr

	;; The animations for each of the 4 directions
	animations	.tag	PipeBlockAnimation 4
.endstruct

IMPORT_MODULE PipeGame
	;; Sets up the PPU, tiles, etc
	;; REQUIRES: 8 bit A, 16 bit Index, DB Access Registrers
	;; SETS: DP = 0
	ROUTINE Init

	;; Copies the buffer to the PPU
	;; REQUIRES: 8 bit A, 16 bit Index, DB Access registers
	ROUTINE	VBlank

	;; Starts a new game
	;; REQUIRES: 8 bit A, 16 bit Index
	ROUTINE	NewGame

	;; Updates the game state
	;; Should be called once per frame
	;; REQUIRES: 8 bit A, 16 bit Index, DB = $7E
	;; RETURNS: Carry set if game still in play
	;;	    Carry clear if game over
	ROUTINE	Update

	;; Completely redraws the buffer
	;; REQUIRES: 8 bit A, 16 bit Index, DB = $7E
	ROUTINE	RedrawBuffer

ENDMODULE

.endif ; __PIPETILES_H_

; vim: ft=asm:

