
.include "pipegame.h"
.include "includes/synthetic.inc"
.include "includes/structure.inc"
.include "includes/registers.inc"
.include "includes/config.inc"
.include "routines/random.h"
.include "routines/block.h"
.include "routines/screen.h"
.include "routines/controller.h"
.include "routines/metasprite.h"
.include "routines/resourceloader.h"

.include "vram.h"
.include "resources.h"


PIPE_PALETTE		= 7
PIPE_ORDER		= 1
PIPE_EMPTY_TILE		= 0
PIPE_TILEMAP_OFFSET	= (PIPE_EMPTY_TILE + 1) | (PIPE_PALETTE << TILEMAP_PALETTE_SHIFT) | (PIPE_ORDER << TILEMAP_ORDER_SHIFT)

CONFIG	PIPE_PLAYFIELD_WIDTH, 12
CONFIG  PIPE_PLAYFIELD_HEIGHT, 12

CONFIG  PIPE_PLAYFIELD_XPOS, 48
CONFIG  PIPE_PLAYFIELD_YPOS, 16

CONFIG	PIPE_MAX_NEXT, 8

CONFIG	PIPE_NEXTLIST_XPOS, 16
CONFIG	PIPE_NEXTLIST_YPOS, 44

CONFIG	PIPE_NEXTLIST_SPACING, 1

;; Minimum manhattan distance between the start and end pipes
CONFIG	PIPE_MIN_START_END_DISTANCE, 6

CONFIG	PIPE_NEWGAME_PADDING, 3

CONFIG	STARTING_ANIMATION_SPEED, 256 / (3 * FPS / PIPE_ANIMATION_COUNT)

PipeBlockBankOffset	= PipeBlockBank << 16

MODULE PipeGame

.enum GameState
	GAME_OVER	=  0
	NEW_GAME	=  2
	WAIT_FOR_START	=  4
	PLAY_GAME	=  6
	PAUSE		=  8
	LEAKING		= 10
.endenum

.segment "SHADOW"
	BYTE	updateBufferOnZero

	BYTE	canReplacePipes

	UINT16	nPiecesPlaced
	UINT16	runLength

	UINT16	playTimeSeconds
	UINT8	playTimeFrames


	WORD	tmp1
	WORD	tmp2
	WORD	tmp3
	WORD	tmp4
	WORD	tmp5


.segment "WRAM7E"
	WORD	buffer, 32 * 32

	;; A map of the grid in the game
	;; Each cell is a pointer to a PipeBlock in PipeBlockBank
	ADDR	grid, 16 * 14

	;; Current game state
	ADDR	state

	;; Address of the PipeBlock in PipeBlockBank
	;; that the cursor is on
	ADDR	cursorPipe

	;; Non-zero if the cursor is on a free cell
	BYTE	cursorValidIfZero

	;; The xPos of the cursor
	BYTE	cursorXpos
	;; The yPos of the cursor
	BYTE	cursorYpos


	;; Number of the next items to show on screen
	BYTE	noOfNextToShow

	;; The list of next items.
	;; Order first -> last
	ADDR	nextList,	PIPE_MAX_NEXT



	;; Address of the PipeBlockAnimation that is being animated.
	;; If NULL then there is no animation
	ADDR	animationPtr

	;; Address of the current cell being animated.
	ADDR	animationCellPos

	;; The speed of the animation
	;; 0:8:8 fixed point
	WORD	animationSpeed

	;; Current frame counter
	;; Starts at PIPE_ANIMATION_COUNT goes down to 0
	;; 0:8:8 fixed point
	WORD	animationCounter
.code

