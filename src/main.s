; Initialisation code

.include "includes/import_export.inc"
.include "includes/registers.inc"
.include "includes/structure.inc"
.include "includes/config.inc"
.include "routines/random.h"
.include "routines/screen.h"
.include "routines/metasprite.h"

.include "pipegame.h"


;; Initialisation Routine
ROUTINE Main
	REP	#$10
	SEP	#$20
.A8
.I16

	; ::TODO Setup Sound Engine::

	LDA	#NMITIMEN_VBLANK_FLAG | NMITIMEN_AUTOJOY_FLAG
	STA	NMITIMEN

	LDXY	#$d3ac47		; source: random.org
	STXY	Random__Seed

	;; ::DEBUG Needed for compiling::
	MetaSprite_Init

	JSR	PipeGame__Init

	LDA	#15
	STA	INIDISP

	LDA	#$7E
	PHA
	PLB

	REPEAT
		JSR	PipeTiles__NewGame

		REPEAT
			JSR	Screen__WaitFrame

			JSR	PipeTiles__Update
		UNTIL_C_CLEAR
	FOREVER


;; ::DEBUG::
MetaSpriteLayoutBank = .bankbyte(*)


.segment "COPYRIGHT"
		;1234567890123456789012345678901
	.byte	"Pipes                          ", 10
	.byte	"(c) 2015, The Undisbeliever    ", 10
	.byte	"MIT Licensed                   ", 10
	.byte	"One Game Per Month Challange   ", 10

