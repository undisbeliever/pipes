
.PHONY: all
all: pipes.4bpp pipes.clr pipes.map


pipes.4bpp pipes.clr pipes.map: pipes.pcx
	pcx2snes -s8 -c16 -screen pipes
	mv pipes.pic pipes.4bpp


.PHONY: clean
clean:
	$(RM) pipes.4bpp pipes.clr pipes.map

