TARGET := iphone:clang:14.5:7.0


ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TOOL_NAME = noncehelper

noncehelper_FILES = main.m nonce-uc.m $(wildcard ./exploit/*.c) ./dimentio/libdimentio.c KernelManager.m
noncehelper_CFLAGS = -fobjc-arc
noncehelper_CODESIGN_FLAGS = -Sentitlements.plist
noncehelper_INSTALL_PATH = /Applications/TrollNonce.app
noncehelper_PRIVATE_FRAMEWORKS = IOKit

include $(THEOS_MAKE_PATH)/tool.mk
