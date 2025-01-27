#include <ctype.h>	// Adds tolower() to make character lowercase
#include <dirent.h>
#include <limits.h>
#include "printcolors.c" // Created for shortcuts to printing different colors
#include <stdio.h>
#include <stdlib.h> // Adds atoi() which converts string to int
					// Used for free() when reading the index file and clearing the allocated memory for it
#include <string.h> // Used for strings, checking equalness, copying strings, etc.
#include <sys/stat.h>



/*
nindex.c
Hussein Esmail
Created: 2025 01 24
Updated: 2025 01 26
Terminal command to compile file to an executable:
    gcc -o nindex nindex.c && chmod +x nindex && ./nindex
*/

// Global variables
int pagesMax = 200; // A notebook has 200 pages at most
int notebookMax = 1000;
									 // X[0]: Most recent notebook

int isNumber(const char number[]) {
	// Does not account for negative numbers
    for (int i=0; number[i] != 0; i++) if (!isdigit(number[i])) return 0;
    return 1;
}

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



void thru(int pagesToOpen[][pagesMax], int currentNotebook, int indexpagestart, int indexpageend, char **passedArgs) {

	int debug_prints_thru = 0;
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
    for (int i = indexpagestart; i < indexpageend; i++) { // For every argument given
    	// passedArgs[0] = './thru', therefore index 0 must be ignored
        // if (debug_prints_thru) printf("passedArgs[%d]: %s\n", i, passedArgs[i]); // Print argument
		if (debug_prints_thru) printf("---------- %s ----------\n", passedArgs[i]);
		if (isNumber(passedArgs[i])) {
			if (debug_prints_thru) printf("\tDetected: number\n");
			// if it is a number
			if (isNumber(passedArgs[i-1])) {
				// If there are 2 numbers in a row, treat as addition
				if (debug_prints_thru) printf("\tConsecutive numbers, treating as +, storing number\n");
				// Store value
				numbers[numbers_count] = atoi(passedArgs[i]); // Add number to array
				numbers_count++; // Increase array counter
				if (debug_prints_thru) printf("[FOUND NUM] %i\n", atoi(passedArgs[i]));
			}
    		if (i == indexpagestart) { // If this is the first argument
				if (debug_prints_thru) printf("\tFirst index, storing number\n");
				// Store value
				numbers[numbers_count] = atoi(passedArgs[i]); // Add number to array
				numbers_count++; // Increase array counter
				if (debug_prints_thru) printf("[FOUND NUM] %i\n", atoi(passedArgs[i]));
			} else { // Not first index
				if (debug_prints_thru) printf("\tNot first index, checking if operator before\n");
				// If it is not the first index, it doesn't mean we can
				// automatically store the number. It could be a scenario where
				// it's '1 thru 5 - 3'. We could be in the '- 3' part
    			if (operatorargnum == i-1) {
    				// If there was an argument given
    				// Flowchart: N12-P163
    				switch (operator) {
						case 1: // +
							numbers[numbers_count] = atoi(passedArgs[i]); // Add number to array
							numbers_count++; // Increase array counter
							break;
						case 2: // -
							// Remove number from list, every instance
							for (int j=0; j<numbers_count; j++) {
								// numbers_count instead of number_size because
								// numbers_cound<j<number_size are all 0.
								if (numbers[j] == atoi(passedArgs[i])) numbers[j] = 0;
							}
							break;
						case 3: // thru
							if (debug_prints_thru) printf("numbers[numbers_count-1]: %i\n", numbers[numbers_count-1]);
							int thru_1 = numbers[numbers_count-1];
							int thru_2 = atoi(passedArgs[i]);
							if (debug_prints_thru) printf("thru_1: %i\n", thru_1);
							if (debug_prints_thru) printf("thru_2: %i\n", thru_2);
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
							printf("[");
							print_red();
							printf("ERROR");
							print_reset();
							printf("]: Unknown error while storing operator\n");
							break;
					}
				}
			}
		} else {
			// Check if it is a valid operator
			char * check = passedArgs[i];
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
    			    if (debug_prints_thru) printf("[OPERATOR] %s\n", check);
    			}
			}
			if (last_operatorargnum == operatorargnum) {
				// If operator argument number did not change, therefore not in list
				printf("[");
				print_red();
				printf("ERROR");
				print_reset();
				printf("] Unknown argument: '%s'.\n", passedArgs[i]);
			}
		}
		if (debug_prints_thru) printf("End of for loop, iteration i=%i\n", i);
    }

	// Sort numbers and remove duplicates
	qsort(numbers, numbers_count, sizeof(int), comp);
	// if (debug_prints_thru) printf("numbers[0]: %i\n", numbers[0]);

	// Remove duplicates
	int check_dup =1;
	for (int i=0; i<numbers_count; i++) {
		if (numbers[i] == check_dup) {
			numbers[i] = 0;
		} else {
			check_dup = numbers[i];
		}
	}

	// Setting the outputted pages to the array for use in the main function
	for (int i=0; i<numbers_count; i++) {
		if (numbers[i] != 0) pagesToOpen[currentNotebook][numbers[i]] = 1;
	}

} // thru() function definition end


