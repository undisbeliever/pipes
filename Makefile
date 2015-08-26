
ROM_NAME      = Pipes
CONFIG        = LOROM_1MBit_copyright
API_MODULES   = reset-snes sfc-header block screen controller text text8x8 math random metasprite resourceloader
API_DIR       = snesdev-common
SOURCE_DIR    = src
TABLES_DIR    = tables
RESOURCES_DIR = resources

include $(API_DIR)/Makefile.in

