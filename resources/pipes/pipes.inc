
; Details of the pipes
; --------------------

.macro _tile_ xPos, yPos
	.addr	(xPos + yPos * 32) * 4
.endmacro

.macro _animation_ xPos, yPos, exit, ptr
	.addr	ptr
	.addr	(xPos + yPos * 32) * 4
	.byte	PIPE_DIRECTION::exit
.endmacro

.macro _can_replace_pipe_
	.byte	$FF
.endmacro

.macro _no_replace_
	.byte	0
.endmacro

.macro _cannot_enter_
	.addr	0
	.addr	0
	.byte	0
.endmacro

.macro _filled_block_ xPos, yPos
	_tile_ xPos, yPos
	_no_replace_
	.addr	0

	_cannot_enter_
	_cannot_enter_
	_cannot_enter_
	_cannot_enter_
.endmacro

.macro _pipe_metasprite_ char
	.byte 1
		.word	0
		.word	char | (3 << OAM_CHARATTR_ORDER_SHIFT)
		.byte	$FF
.endmacro
	

.segment METASPRITE_BANK

; MetaSprites
; ===========
.proc PipeMetaSprite

Horizontal:
	_pipe_metasprite_ 0

Vertical:
	_pipe_metasprite_ 2

SE:
	_pipe_metasprite_ 4

SW:
	_pipe_metasprite_ 6

NE:
	_pipe_metasprite_ 8

NW:
	_pipe_metasprite_ 10

Cross:
	_pipe_metasprite_ 12


::PipeMetaSprite_Cursor:
Cursor:
	.byte	4
		.byte	0, 0
		.word	14 | (3 << OAM_CHARATTR_ORDER_SHIFT)
		.byte	0

		.byte	8, 0
		.word	14 | (3 << OAM_CHARATTR_ORDER_SHIFT) | OAM_CHARATTR_H_FLIP_FLAG
		.byte	0

		.byte	0, 8
		.word	14 | (3 << OAM_CHARATTR_ORDER_SHIFT) | OAM_CHARATTR_V_FLIP_FLAG
		.byte	0

		.byte	8, 8
		.word	14 | (3 << OAM_CHARATTR_ORDER_SHIFT) | OAM_CHARATTR_H_FLIP_FLAG | OAM_CHARATTR_V_FLIP_FLAG
		.byte	0

::PipeMetaSprite_InvalidCursor:
InvalidCursor:
	.byte	4
		.byte	0, 0
		.word	15 | (3 << OAM_CHARATTR_ORDER_SHIFT)
		.byte	0

		.byte	8, 0
		.word	15 | (3 << OAM_CHARATTR_ORDER_SHIFT) | OAM_CHARATTR_H_FLIP_FLAG
		.byte	0

		.byte	0, 8
		.word	15 | (3 << OAM_CHARATTR_ORDER_SHIFT) | OAM_CHARATTR_V_FLIP_FLAG
		.byte	0

		.byte	8, 8
		.word	15 | (3 << OAM_CHARATTR_ORDER_SHIFT) | OAM_CHARATTR_H_FLIP_FLAG | OAM_CHARATTR_V_FLIP_FLAG
		.byte	0
.endproc



.segment PIPEDATA_BANK

PipeTileMap:
	.incbin	"pipes.map"


PipeBlockBank = .bankbyte(*)

.proc StartingBlocks
	.addr	Up
	.addr	Right
	.addr	Down
	.addr	Left

::N_STARTING_BLOCKS = (* - ::StartingBlocks) / 2

Up:
	_tile_	0, 20
	_no_replace_
	.addr	0

	_animation_	0, 20, UP, Up_Filled
	_cannot_enter_
	_cannot_enter_
	_cannot_enter_

Up_Filled:
	_filled_block_	15, 20


Right:
	_tile_	0, 21
	_no_replace_
	.addr	0

	_cannot_enter_
	_cannot_enter_
	_cannot_enter_
	_animation_	0, 21, RIGHT, Right_Filled

Right_Filled:
	_filled_block_	15, 21


Down:
	_tile_	0, 22
	_no_replace_
	.addr	0

	_cannot_enter_
	_animation_	0, 22, DOWN, Down_Filled
	_cannot_enter_
	_cannot_enter_

Down_Filled:
	_filled_block_	15, 22


Left:
	_tile_	0, 23
	_no_replace_
	.addr	0

	_cannot_enter_
	_cannot_enter_
	_animation_	0, 23, LEFT, Left_Filled
	_cannot_enter_

Left_Filled:
	_filled_block_	15, 23

.endproc


.proc EndingBlocks
	.addr	EndDown
	.addr	EndLeft
	.addr	EndUp
	.addr	EndRight

