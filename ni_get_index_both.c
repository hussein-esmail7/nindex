#include <dirent.h>
#include <limits.h>
#include <stdio.h>
#include <string.h> // Used for strings, checking equalness, copying strings, etc.
#include <sys/stat.h>
#include <stdlib.h> // Used for free() when reading the index file and clearing the allocated memory for it


/*
ni_get_index.c
Hussein Esmail
Created: 2023 11 26
Updated: 2025 01 26
Terminal command to compile file to an executable:
    gcc -o ni_get_index ni_get_index.c && chmod +x ni_get_index && ./ni_get_index
Description: This file searches the notebook directory for all files that start
    with "N", then greps the index file for the title and returns an unsorted
    list of all the pages with their titles.
*/

int comp(const void* a, const void* b) {
	// Quicksort comparator (qsort())
    return (*(int*)a - *(int*)b);
}

void checkIndexFile(char* nPage, char* indexPath) {
    char    *line = NULL;
    size_t  len = 0;
    ssize_t read;	// Line iterator
    FILE    *fp = fopen(indexPath, "r"); // Attempt to read index file

	// If the file could not be opened
    if (!fp) fprintf(stderr, "Failed to open %s\n", indexPath);

    while ((read = getline(&line, &len, fp)) != -1) {
        if (strstr(line, nPage) != NULL) {
            // printf("%s - %s\n", nPage, line);
            char * separator = "]";
            char * b = strtok(line, separator); // Get substring before ']' (aka '  \item[N11-121'). This line required for char* c to work
            char * c = strtok(NULL, ""); // Get substring after ']' (aka title of page)
            if (c[0] == ' ')  // Trim whitespace of title if first character is a space
                memmove(c, c+1, strlen(c));
            printf("%s - %s", nPage, c);
            break;
         }
    }
    fclose(fp); // Close the file after done reading
    if (line) free(line); // Free the allocated memory
}

void list_files(char* path, char *argv[]) {
	/*
	 * This function changes directories to the given notebook folder, and gets
	 * all files that start with the letter 'N' (to avoid things like
	 * 'cover.jpg', etc.)
	 */
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
                    checkIndexFile(nPage, argv[2]);
                    printf("%s\n", full_path);
                }
			}
        }
        closedir(d);
    }
}


int num_dirs(const char* path) {
	// This function returns the number of sub-directories that exist in the
	// input path
    int dir_count = 0;
    struct dirent* dent;
    DIR* srcdir = opendir(path);
	if (srcdir == NULL) {
        perror("opendir");
        return -1;
    }
    while((dent = readdir(srcdir)) != NULL) {
        struct stat st;
        if(strcmp(dent->d_name, ".") == 0 || strcmp(dent->d_name, "..") == 0)
            continue;
        if (fstatat(dirfd(srcdir), dent->d_name, &st, 0) < 0) {
            perror(dent->d_name);
            continue;
        }
        if (S_ISDIR(st.st_mode)) dir_count++;
    }
    closedir(srcdir);
    return dir_count;
}

int main(int argc, char *argv[]) {
	// char path[1000]="/Users/hussein/Documents/Notebooks";
	// Input (argv[1]): File path of Notebook folders ("/Users/hussein/Documents/Notebooks")
    // Input (argv[2]): File path of index file ("/Users/hussein/Documents/Notebooks/N-Indexes.tex")
	if (argc < 1) return -1; // If there is an argument (assumed file path)

    struct dirent *direntp = NULL;
    DIR *dirp = NULL;
    size_t path_len;

    /* Check input parameters. */
    path_len = argc;
    if (!argv[1] || !path_len || (path_len > _POSIX_PATH_MAX)) {
        printf("ERROR: No input given. Path to notebook folder required as 1st argument.\n");
        return -1;
    }
    if (!argv[2] || !path_len || (path_len > _POSIX_PATH_MAX)) {
        printf("ERROR: No input given. Path to index file required as 2nd argument.\n");
        return -1;
    }

    /* Open directory */
    dirp = opendir(argv[1]);
    if (dirp == NULL) return -1;

    int dir_count = 0;
    while ((direntp = readdir(dirp)) != NULL) {
        /* For every directory entry... */
        struct stat fstat;
        char full_name[_POSIX_PATH_MAX + 1];

        /* Calculate full name, check we are in file length limts */
        if ((path_len + strlen(direntp->d_name) + 1) > _POSIX_PATH_MAX)
            continue;

        strcpy(full_name, argv[1]);
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
            list_files(full_name, argv);
        }
    }
    /* Cleanup */
    (void)closedir(dirp);

	// Sort output
	// qsort(numbers, numbers_count, sizeof(int), comp);

	return 0;
}