.A8
.I16
ROUTINE Init
	PEA	0
	PLD

	; Reset game config
	LDA	#1
	STA	canReplacePipes



	LDA	#INIDISP_FORCE
	STA	INIDISP

	LDA	#PPU_PIPEGAME_SCREEN_MODE
	STA	BGMODE

	LDA	#.lobyte(-PIPE_PLAYFIELD_XPOS)
	STA	BG1HOFS
	LDA	#.hibyte(-PIPE_PLAYFIELD_XPOS)
	STA	BG1HOFS

	LDA	#.lobyte(-PIPE_PLAYFIELD_YPOS - 1)
	STA	BG1VOFS
	LDA	#.hibyte(-PIPE_PLAYFIELD_YPOS - 1)
	STA	BG1VOFS


	STZ	BG2HOFS
	STZ	BG2HOFS

	LDA	#$FF
	STA	BG2VOFS
	STA	BG2VOFS

	Screen_SetVramBaseAndSize PPU_PIPEGAME


	; ::SHOULDDO load resource palette macro::
	; ::SHOULDDO load resource vram macro::


	; Background
	; ----------
	STZ	CGADD

	LDA	#RESOURCES_PALETTES::PIPEGAME__BACKGROUND
	JSR	ResourceLoader__LoadPalette_8A

	LDX	#PPU_PIPEGAME_BACKGROUND_TILES
	STX	VMADD
	LDA	#RESOURCES_VRAM::PIPEGAME__BACKGROUND_TILES
	JSR	ResourceLoader__LoadVram_8A

	LDX	#PPU_PIPEGAME_BACKGROUND_MAP
	STX	VMADD
	LDA	#RESOURCES_VRAM::PIPEGAME__BACKGROUND_TILEMAP
	JSR	ResourceLoader__LoadVram_8A


	; Tiles
	; -----

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
	LDA	#RESOURCES_PALETTES::PIPEGAME__PIPE_TILES
	JSR	ResourceLoader__LoadPalette_8A


	; OAM
	; ---

	LDY	#PPU_PIPEGAME_OAM_TILES
	STY	VMADD

	LDA	#RESOURCES_VRAM::PIPEGAME__PIPE_SPRITES
	JSR	ResourceLoader__LoadVram_8A

	LDA	#128
	STA	CGADD
	LDA	#RESOURCES_PALETTES::PIPEGAME__PIPE_SPRITES
	JSR	ResourceLoader__LoadPalette_8A



	LDA	#TM_BG1 | TM_BG2 | TM_OBJ
	STA	TM

	LDX	#GameState::NEW_GAME
	STX	state

	JMP	Clear




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

	JSR	MetaSprite__InitLoop

	LDX	state
	JSR	(.loword(StateTable), X)

	JSR	MetaSprite__FinalizeLoop

	.assert GameState::GAME_OVER = 0, error, "Bad assumption"
	LDX	state
	IF_ZERO
		CLC
		RTS
	ENDIF

	SEC
	RTS

.rodata
StateTable:
	.addr	GameOver
	.addr	NewGame
	.addr	WaitForStart
	.addr	PlayGame
	.addr	PauseGame
	.addr	Leaking

.code



.A8
.I16
ROUTINE	NewGame

tmpDistance	= tmp1
tmpXpos		= tmp2
tmpYpos		= tmp3
tmpX2pos	= tmp4
tmpY2pos	= tmp5

	PHB
	LDA	#.bankbyte(buffer)
	PHA
	PLB

	JSR	Clear


	;; ::TODO speed determined by level and region::
	LDX	#STARTING_ANIMATION_SPEED
	STX	animationSpeed

	LDX	#0
	STX	animationCounter

	LDA	#PIPE_PLAYFIELD_WIDTH / 2
	STA	cursorXpos

	LDA	#PIPE_PLAYFIELD_HEIGHT / 2
	STA	cursorYpos

	; Reset stats

	LDX	#0
	STX	nPiecesPlaced
	STX	runLength

	STZ	playTimeFrames
	STX	playTimeSeconds



	LDA	#PIPE_MAX_NEXT
	STA	noOfNextToShow

	LDX	#PIPE_MAX_NEXT + 1
	REPEAT
		PHX
		JSR	GenerateNextPipe
		PLX
		DEX
	UNTIL_ZERO


	; Random start location
	; ---------------------
	PEA	$7E80
	PLB

	LDY	#PIPE_PLAYFIELD_WIDTH - PIPE_NEWGAME_PADDING * 2
	JSR	Random__Rnd_U16Y
	STY	tmpXpos

	LDY	#PIPE_PLAYFIELD_HEIGHT - PIPE_NEWGAME_PADDING * 2
	JSR	Random__Rnd_U16Y
	STY	tmpYpos

	LDY	#N_STARTING_BLOCKS
	JSR	Random__Rnd_U16Y

	PLB

	REP	#$30
