TARGET := iphone:clang:14.5:14.0
INSTALL_TARGET_PROCESSES = TrollNonce

ARCHS = arm64

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = TrollNonce

TrollNonce_FILES = main.m TNAppDelegate.m TNRootViewController.m TSUtil.m
TrollNonce_FRAMEWORKS = UIKit CoreGraphics
TrollNonce_PRIVATE_FRAMEWORKS = Preferences
TrollNonce_CFLAGS = -fobjc-arc
TrollNonce_CODESIGN_FLAGS = -Sentitlements.plist

include $(THEOS_MAKE_PATH)/application.mk
SUBPROJECTS += noncehelper
include $(THEOS_MAKE_PATH)/aggregate.mk
