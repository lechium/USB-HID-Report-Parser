SRC		:= daemon
BUILD		:= build
IOS_SDK         := iphoneos
IOS_SDK_PATH   	:= $(shell /usr/bin/xcrun --sdk $(IOS_SDK) --show-sdk-path)
TVOS_SDK	:= appletvos
TVOS_SDK_PATH	:= $(shell /usr/bin/xcrun --sdk $(TVOS_SDK) --show-sdk-path)
MACOS_SDK_PATH	:= $(shell /usr/bin/xcrun --sdk macosx --show-sdk-path)
TARGET		:= HIDParse 
FILES		:= $(wildcard *.mm) $(wildcard *.m) $(wildcard *.c) 
PWD		:= $(shell pwd)
IOS_CC          ?= xcrun -sdk iphoneos clang
INCLUDES	:= -I. 
LD_FLAGS_ALL	:= -lsystem -fmodules -Xclang -F. -L. -framework Foundation -fobjc-arc $(INCLUDES)
LD_FLAGS_MAC	:= $(LD_FLAGS_ALL)
LD_FLAGS_IOS	:= $(LD_FLAGS_ALL) 
C_FLAGS_MAC	:= -arch x86_64 -isysroot "$(MACOS_SDK_PATH)"
C_FLAGS_IOS	:= -arch arm64e -arch arm64 -isysroot "$(IOS_SDK_PATH)" -miphoneos-version-min=8.1 -O
C_FLAGS_TVOS	:= -arch arm64 -isysroot "$(TVOS_SDK_PATH)" -Ftvos -mappletvos-version-min=9.0 -O3

args = `arg="$(filter-out $@,$(MAKECMDGOALS))" && echo $${arg:-${1}}`
all: HIDParse.ios HIDParse.tvos HIDParse.x86_64
ios: all
tvos: all
mac: HIDParse.x86_64
.PHONY : all ios tvos clean mac

%:
	@:

HIDParse.ios: $(FILES)
	@echo "[i] Building $@..."
	@clang $(FILES) -o $@ $(C_FLAGS_IOS) $(LD_FLAGS_IOS)
	@strip $@

HIDParse.tvos: $(FILES)
	@echo "[i] Building $@..."
	@clang $(FILES) -o $@ $(C_FLAGS_TVOS) $(LD_FLAGS_IOS)
	@strip $@

HIDParse.x86_64: $(FILES)
	@echo "[i] Building $@..."
	@clang $(FILES) -o $@ $(C_FLAGS_MAC) $(LD_FLAGS_MAC)
	@strip $@

clean: 
	rm HIDParse* 
