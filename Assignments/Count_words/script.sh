#!/bin/bash

# === Set your directory path ===
DIR_PATH="/d/DAWS_84s/Assignments/Count_words"

# === Get the name of this script ===
SCRIPT_NAME=$(basename "$0")

# === Define color and style codes ===
RED="\033[31m"
GREEN="\033[32m"
BLUE="\033[94m"
YELLOW="\033[33m"
CYAN="\033[36m"
BOLD="\033[1m"
RESET="\033[0m"

# === Check if directory exists ===
if [ ! -d "$DIR_PATH" ]; then
    echo -e "${RED}Directory not found: $DIR_PATH${RESET}"
    exit 1
fi

# === File selection loop ===
while true; do
    echo
    echo -e "${GREEN}Files in directory:${RESET}"

    # Load files excluding folders and the script file itself
    mapfile -t FILES < <(ls -p "$DIR_PATH" | grep -v / | grep -v "^$SCRIPT_NAME$")

    if [ ${#FILES[@]} -eq 0 ]; then
        echo -e "${RED}No valid files found in the directory.${RESET}"
        exit 1
    fi

    for i in "${!FILES[@]}"; do
        printf "${BLUE}%2d) %s${RESET}\n" "$((i + 1))" "${FILES[$i]}"
    done

    echo
    read -p "$(echo -e "${YELLOW}Enter the number of the file to analyze (or type 'exit' to quit): ${RESET}")" CHOICE

    if [[ "$CHOICE" == "exit" ]]; then
        echo -e "${YELLOW}Exiting script...${RESET}"
        echo -e "${GREEN}${BOLD}Thank you for Testing this Script!${RESET}"
        exit 0
    fi

    if [[ "$CHOICE" =~ ^[0-9]+$ ]] && (( CHOICE >= 1 && CHOICE <= ${#FILES[@]} )); then
        FILENAME="${FILES[$((CHOICE - 1))]}"
        FILE_PATH="$DIR_PATH/$FILENAME"

        echo
        echo -e "${CYAN}${BOLD}Top 5 Most Frequent Words in '${FILENAME}':${RESET}"
        echo

        tr -c '[:alnum:]' '[\n*]' < "$FILE_PATH" | \
        tr '[:upper:]' '[:lower:]' | \
        grep -v '^$' | \
        sort | uniq -c | sort -nr | head -n 5 | \
        awk -v BOLD="$BOLD" -v RESET="$RESET" '{ printf("%s%-10s %s%s\n", BOLD, $1, $2, RESET) }'

        echo
        echo -e "${GREEN}${BOLD}Analysis complete. Thank you for Testing this Script!${RESET}"
        break
    else
        echo -e "${RED}Invalid choice. Please enter a valid number from the list.${RESET}"
    fi
done
