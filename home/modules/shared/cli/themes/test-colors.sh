#!/usr/bin/env bash

# Print a colored block with its color code
print_color() {
    local color_num=$1
    local color_hex=$2
    printf "\033[48;5;%dm  Color %d (%s)  \033[0m\n" "$color_num" "$color_num" "$color_hex"
}

# Regular Colors (0-7)
echo "Regular Colors:"
print_color 0 "282a36" # Black
print_color 1 "ff5555" # Red
print_color 2 "50fa7b" # Green
print_color 3 "f1fa8c" # Yellow
print_color 4 "bd93f9" # Blue
print_color 5 "ff79c6" # Magenta
print_color 6 "8be9fd" # Cyan
print_color 7 "f8f8f2" # White

echo -e "\nBright Colors (8-15):"
print_color 8 "44475a"  # Bright Black
print_color 9 "ff5555"  # Bright Red
print_color 10 "50fa7b" # Bright Green
print_color 11 "f1fa8c" # Bright Yellow
print_color 12 "bd93f9" # Bright Blue
print_color 13 "ff79c6" # Bright Magenta
print_color 14 "8be9fd" # Bright Cyan
print_color 15 "ffffff" # Bright White

# Print some sample text with different colors
echo -e "\nSample Text:"
for i in {0..23}; do
    printf "\033[38;5;%dm▌ This is color %d\033[0m\n" "$i" "$i"
done
