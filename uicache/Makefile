TARGETNAME = uicache
OUTDIR ?= bin

CC = xcrun -sdk iphoneos clang -arch arm64
LDID = ../amfidebilitate/ldid

.PHONY: all clean

all: $(OUTDIR)/$(TARGETNAME)

CFLAGS =

DEBUG ?= 1
ifneq (($DEBUG), 1)
	CFLAGS += -O3
endif

$(OUTDIR):
	mkdir -p $(OUTDIR)

$(OUTDIR)/$(TARGETNAME): uicache.m | $(OUTDIR)
	$(CC) -o $@ $^ $(CFLAGS) -fobjc-arc -framework Foundation -framework MobileCoreServices
	strip $@
	$(LDID) -K../amfidebilitate/signcert.p12 -Sent.plist $@

clean:
	rm -f $(OUTDIR)/$(TARGETNAME)

