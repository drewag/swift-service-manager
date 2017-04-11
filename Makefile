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
	swift package -Xcc -I/usr/local/include -Xlinker -L/usr/local/lib/ -Xswiftc -I/usr/local/include generate-xcodeproj

clean:
	swift build --clean

install: prod
	cp .build/release/ssm /usr/local/bin/

service: Sources/*.swift Package.swift
	swift build $(FLAGS)