.A16
	TYA
	ASL
	TAX


	LDA	tmpYpos
	ADD	#PIPE_NEWGAME_PADDING
	ASL
	ASL
	ASL
	ASL
	ADD	tmpXpos
	ADD	#PIPE_NEWGAME_PADDING
	ASL
	TAY

	STY	animationCellPos

	LDA	f:StartingBlocks, X
	STA	grid, Y

	ADD	#PipeBlock::animations

	REPEAT
		TAX
		LDA	f:PipeBlockBankOffset + PipeBlockAnimation::pipeBlockPtr, X
	WHILE_ZERO
		TXA
		ADD	#.sizeof(PipeBlockAnimation)
	WEND

	STX	animationPtr


	; Draw the second pipe

	; Y = animationCellPos

	LDA	f:PipeBlockBankOffset + PipeBlockAnimation::exitDirection, X
	AND	#$00FF

	IF_BIT	#PIPE_DIRECTION::UP | PIPE_DIRECTION::DOWN
		; up/down

		CMP	#PIPE_DIRECTION::UP
		IF_EQ
			TYA
			SUB	#16 * 2
		ELSE
			TYA
			ADD	#16 * 2
		ENDIF

		TAY

		LDA	#.loword(PipeBlock_Vertical)
	ELSE
		; Left/Right

		CMP	#PIPE_DIRECTION::LEFT
		IF_EQ
			DEY
			DEY
		ELSE
			; RIGHT
			INY
			INY
		ENDIF

		LDA	#.loword(PipeBlock_Horizontal)
	ENDIF

	STA	grid, Y

	SEP	#$20
.A8

	TYX
	JSR	DrawTile


	; Draw the end tile
	; -----------------

	PEA	$7E80
	PLB

.A8
	REPEAT
		LDY	#PIPE_PLAYFIELD_WIDTH - PIPE_NEWGAME_PADDING * 2
		JSR	Random__Rnd_U16Y
		STY	tmpX2pos

		LDY	#PIPE_PLAYFIELD_HEIGHT - PIPE_NEWGAME_PADDING * 2
		JSR	Random__Rnd_U16Y
		STY	tmpY2pos

		REP	#$30
.A16
		TYA
		SUB	tmpYpos
		IF_MINUS
			NEG16
		ENDIF
		STA	tmpDistance

		LDA	tmpX2pos
		SUB	tmpXpos
		IF_MINUS
			NEG16
		ENDIF

		ADD	tmpDistance
		CMP	#PIPE_MIN_START_END_DISTANCE

		SEP	#$20
.A8
	UNTIL_GE

	LDY	#N_ENDING_BLOCKS
	JSR	Random__Rnd_U16Y

	PLB

	REP	#$20
.A16
	TYA
	ASL
	TAX


	LDA	tmpY2pos
	ADD	#PIPE_NEWGAME_PADDING
	ASL
	ASL
	ASL
	ASL
	ADD	tmpX2pos
	ADD	#PIPE_NEWGAME_PADDING
	ASL
	TAY

	LDA	f:EndingBlocks, X
	STA	grid, Y

	SEP	#$20
.A8

	TYX
	JSR	DrawTile

	LDX	#GameState::WAIT_FOR_START
	STX	state

	PLB

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

		LDA	grid, X

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

		CPX	#.sizeof(grid)
	UNTIL_GE

	SEP	#$20
.A8

	JSR	DrawAnimation

	;; ::TODO draw the next pieces bit::

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
	STA	f:grid
	LDX	#.loword(grid)
	LDY	#.loword(grid) + 2
	LDA	#.sizeof(grid) - 2 - 1
	MVN	.bankbyte(grid), .bankbyte(grid)


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


;; Game States
;; ===========

; DP = $7E
.A8
.I16
ROUTINE	GameOver
	; ::TODO code::
	RTS



;; Starts a new Game
; DP = $7E
.A8
.I16
ROUTINE	WaitForStart
	; ::TODO code::

	LDX	#GameState::PLAY_GAME
	STX	state

	RTS



