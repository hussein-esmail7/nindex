#include <stdio.h>
#include <stdlib.h> // Adds atoi() which converts string to int
#include <string.h>
#include <ctype.h> // Adds isdigit() which is used inside isNumber() function
				   // Adds tolower() to make character lowercase

/*
thru.c
Hussein Esmail
Created: 2025 01 23
Updated: 2025 01 23
Terminal command to compile file to an executable:
    gcc -o thru thru.c && chmod +x thru && ./thru
*/

int comp(const void* a, const void* b) {
	// Custom comparator
    // If a is smaller, positive value will be returned
    return (*(int*)a - *(int*)b);
}

int removeDup(int arr[], int n) {
	// Removes duplicate numbers from a sorted array
	// This moves all duplicates to the end of the array (leaves 1 non-unique
	// value where it is, making it unique), and returns a new index where the
	// unique values end.
	if (n == 0) return 0;
	int j = 0;
	for (int i=1; i<n-1; i++) {
		// If a unique element is found, place it at arr[j + 1]
		if (arr[i] != arr[j]) arr[++j] = arr[i];
    }
    // Return the new ending of arr that only contains unique elements
    return j + 1;
}

int isNumber(const char number[]) {
	// Does not account for negative numbers
    for (int i=0; number[i] != 0; i++) if (!isdigit(number[i])) return 0;
    return 1;
}

int main(int argc, char **argv) {
	int debug_prints = 0;
	int numbers_size = 1000; // How big the numbers array will be
	int numbers[numbers_size]; // Array where final values are stored
	int numbers_count = 1; // Next free index of the numbers to return
	for (int i=0; i<numbers_size; i++) numbers[i] = 0; // Set default
	char * accepted_operators [] = {"+", "-", "thru"};
	int len = sizeof(accepted_operators)/sizeof(accepted_operators[0]);
	int operator = 0;	// Which math operator given. See list below
	/* operator:
	 * 0: null / none given yet
	 * 1: +
	 * 2: -
	 * 3: thru
	 */
	int operatorargnum = 0; // Index the last operator was given
	// Why track argument numbers? There's no scenario where this program
	// should expect two numbers in a row or two operators in a row. Ex:
	// 1. '1 2 3'
	// 2. '1 + - 3'
	// 3. '1 THRU - 4'
	// All these examples do not make sense
    for (int i = 1; i < argc; i++) { // For every argument given
    	// argv[0] = './thru', therefore index 0 must be ignored
        // if (debug_prints) printf("argv[%d]: %s\n", i, argv[i]); // Print argument
		if (debug_prints) printf("---------- %s ----------\n", argv[i]);
		if (isNumber(argv[i])) {
			if (debug_prints) printf("\tDetected: number\n");
			// if it is a number
			if (i!=1 && isNumber(argv[i-1])) {
				// If there are 2 numbers in a row, error
				printf("[ERROR] Cannot have 2 numbers in a row!: '%s %s'\n", argv[i-1], argv[i]);
				return -1;
			}
    		if (i == 1) { // If this is the first argument
				if (debug_prints) printf("\tFirst index, storing number\n");
				// Store value
				numbers[numbers_count] = atoi(argv[i]); // Add number to array
				numbers_count++; // Increase array counter
				if (debug_prints) printf("[FOUND NUM] %i\n", atoi(argv[i]));
			} else { // Not first index
				if (debug_prints) printf("\tNot first index, checking if operator before\n");
				// If it is not the first index, it doesn't mean we can
				// automatically store the number. It could be a scenario where
				// it's '1 thru 5 - 3'. We could be in the '- 3' part
    			if (operatorargnum == i-1) {
    				// If there was an argument given
    				// Flowchart: N12-P163
    				switch (operator) {
						case 1: // +
							numbers[numbers_count] = atoi(argv[i]); // Add number to array
							numbers_count++; // Increase array counter
							break;
						case 2: // -
							// Remove number from list, every instance
							for (int j=0; j<numbers_count; j++) {
								// numbers_count instead of number_size because
								// numbers_cound<j<number_size are all 0.
								if (numbers[j] == atoi(argv[i])) numbers[j] = 0;
							}
							break;
						case 3: // thru
							if (debug_prints) printf("numbers[numbers_count-1]: %i\n", numbers[numbers_count-1]);
							int thru_1 = numbers[numbers_count-1];
							int thru_2 = atoi(argv[i]);
							if (debug_prints) printf("thru_1: %i\n", thru_1);
							if (debug_prints) printf("thru_2: %i\n", thru_2);
							if (thru_2 < thru_1) {
								// Swap numbers if 1st number larger than 2nd
								// Swap numbers without using a third variable
								thru_1 = thru_1 + thru_2;
								thru_2 = thru_1 - thru_2;
								thru_1 = thru_1 - thru_2;
							}
							for (int j=thru_1; j<=thru_2; j++) {
								// Add each number to array, thru_2 inclusive
								numbers[numbers_count] = j;
								numbers_count++;
							}
							break;
						default:
							printf("[ERROR]: Unknown error while storing operator\n");
							return -1;
							break;
					}
				}
			}
		} else {
			// Check if it is a valid operator
			char * check = argv[i];
			for(int j = 0; check[j]; j++){
				// Makes lowercase
				check[j] = tolower(check[j]);
			}
			int last_operatorargnum = operatorargnum; // Used to check after loop
			for (int j=0; j < len; ++j) {
				if (!strcmp(accepted_operators[j], check)) {
    			    // If string is in array, therefore a valid operator
    			    // Store operator
    			    operator = j+1; // index (starts at 0) to operator list (starts at 1)
    			    operatorargnum = i; // Set arg num
    			    if (debug_prints) printf("[OPERATOR] %s\n", check);
    			}
			}
			if (last_operatorargnum == operatorargnum) {
				// If operator argument number did not change, therefore not in list
				printf("[ERROR] Unknown argument: '%s'.\n", argv[i]);
			}
		}
		if (debug_prints) printf("End of for loop, iteration i=%i\n", i);
    }

	// Sort numbers and remove duplicates
	qsort(numbers, numbers_count, sizeof(int), comp);
	// if (debug_prints) printf("numbers[0]: %i\n", numbers[0]);

	// Remove duplicates
	int check_dup =1;
	for (int i=0; i<numbers_count; i++) {
		if (numbers[i] == check_dup) {
			numbers[i] = 0;
		} else {
			check_dup = numbers[i];
		}
	}

	// Print numbers
	for (int i=0; i<numbers_count; i++) {
		if (numbers[i] != 0) {
			printf("%i", numbers[i]);
			if (i != numbers_count-1) printf(" ");
		}
	}
	printf("\n");
    return 0;
}