void list_files(char* path, char* notebookFolder) {
	/*
	 * This function changes directories to the given notebook folder, and gets
	 * all files that start with the letter 'N' (to avoid things like
	 * 'cover.jpg', etc.)
	 */
	struct dirent *direntp = NULL;
    DIR *dirp = NULL;
    size_t path_len = sizeof(*notebookFolder)/sizeof(char);

    /* Check input parameters. */
    if (!notebookFolder || (path_len > _POSIX_PATH_MAX)) {
		printf("[");
		print_red();
		printf("ERROR");
		print_reset();
        printf("]: No input given. Path to notebook folder required as 1st argument.\n");
    }

    /* Open directory */
    dirp = opendir(notebookFolder);
    if (dirp == NULL) {
		printf("[");
		print_red();
		printf("ERROR");
		print_reset();
    	printf("]: Could not open directory.\n");
    } else {
		int dir_count = 0;
    	while ((direntp = readdir(dirp)) != NULL) {
    	    /* For every directory entry... */
    	    struct stat fstat;
    	    char full_name[_POSIX_PATH_MAX + 1];
    	    /* Calculate full name, check we are in file length limts */
    	    if ((path_len + strlen(direntp->d_name) + 1) > _POSIX_PATH_MAX)
    	        continue;
    	    strcpy(full_name, notebookFolder);
    	    if (full_name[path_len - 1] != '/')
    	        strcat(full_name, "/");
    	    strcat(full_name, direntp->d_name);
    	    /* Ignore special directories. */
    	    if ((strcmp(direntp->d_name, ".") == 0) ||
    	        (strcmp(direntp->d_name, "..") == 0))
    	        continue;
    	    /* Print only if it is really directory. */
    	    if (stat(full_name, &fstat) < 0) continue;
    	    if (S_ISDIR(fstat.st_mode)) {
    	        // printf("%s\n", full_name); // Print folder name
    	        dir_count++;
				DIR *d;					// Directory prointer
    			struct dirent *dir;
    			d = opendir(path);		// Opens directory
    			char full_path[1000]; // Full directory path of the notebook folder
    			if (d) {
    			    while ((dir = readdir(d)) != NULL) { // While there are files here
    			        if (dir->d_type==DT_REG) {
    			            full_path[0]='\0';
    			            strcat(full_path,path);
    			            strcat(full_path,"/");
    			            strcat(full_path,dir->d_name);
    			            if (dir->d_name[0] == 'N') {
    			                // Only print the file line if first character is 'N'
    			                // printf("%.8s\n",dir->d_name); // This line prints the first 8 chars of the file name
    			                // Only save first 8 characters of file name (ex. 'N11-P120' = 8 characters)
    			                char nPage[256];     // Destination string
    			                strncpy(nPage, dir->d_name, 8);
    			                nPage[8] = 0; // null terminate destination
    			                // printf("\tlist_files(): %s\n", nPage);
    			            }
						}
    			    }
    			    closedir(d);
    			}
    	    }
    	}
	}
    /* Cleanup */
    (void)closedir(dirp);



} // list_files() function definition end