;; Plays a single frame of the game
; DP = $7E
.A8
.I16
ROUTINE	PlayGame
	; ::SHOULDO dynamic FPS::

	LDA	playTimeFrames
	INC
	CMP	#FPS

	IF_EQ
		STZ	playTimeFrames

		REP	#$30
.A16
		INC	playTimeSeconds
		IF_ZERO
			LDA	#$FFFF
			STA	playTimeSeconds
		ENDIF
	ENDIF

	REP	#$30
.A16

	; Process the pipe animation
	; --------------------------

	LDX	animationPtr
	IFL_NOT_ZERO
		LDA	animationCounter
		ADD	animationSpeed
		STA	animationCounter

		CMP	#(PIPE_ANIMATION_COUNT + 1) << 8
		IFL_GE
			LDX	animationPtr
			LDA	f:PipeBlockBankOffset + PipeBlockAnimation::pipeBlockPtr, X

			LDX	animationCellPos
			STA	grid, X

			INC	runLength
			IF_ZERO
				LDA	#$FFFF
				STA	runLength
			ENDIF

			SEP	#$20
.A8
			JSR	DrawTile

			; Select next pipe
			LDX	animationPtr
			LDA	f:PipeBlockBankOffset + PipeBlockAnimation::exitDirection, X

			LDY	animationCellPos


			CMP	#PIPE_DIRECTION::END
			IF_EQ
				JMP	FinishedLevel
			ENDIF

			IF_BIT	#PIPE_DIRECTION::UP | PIPE_DIRECTION::DOWN
				CMP	#PIPE_DIRECTION::UP
				IF_EQ
					; UP

					REP	#$30
.A16
					LDA	animationCellPos
					AND	#$FFE0
					IF_ZERO
						JMP	SprungALeak
					ENDIF

					LDA	animationCellPos
					SUB	#16 * 2
					STA	animationCellPos

					LDY	#0 * .sizeof(PipeBlockAnimation)
				ELSE
					; DOWN

					REP	#$30
.A16
					LDA	animationCellPos
					AND	#$FFE0
					CMP	#(PIPE_PLAYFIELD_HEIGHT - 1) * 32
					IF_GE
						JMP	SprungALeak
					ENDIF

					LDA	animationCellPos
					ADD	#16 * 2
					STA	animationCellPos

					LDY	#1 * .sizeof(PipeBlockAnimation)
				ENDIF
			ELSE
.A8
				CMP	#PIPE_DIRECTION::LEFT
				IF_EQ
					; LEFT

					REP	#$30
.A16
					LDA	animationCellPos
					AND	#$1F
					IF_ZERO
						JMP	SprungALeak
					ENDIF

					LDA	animationCellPos
					DEC
					DEC
					STA	animationCellPos

					LDY	#2 * .sizeof(PipeBlockAnimation)
				ELSE
					; RIGHT

					REP	#$30
.A16
					LDA	animationCellPos
					AND	#$1F
					CMP	#(PIPE_PLAYFIELD_WIDTH - 1) * 2
					IF_GE
						JMP	SprungALeak
					ENDIF

					LDA	animationCellPos
					INC
					INC
					STA	animationCellPos

					LDY	#3 * .sizeof(PipeBlockAnimation)
				ENDIF
			ENDIF

.A16
			; A = new animationCellPos
			; Y = pipeBlockAnimation offset

			TAX
			LDA	grid, X
			IF_ZERO
				JMP	SprungALeak
			ENDIF

			STY	tmp1
			ADD	tmp1
			ADD	#PipeBlock::animations
			TAX

			LDA	f:PipeBlockBankOffset + PipeBlockAnimation::pipeBlockPtr, X
			IF_ZERO
				JMP	SprungALeak
			ENDIF

			STX	animationPtr
			STZ	animationCounter
		ELSE
.A16
			SEP	#$20
.A8
			JSR	DrawAnimation
		ENDIF
	ENDIF


	; Move cursor
	; -----------

	SEP	#$20
