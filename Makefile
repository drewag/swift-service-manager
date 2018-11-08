UNAME_S := $(shell uname -s)
FLAGS :=

all: service

prod: FLAGS += --configuration release
prod: service

project:
	swift package generate-xcodeproj

clean:
	swift package clean

install: prod
	cp .build/release/ssm /usr/local/bin/

service: Sources/*.swift Package.swift
	swift build $(FLAGS)