int main(int argc, char **argv) {
	int pagesToOpen[notebookMax][pagesMax]; // X: Notebook, Y: Page
	int currentNotebook; // Notebook that is currently being called
	int indexpagestart = -1; // 1 if no notebook number given, 2 if yes
	int indexpageend = -1; // Given when arguments end or next n# given
	char nindexfile[] = "vim ~/Documents/Notebooks/N-Indexes.tex";

	int debug_prints_main = 0;
	if (debug_prints_main) {
		printf("------- argv -------\n");
		for (int i=0; i<argc; i++) printf("argv[%i]: %s\n", i, argv[i]);
		printf("--------------------\n\n\n");
	}

	for (int x=0; x<notebookMax; x++)
		for (int y=0; y<pagesMax; y++)
			pagesToOpen[x][y] = 0;

	for (int i=0; i<argc; i++) {
		// Checking for non-notebook number arguments
		if (!strcmp(argv[i], "-e")) {
			// open the N-Indexes.tex file here
			system(nindexfile);
			return 0;
		}
		if (!strcmp(argv[i], "-h")) {
			printf("usage: ./nindex, ni\n");
			printf("\n");
			printf("This program quickly opens a specific notebook page quickly\n");
			printf("Allows search by notebook number and page, or by index\n");
			printf("entry name.\n");
			printf("\n");
			printf("Requirements: fzf\n");
			printf("\n");
			printf("Arguments:\n");
			printf("-e: Edit index file in vim.\n");
			printf("\tCommand: %s\n", nindexfile);
			printf("-h: Prints this help message, then exit program.\n");
			printf("\n");
			printf("https://github.com/hussein-esmail7/nindex\n");
			return 0;
		}
	}

	for (int arg=1; arg<argc; arg++) {
		// printf("------- argv[%i]: %s -------\n", arg, argv[arg]);
		// For every argument
		// Determine if first argument is # or n#. Error if not (unusable)
		char test = tolower(argv[1][0]); // Convert 'N' to 'n'
		if (arg == 1 && isNumber(argv[arg])) {
			// If the first argument is a number
			// It could be just that page, or an entire 'thru' command
			indexpagestart = arg;
			currentNotebook = 0;
			if (debug_prints_main) printf("----- N00 ----- (Most Recent)\n");
		} else if (argv[arg][0] == 'n' || argv[arg][0] == 'N') {
			// Finish up processing for current notebook (if this isn't first)
			if (arg != 1) indexpageend = arg; // Set since next n# is given
			if (indexpagestart != -1 && indexpageend != -1 && indexpagestart != indexpageend) {
				// If arguments are ready to pass into 'thru'
				if (debug_prints_main) {
					printf("\t1 TODO: Run 'thru' on commands: ");
					for (int i=indexpagestart; i<indexpageend; i++) {
						printf("%s ", argv[i]);
					}
					printf("\n");
				}
				thru(pagesToOpen, currentNotebook, indexpagestart, indexpageend, argv);

			} else if (arg != 1 && indexpagestart == indexpageend) {
				// Warning to not put a notebook number without page numbers
				// indexpagesstart == indexpagesend when a notebook has no
				// provided pages
				printf("[");
				print_yellow();
				printf("WARNING");
				print_reset();
				printf("]: Did not detect any pages for Notebook %i.\n", currentNotebook);
			}
			// Prep processing for next notebook's args
			argv[arg][0] = 'n'; // Change input to lower 'n'
			sscanf(argv[arg], "n%d", &currentNotebook); // Converts format to variables
			if (debug_prints_main) printf("----- N%02d -----\n", currentNotebook);
			indexpagestart = arg+1;
		}
	}
	// Since we process the notebook before when the next notebook number
	// is given, we need that same code after the loop for the pages of the
	// last notebook given (because there's no next notebook number which
	// is when this would have been processed).
	indexpageend = argc;
	if (indexpagestart != indexpageend) {
		// In the scenario where indexpagestart and indexpageend are equal,
		// that means a notebook number was the last argument (no pages
		// specified)
		// If arguments are ready to pass into 'thru'
		if (indexpagestart == -1) {
			// In case the user uses a thru command (i.e. multiple
			// arguments) without giving any notebook number at all
			indexpagestart = 1;
			if (debug_prints_main) printf("----- N00 ----- (Most Recent)\n");
		}
		if (debug_prints_main) {
			printf("\t2 TODO: Run 'thru' on commands: ");
			for (int i=indexpagestart; i<indexpageend; i++) {
				printf("%s ", argv[i]);
			}
			printf("\n");
		}
		thru(pagesToOpen, currentNotebook, indexpagestart, indexpageend, argv);
	} else {
		// Warning to not put a notebook number without page numbers
		printf("[");
		print_yellow();
		printf("WARNING");
		print_reset();
		printf("]: Did not detect any pages for Notebook %i.\n", currentNotebook);
	}


	// At this point we have all the pages that need to be opened.
	// X=0 is treated as the most recent notebook, so we need to find out which
	// one that is if it is used:
	int bool_find_recent = 0;
	for (int y=0; y<pagesMax; y++) {
		if (pagesToOpen[1][y] == 1) {
			bool_find_recent = 1;
		}
	}


	list_files("/Users/hussein/Documents/Notebooks/", "/Users/hussein/Documents/Notebooks/");


	// Print pages that would be opened
	// printf("----- Final Pages -----\n");
	for (int x=0; x<notebookMax; x++) {
		for (int y=0; y<pagesMax; y++) {
			if (pagesToOpen[x][y] == 1) {
				printf("N%02d-P%03d\n", x, y);
			}
		}
	}






	return 0;
}
