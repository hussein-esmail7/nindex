#include <stdio.h>

void print_reset() {
	printf("\033[0m");
}

void print_black() {
	printf("\033[1;30m");
}

void print_blue() {
	printf("\033[1;34m");
}

void print_cyan() {
	printf("\033[1;36m");
}

void print_green() {
	printf("\033[1;32m");
}

void print_purple() {
	printf("\033[1;35m");
}

void print_red() {
	printf("\033[1;31m");
}

void print_white() {
	printf("\033[1;37m");
}

void print_yellow() {
	printf("\033[1;33m");
}
