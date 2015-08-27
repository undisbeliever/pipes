; Loader of resources.

; :SHOULDDO automatically generate this with a program::

.include "includes/import_export.inc"
.include "includes/registers.inc"
.include "includes/structure.inc"

.include "routines/resourceloader.h"
.include "routines/metasprite.h"


.segment "BANK1"

PalettesTable:
	.faraddr	PipeGame_Pipes_Palette
	.byte		16


VramTable:
	.faraddr	PipeGame_Pipes_Tiles


PipeGame_Pipes_Tiles:
	.byte	VramDataFormat::UNCOMPRESSED
	.word	PipeGame_Pipes_Tiles_End - PipeGame_Pipes_Tiles - 3
	.incbin	"resources/pipes/pipes.4bpp"
PipeGame_Pipes_Tiles_End:


PipeGame_Pipes_Palette:
	.incbin	"resources/pipes/pipes.clr"


