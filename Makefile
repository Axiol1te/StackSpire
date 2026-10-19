SHELL := /bin/bash

.PHONY: help

help:
	@echo 'flutter pub get'
	@echo 'dart setup.dart android --arch arm64'
	@echo 'dart setup.dart windows | macos | linux'
	@echo 'Core sources are included; see BUILDING.md.'