.A8

	JSR	Controller__UpdateRepeatingDPad

	LDA	Controller__pressed + 1

	IF_BIT	#JOYH_UP
		LDA	cursorYpos
		DEC
		IF_MINUS
			LDA	#0
		ENDIF

		STA	cursorYpos

	ELSE_BIT #JOYH_DOWN
		LDA	cursorYpos
		INC
		CMP	#PIPE_PLAYFIELD_HEIGHT
		IF_GE
			LDA	#PIPE_PLAYFIELD_HEIGHT - 1
		ENDIF

		STA	cursorYpos
	ENDIF

	LDA	Controller__pressed + 1

	IF_BIT	#JOYH_LEFT
		LDA	cursorXpos
		DEC
		IF_MINUS
			LDA	#0
		ENDIF

		STA	cursorXpos

	ELSE_BIT #JOYH_RIGHT
		LDA	cursorXpos
		INC
		CMP	#PIPE_PLAYFIELD_WIDTH
		IF_GE
			LDA	#PIPE_PLAYFIELD_WIDTH - 1
		ENDIF

		STA	cursorXpos
	ENDIF


	; Test if cursor is on a free cell
	; --------------------------------
	REP	#$30
.A16
	LDA	cursorYpos
	AND	#$00FF
	ASL
	ASL
	ASL
	ASL
	STA	tmp1

	LDA	cursorXpos
	AND	#$00FF
	ADD	tmp1
	ASL

	; tmp1 = gridPos
	; can place piece if:
	;	- gridPos != animationCellPos
	;	- cell is empty
	;	- cell's canReplace value is true AND canReplacePipes is true

	STA	tmp1

	CMP	animationCellPos
	BEQ	_CursorInvalid

	TAX
	LDA	grid, X
	BEQ	_CursorValid

	TAX

	SEP	#$20
.A8
	LDA	canReplacePipes
	BEQ	_CursorInvalid

	LDA	f:PipeBlockBankOffset + PipeBlock::canReplace, X

	IF_NOT_ZERO
_CursorValid:
		SEP	#$20
.A8
		LDA	#0
	ELSE
_CursorInvalid:
		SEP	#$20
.A8
		LDA	#$FF
	ENDIF

	STA	cursorValidIfZero

	IF_ZERO
		; Place piece on button press
		; ---------------------------

		REP	#$30
.A16
		LDA	Controller__pressed

		IF_BIT	#JOY_BUTTONS
			INC	nPiecesPlaced
			IF_ZERO
				LDA	#$FFFF
				STA	nPiecesPlaced
			ENDIF

			; tmp1 = gridPos
			LDX	tmp1
			LDA	cursorPipe
			STA	grid, X

			JSR	DrawTile
			JSR	GenerateNextPipe
		ENDIF

		SEP	#$20
.A8
	ENDIF

	JSR	DrawCursorPipe
	JSR	DrawNextList

	RTS


;; The level is over
;; Prep the score
.A8
.I16
ROUTINE	FinishedLevel
	LDX	#GameState::GAME_OVER
	STX	state

	; ::TODO::
	RTS


;; Pipe is leaking
;; Setup the game state
.A16
.I16
ROUTINE	SprungALeak
	LDX	#GameState::LEAKING
	STX	state

	SEP	#$20
.A8
	RTS


;; The pipe is leaking
; DP = $7E
.A8
.I16
ROUTINE	Leaking
	; ::TODO code::
	REPEAT
	FOREVER



;; The game is paused
; DP = $7E
.A8
.I16
ROUTINE	PauseGame
	RTS



;; Common
;; ======


;; Draws the tile currently being animated
;; REQUIRES: DP access buffer
.A8
.I16
ROUTINE DrawAnimation
	LDX	animationPtr
	IF_NOT_ZERO
		LDA	animationCounter + 1

		REP	#$30
.A16
		AND	#$00FF

		CMP	#PIPE_ANIMATION_COUNT
		IF_LT
			ASL
			ASL

			ADD	f:PipeBlockBankOffset + PipeBlockAnimation::animationTile, X
		ELSE
			; ::HACK the 'final' tile of the animation must be included in
			; :: The animationCounter. ::
			LDA	f:PipeBlockBankOffset + PipeBlockAnimation::pipeBlockPtr, X
			TAX
			LDA	f:PipeBlockBankOffset + PipeBlock::tilePos, X
		ENDIF
		TAX

		LDA	animationCellPos
		AND	#$FFE0
		ASL
		STA	tmp1

		LDA	animationCellPos
		AND	#$1E
		ADD	tmp1
		ASL
		TAY

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

		SEP	#$20
