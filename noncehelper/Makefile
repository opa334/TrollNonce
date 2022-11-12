TARGET := iphone:clang:14.5:14.0


ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TOOL_NAME = noncehelper

noncehelper_FILES = main.m nonce-uc.m $(wildcard ./exploit/multicast_bytecopy/*.c ./exploit/weightBufs/*.m ./exploit/weightBufs/*.c) ./dimentio/libdimentio.c KernelManager.m
noncehelper_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
noncehelper_CODESIGN_FLAGS = -Sentitlements.plist
noncehelper_INSTALL_PATH = /Applications/TrollNonce.app
noncehelper_FRAMEWORKS = Foundation AppleNeuralEngine CoreML IOSurface
noncehelper_PRIVATE_FRAMEWORKS = IOKit
noncehelper_LIBRARIES = MobileGestalt

include $(THEOS_MAKE_PATH)/tool.mk
