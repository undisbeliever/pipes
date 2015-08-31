
.ifndef ::__RESOURCES_H_
::__RESOURCES_H_ = 1

.setcpu "65816"
.include "includes/import_export.inc"
.include "includes/registers.inc"
.include "includes/config.inc"


.enum RESOURCES_VRAM
	PIPEGAME__PIPE_TILES
	PIPEGAME__PIPE_SPRITES
.endenum

.enum RESOURCES_PALETTES
	PIPEGAME__PIPE_TILES
	PIPEGAME__PIPE_SPRITES
.endenum

.endif ; __RESOURCES_H_

; vim: ft=asm:

