SDKROOT := $(shell xcrun --show-sdk-path)
CC := $(shell xcrun -f clang)
ARCHS := -arch arm64 -arch arm64e
TARGET := build/libDockReflections.dylib

.PHONY: all clean sign install restart deploy

all: $(TARGET)

$(TARGET): DockReflections.m
	@mkdir -p build
	$(CC) -dynamiclib -fobjc-arc -fmodules -O2 $(ARCHS) -isysroot $(SDKROOT) \
		-framework Foundation -framework AppKit -framework QuartzCore -framework CoreImage \
		-install_name @rpath/libDockReflections.dylib -o $@ $<

clean:
	rm -rf build

sign: $(TARGET)
	codesign --force --sign - $(TARGET)

install: sign
	cp $(TARGET) /var/ammonia/core/tweaks/libDockReflections.dylib
	cp libDockReflections.dylib.whitelist /var/ammonia/core/tweaks/libDockReflections.dylib.whitelist

restart:
	killall Dock

deploy: install restart
