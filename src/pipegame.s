
.include "pipegame.h"
.include "includes/synthetic.inc"
.include "includes/structure.inc"
.include "includes/registers.inc"
.include "includes/config.inc"
.include "routines/random.h"
.include "routines/block.h"
.include "routines/screen.h"
.include "routines/resourceloader.h"

.include "vram.h"
.include "resources.h"

PIPE_PALETTE		= 7
PIPE_ORDER		= 1
PIPE_EMPTY_TILE		= 0
PIPE_TILEMAP_OFFSET	= (PIPE_EMPTY_TILE + 1) | (PIPE_PALETTE << TILEMAP_PALETTE_SHIFT) | (PIPE_ORDER << TILEMAP_ORDER_SHIFT)


CONFIG	PIPE_PLAY_WIDTH, 12
CONFIG  PIPE_PLAY_HEIGHT, 12


PipeBlockBankOffset	= PipeBlockBank << 16

MODULE PipeGame

.segment "SHADOW"
	BYTE	updateBufferOnZero


.segment "WRAM7E"
	WORD	buffer, 32 * 28

	;; A map of the cells in the game
	;; Each cell is a pointer to a PipeBlock in PipeBlockBank
	ADDR	cells, 16 * 14


	WORD	tmp1


.code

.A8
.I16
ROUTINE Init
	PEA	0
	PLD

	LDA	#INIDISP_FORCE
	STA	INIDISP

	LDA	#PPU_PIPEGAME_SCREEN_MODE
	STA	BGMODE

	STZ	BG1HOFS
	STZ	BG1HOFS
	STZ	BG2HOFS
	STZ	BG2HOFS

	LDA	#$FF
	STA	BG1VOFS
	STA	BG1VOFS
	STA	BG1VOFS
	STA	BG1VOFS

	Screen_SetVramBaseAndSize PPU_PIPEGAME


	; ::TODO load resource palette macro::
	; ::TODO load resource vram macro::

	LDX	#PPU_PIPEGAME_PIPES_TILES
	STX	VMADD

	; Empty tile
	LDX	#16
	LDY	#0
	REPEAT
		STY	VMDATA
		DEX
	UNTIL_ZERO

	LDA	#RESOURCES_VRAM::PIPEGAME__PIPE_TILES
	JSR	ResourceLoader__LoadVram_8A

	LDA	#PIPE_PALETTE * 16
	STA	CGADD
	LDA	#RESOURCES_PALETTES::PIPEGAME__PIPES
	JSR	ResourceLoader__LoadPalette_8A

	; ::DEBUG BG::
	STZ	CGADD
	LDA	#$0F
	STA	CGDATA
	STA	CGDATA

	; ::TODO load background::

	JSR	Clear

	; ::TODO starting position::

	LDA	#TM_BG1 | TM_OBJ
	STA	TM

	RTS



.A8
.I16
ROUTINE VBlank
	LDA	updateBufferOnZero
	IF_ZERO
		TransferToVramLocation	buffer, PPU_PIPEGAME_PIPES_MAP

		; A is non-zero
		STA	updateBufferOnZero
	ENDIF

	RTS



; DB = $7E
.A8
.I16
ROUTINE Update
	; ::TODO::


	RTS



; DB = $7E
.A8
.I16
ROUTINE	RedrawBuffer
	REP	#$30
.A16

	LDX	#0
	TXY

	REPEAT
		PHX

		LDA	cells, X

		IF_NOT_ZERO
			TAX
			LDA	f:PipeBlockBankOffset + PipeBlock::tilePos, X
			TAX

			LDA	f:PipeTileMap, X
			ADD	#PIPE_TILEMAP_OFFSET
			STA	buffer, Y

			LDA	f:PipeTileMap + 2, X
			ADD	#PIPE_TILEMAP_OFFSET
			STA	buffer + 2, Y

			LDA	f:PipeTileMap + 64, X
			ADD	#PIPE_TILEMAP_OFFSET
			STA	buffer + 64, Y

			LDA	f:PipeTileMap + 64 + 2, X
			ADD	#PIPE_TILEMAP_OFFSET
			STA	buffer + 64 + 2, Y
		ELSE
			LDA	#PIPE_EMPTY_TILE + PIPE_TILEMAP_OFFSET
			STA	buffer, Y
			STA	buffer + 2, Y
			STA	buffer + 64, Y
			STA	buffer + 64 + 2, Y
		ENDIF

		TYA
		ADD	#4
		IF_NOT_BIT	#32 * 2 - 1
			ADD	#32 * 2
		ENDIF
		TAY

		PLA
		ADD	#2
		TAX

		CPX	#.sizeof(cells)
	UNTIL_GE


	;; ::TODO draw the next pieces bit::

	SEP	#$20
.A8

	STZ	updateBufferOnZero
	RTS



;; Fills the buffer with empty tiles.
.A8
.I16
ROUTINE Clear
	REP	#$30
.A16
.I16
	PHB

	LDA	#0
	STA	f:cells
	LDX	#.loword(cells)
	LDY	#.loword(cells) + 2
	LDA	#.sizeof(cells) - 2 - 1
	MVN	.bankbyte(cells), .bankbyte(cells)


	LDA	#PIPE_EMPTY_TILE + PIPE_TILEMAP_OFFSET
	STA	buffer

	LDX	#.loword(buffer)
	LDY	#.loword(buffer) + 2
	LDA	#.sizeof(buffer) - 2 - 1
	MVN	.bankbyte(buffer), .bankbyte(buffer)

	SEP	#$20
.A8
	STZ	updateBufferOnZero

	PLB

	RTS


;; Draws the given tile to the given coordinates
;; REQUIRES: DB access buffer
;; INPUT:
;;	X: address of the cell to update
.A8
.I16
ROUTINE DrawTile
	; cellPos to bufferPos calculation
	;	x = cellPos & 0x1F / 2
	;	y = cellPos / 16 / 2
	;	bufferPos = (y * 64 + x * 2) * 2


	; bufferPos = ((cellPos & 0xFFE0) * 2) + (cellPos & 0x1E)) * 2

	REP	#$30
.A16

	TXA
	AND	#$FFE0
	ASL
	STA	tmp1

	TXA
	AND	#$1E
	ADD	tmp1
	ASL

	TAY

	LDA	cells, X
	IF_NOT_ZERO
		TAX
		LDA	f:PipeBlockBankOffset + PipeBlock::tilePos, X
		TAX


		LDA	f:PipeTileMap, X
		ADD	#PIPE_TILEMAP_OFFSET
		STA	buffer, Y

		LDA	f:PipeTileMap + 2, X
		ADD	#PIPE_TILEMAP_OFFSET
		STA	buffer + 2, Y

		LDA	f:PipeTileMap + 64, X
		ADD	#PIPE_TILEMAP_OFFSET
		STA	buffer + 64, Y

		LDA	f:PipeTileMap + 64 + 2, X
		ADD	#PIPE_TILEMAP_OFFSET
		STA	buffer + 64 + 2, Y
	ELSE
		LDA	#PIPE_EMPTY_TILE + PIPE_TILEMAP_OFFSET
		STA	buffer, Y
		STA	buffer + 2, Y
		STA	buffer + 64, Y
		STA	buffer + 64 + 2, Y
	ENDIF

	SEP	#$20
.A8
	STZ	updateBufferOnZero

	RTS


.segment "BANK1"
	.include "resources/pipes/pipes.inc"

ENDMODULE

