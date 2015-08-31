
.PHONY: all
all: pipes.4bpp pipes.clr pipes.map pipe-sprites.4bpp pipe-sprites.clr


pipes.4bpp pipes.clr pipes.map: pipes.pcx
	pcx2snes -s8 -c16 -screen pipes
	mv pipes.pic pipes.4bpp

pipe-sprites.4bpp pipe-sprites.clr: pipe-sprites.pcx
	pcx2snes -n -s16 -c16 pipe-sprites
	mv pipe-sprites.pic pipe-sprites.4bpp

.PHONY: clean
clean:
	$(RM) pipes.4bpp pipes.clr pipes.map pipe-sprites.clr pipe-sprites.map

