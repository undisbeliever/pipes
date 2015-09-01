
.PHONY: all
all: pipes.4bpp pipes.clr pipes.map background.4bpp background.clr background.map pipe-sprites.4bpp pipe-sprites.clr


pipes.4bpp pipes.clr pipes.map: pipes.pcx
	pcx2snes -screen -s8 -c16 pipes
	mv pipes.pic pipes.4bpp

background.4bpp background.clr background.map: background.pcx
	pcx2snes -screen -r -s8 -c16 -o112 background
	mv background.pic background.4bpp

pipe-sprites.4bpp pipe-sprites.clr: pipe-sprites.pcx
	pcx2snes -n -s16 -c16 pipe-sprites
	mv pipe-sprites.pic pipe-sprites.4bpp

.PHONY: clean
clean:
	$(RM) pipes.4bpp pipes.clr pipes.map background.4bpp background.clr background.map pipe-sprites.4bpp pipe-sprites.clr