.A8
		STZ	updateBufferOnZero
	ENDIF

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

	CPX	animationCellPos
	BEQ	DrawAnimation


	TXA
	AND	#$FFE0
	ASL
	STA	tmp1

	TXA
	AND	#$1E
	ADD	tmp1
	ASL

	TAY

	LDA	grid, X
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


;; Draws the cursor pipe
; DB = $7E
.A8
.I16
ROUTINE DrawCursorPipe
	REP	#$30
.A16
	LDA	cursorXpos
	AND	#$00FF
	ASL
	ASL
	ASL
	ASL
	ADD	#PIPE_PLAYFIELD_XPOS
	STA	MetaSprite__xPos

	LDA	cursorYpos
	AND	#$00FF
	ASL
	ASL
	ASL
	ASL
	ADD	#PIPE_PLAYFIELD_YPOS
	STA	MetaSprite__yPos

	SEP	#$20
.A8

	LDA	cursorValidIfZero
	IF_ZERO
		LDX	#.loword(PipeMetaSprite_Cursor)
	ELSE
		LDX	#.loword(PipeMetaSprite_InvalidCursor)
	ENDIF

	LDY	#0
	JSR	MetaSprite__ProcessMetaSprite_Y


	REP	#$20
.A16

	LDX	cursorPipe
	LDA	f:PipeBlockBankOffset + PipeBlock::metaSpritePtr, X
	TAX

	SEP	#$20
.A8


	LDY	#0
	JSR	MetaSprite__ProcessMetaSprite_Y

	RTS


;; Draws the next pipe list
; DB = $7E
.A8
.I16
ROUTINE DrawNextList
	REP	#$30
.A16

	LDA	noOfNextToShow
	AND	#$000F
	IF_NOT_ZERO
		ASL
		STA	tmp1

		LDA	#PIPE_NEXTLIST_XPOS
		STA	MetaSprite__xPos

		LDA	#PIPE_NEXTLIST_YPOS + PIPE_MAX_NEXT * (16 + PIPE_NEXTLIST_SPACING)
		STA	MetaSprite__yPos


		LDX	#0

		REPEAT
			PHX

			LDA	MetaSprite__yPos
			SUB	#16 + PIPE_NEXTLIST_SPACING
			STA	MetaSprite__yPos

			LDA	nextList, X
			TAX

			LDA	f:PipeBlockBankOffset + PipeBlock::metaSpritePtr, X
			TAX

			SEP	#$20
.A8
			LDY	#0
			JSR	MetaSprite__ProcessMetaSprite_Y

			REP	#$20
.A16

			PLX

			INX
			INX
			CPX	tmp1
		UNTIL_GE
	ENDIF

	SEP	#$20
.A8

	RTS



;; Push a random pipe onto the next array.
; DB = $7E
.A8
.I16
ROUTINE GenerateNextPipe
	REP	#$30
.A16
	LDA	nextList
	STA	cursorPipe

	LDX	#0
	REPEAT
		LDA	nextList + 2, X
		STA	nextList, X
		INX
		INX
		CPX	#.sizeof(nextList) - 2
	UNTIL_GE

	SEP	#$20
.A8
	PEA	$7E80
	PLB

	LDY	#N_BLOCKS * 2
	JSR	Random__Rnd_U16Y

	PLB

	REP	#$30
.A16

	TYA
	AND	#$00FE
	TAX
	LDA	f:PipeBlocks, X

	STA	nextList + .sizeof(nextList) - 2

	SEP	#$20
.A8
	RTS



.define METASPRITE_BANK "BANK1"
.define PIPEDATA_BANK "BANK1"

	.include "resources/pipes/pipes.inc"


.segment METASPRITE_BANK
	MetaSpriteLayoutBank = .bankbyte(*)

ENDMODULE

