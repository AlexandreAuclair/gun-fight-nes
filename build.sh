#!/bin/bash

ca65 src/main.asm -o out/main.o
ld65 out/main.o -t nes -o out/gunFight.nes