::N_ENDING_BLOCKS = (* - ::EndingBlocks) / 2

EndDown:
	_tile_	0, 20
	_no_replace_
	.addr	0

	_cannot_enter_
	_animation_	0, 24, END, EndDown_Filled
	_cannot_enter_
	_cannot_enter_

EndDown_Filled:
	_filled_block_	15, 20


EndLeft:
	_tile_	0, 21
	_no_replace_
	.addr	0

	_cannot_enter_
	_cannot_enter_
	_animation_	0, 25, END, EndLeft_Filled
	_cannot_enter_

EndLeft_Filled:
	_filled_block_	15, 21


EndUp:
	_tile_	0, 22
	_no_replace_
	.addr	0

	_animation_	0, 26, END, EndUp_Filled
	_cannot_enter_
	_cannot_enter_
	_cannot_enter_

EndUp_Filled:
	_filled_block_	15, 22


EndRight:
	_tile_	0, 23
	_no_replace_
	.addr	0

	_cannot_enter_
	_cannot_enter_
	_cannot_enter_
	_animation_	0, 27, END, EndRight_Filled

EndRight_Filled:
	_filled_block_	15, 23

.endproc


.proc PipeBlocks
	.addr	Horizontal
	.addr	Vertical
	.addr	SE
	.addr	SW
	.addr	NE
	.addr	NW
	.addr	Cross

::N_BLOCKS = (* - ::PipeBlocks) / 2

::PipeBlock_Horizontal:
Horizontal:
	_tile_	0, 0
	_can_replace_pipe_
	.addr	PipeMetaSprite::Horizontal

	_cannot_enter_
	_cannot_enter_
	_animation_	1, 1, LEFT,	Horizontal_Filled
	_animation_	1, 0, RIGHT,	Horizontal_Filled


Horizontal_Filled:
	_filled_block_	0, 1


::PipeBlock_Vertical:
Vertical:
	_tile_	0, 2
	_can_replace_pipe_
	.addr	PipeMetaSprite::Vertical

	_animation_	1, 3, UP,	Vertical_Filled
	_animation_	1, 2, DOWN,	Vertical_Filled
	_cannot_enter_
	_cannot_enter_


Vertical_Filled:
	_filled_block_	0, 3


SE:
	_tile_	0, 4
	_can_replace_pipe_
	.addr	PipeMetaSprite::SE

	_animation_	1, 4, RIGHT,	SE_Filled
	_cannot_enter_
	_animation_	1, 5, DOWN,	SE_Filled
	_cannot_enter_


SE_Filled:
	_filled_block_	0, 5


SW:
	_tile_	0, 6
	_can_replace_pipe_
	.addr	PipeMetaSprite::SW

	_animation_	1, 7, LEFT,	SW_Filled
	_cannot_enter_
	_cannot_enter_
	_animation_	1, 6, DOWN,	SW_Filled


SW_Filled:
	_filled_block_	0, 7


NE:
	_tile_	0, 8
	_can_replace_pipe_
	.addr	PipeMetaSprite::NE

	_cannot_enter_
	_animation_	1, 8, RIGHT,	NE_Filled
	_animation_	1, 9, UP,	NE_Filled
	_cannot_enter_


NE_Filled:
	_filled_block_	0, 9


NW:
	_tile_	0, 10
	_can_replace_pipe_
	.addr	PipeMetaSprite::NW

	_cannot_enter_
	_animation_	1, 10, LEFT,	NW_Filled
	_cannot_enter_
	_animation_	1, 11, UP,	NW_Filled


NW_Filled:
	_filled_block_	0, 11


Cross:
	_tile_	0, 12
	_can_replace_pipe_
	.addr	PipeMetaSprite::Cross

	_animation_	1, 18, UP,	Cross_Vertical_Filled
	_animation_	1, 16, DOWN,	Cross_Vertical_Filled
	_animation_	1, 14, LEFT,	Cross_Horizontal_Filled
	_animation_	1, 12, RIGHT,	Cross_Horizontal_Filled


Cross_Vertical_Filled:
	_tile_	0, 13
	_no_replace_
	.addr	0

	_cannot_enter_
	_cannot_enter_
	_animation_	1, 15, LEFT,	Cross_Both_Filled
	_animation_	1, 13, RIGHT,	Cross_Both_Filled


Cross_Horizontal_Filled:
	_tile_	0, 17
	_no_replace_
	.addr	0

	_animation_	1, 19, UP,	Cross_Both_Filled
	_animation_	1, 17, DOWN,	Cross_Both_Filled
	_cannot_enter_
	_cannot_enter_


Cross_Both_Filled:
	_filled_block_	0, 19

.endproc

; vim: ft=asm:

