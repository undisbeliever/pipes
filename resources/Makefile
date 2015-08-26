
API_DIR = ../snesdev-common

.PHONY: all
all: pipes
	$(MAKE) -C . -f "$(realpath $(API_DIR)/makefiles/resources.makefile)"	


.PHONY: pipes
pipes:
	$(MAKE) -C pipes	


.PHONY: clean
clean:
	$(MAKE) -C . -f "$(realpath $(API_DIR)/makefiles/resources.makefile)" clean
	$(MAKE) -C pipes clean

