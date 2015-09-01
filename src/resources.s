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
	.faraddr	PipeGame_PipeSprites_Palette
	.byte		16
	.faraddr	PipeGame_Background_Palette
	.byte		16 * 7


VramTable:
	.faraddr	PipeGame_Pipes_Tiles
	.faraddr	PipeGame_PipeSprites_Tiles
	.faraddr	PipeGame_Background_Tiles
	.faraddr	PipeGame_Background_TileMap


PipeGame_Pipes_Tiles:
	.byte	VramDataFormat::UNCOMPRESSED
	.word	PipeGame_Pipes_Tiles_End - PipeGame_Pipes_Tiles - 3
	.incbin	"resources/pipes/pipes.4bpp"
PipeGame_Pipes_Tiles_End:


PipeGame_Pipes_Palette:
	.incbin	"resources/pipes/pipes.clr"



PipeGame_PipeSprites_Tiles:
	.byte	VramDataFormat::UNCOMPRESSED
	.word	PipeGame_PipeSprites_Tiles_End - PipeGame_PipeSprites_Tiles - 3
	.incbin	"resources/pipes/pipe-sprites.4bpp"
PipeGame_PipeSprites_Tiles_End:


PipeGame_PipeSprites_Palette:
	.incbin	"resources/pipes/pipe-sprites.clr"



PipeGame_Background_Tiles:
	.byte	VramDataFormat::UNCOMPRESSED
	.word	PipeGame_Background_Tiles_End - PipeGame_Background_Tiles - 3
	.incbin	"resources/pipes/background.4bpp"
PipeGame_Background_Tiles_End:


PipeGame_Background_TileMap:
	.byte	VramDataFormat::UNCOMPRESSED
	.word	PipeGame_Background_TileMap_End - PipeGame_Background_TileMap - 3
	.incbin	"resources/pipes/background.map"
PipeGame_Background_TileMap_End:


PipeGame_Background_Palette:
	.incbin	"resources/pipes/background.clr"

