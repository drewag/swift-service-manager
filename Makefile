UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
	FLAGS := -Xcc -I/usr/include/postgresql -Xcc -I/usr/include/libxml2
else
    FLAGS := -Xcc -I/usr/local/include -Xlinker -L/usr/local/lib/ -Xcc -I/usr/local/include/libxml2
endif

all: service

prod: FLAGS += --configuration release
prod: service

project:
	swift package generate-xcodeproj -Xcc -I/usr/local/include -Xlinker -L/usr/local/lib/ -Xswiftc -I/usr/local/include

clean:
	swift build --clean

service: Sources/*.swift Package.swift
	swift build $(FLAGS)
