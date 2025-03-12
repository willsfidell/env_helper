#!/bin/bash

# Copyright (c) 2025
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Function to print usage information
print_usage() {
    echo "Usage:"
    echo "  Compare mode: $0 -c file1.env file2.env"
    echo "  Format mode:  $0 -f file.env"
    exit 1
}

# Function to read env file and return both variables and their comments
read_env_file() {
    local file=$1
    local -n vars=$2  # nameref to the variables array
    
    # Initialize a temporary associative array for comments
    declare -A local_comments
    
    local current_comments=""
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Handle comments
        if [[ "$line" =~ ^[[:space:]]*# ]]; then
            current_comments+="${line}"$'\n'
            continue
        fi
        
        # Skip empty lines
        if [[ -z "$line" ]]; then
            current_comments=""
            continue
        fi
        
        # Extract key and value
        if [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
            key="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"
            # Trim whitespace
            key="${key%%[[:space:]]}"
            key="${key##[[:space:]]}"
            vars["$key"]="$value"
            # Store associated comments if any
            if [[ -n "$current_comments" ]]; then
                local_comments["$key"]="${current_comments%$'\n'}"  # Remove trailing newline
                current_comments=""
            fi
        fi
    done < "$file"
    
    # Return the comments array
    declare -g -A COMMENTS_ARRAY
    for key in "${!local_comments[@]}"; do
        COMMENTS_ARRAY["$key"]="${local_comments[$key]}"
    done
}

# Function to compare two env files
compare_env_files() {
    local file1=$1
    local file2=$2
    
    # Declare associative arrays for both files
    declare -A env1
    declare -A env2
    
    # Read both files
    read_env_file "$file1" env1
    declare -A comments1=()
    for key in "${!COMMENTS_ARRAY[@]}"; do
        comments1["$key"]="${COMMENTS_ARRAY[$key]}"
    done
    
    read_env_file "$file2" env2
    declare -A comments2=()
    for key in "${!COMMENTS_ARRAY[@]}"; do
        comments2["$key"]="${COMMENTS_ARRAY[$key]}"
    done
    
    echo "=== Keys unique to $file1 ==="
    for key in "${!env1[@]}"; do
        if [[ ! -v "env2[$key]" ]]; then
            echo "$key"
        fi
    done
    
    echo -e "\n=== Keys unique to $file2 ==="
    for key in "${!env2[@]}"; do
        if [[ ! -v "env1[$key]" ]]; then
            echo "$key"
        fi
    done
    
    echo -e "\n=== Keys with different values ==="
    for key in "${!env1[@]}"; do
        if [[ -v "env2[$key]" && "${env1[$key]}" != "${env2[$key]}" ]]; then
            echo "$key:"
            echo "  $file1: ${env1[$key]}"
            echo "  $file2: ${env2[$key]}"
        fi
    done
}

# Function to get prefix from key
get_prefix() {
    local key=$1
    if [[ "$key" =~ ^([^_]+) ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo "$key"
    fi
}

# Function to format env file
format_env_file() {
    local file=$1
    declare -A env
    
    # Read the file
    read_env_file "$file" env
    declare -A comments=()
    for key in "${!COMMENTS_ARRAY[@]}"; do
        comments["$key"]="${COMMENTS_ARRAY[$key]}"
    done
    
    # Get all keys and sort them
    readarray -t sorted_keys < <(printf '%s\n' "${!env[@]}" | sort)
    
    # Track the current prefix
    local current_prefix=""
    
    # Print formatted output
    for key in "${sorted_keys[@]}"; do
        prefix=$(get_prefix "$key")
        
        # Add blank line between different prefixes
        if [[ "$prefix" != "$current_prefix" && -n "$current_prefix" ]]; then
            echo ""
        fi
        
        # Print associated comments if they exist
        if [[ -v "comments[$key]" ]]; then
            echo -n "${comments[$key]}"$'\n'
        fi
        
        echo "$key=${env[$key]}"
        current_prefix=$prefix
    done
}

# Main script

# Check if we have enough arguments
if [[ $# -lt 2 ]]; then
    print_usage
fi

# Process arguments
case "$1" in
    -c)
        if [[ $# -ne 3 ]]; then
            echo "Error: Compare mode requires exactly two files"
            print_usage
        fi
        
        if [[ ! -f "$2" ]]; then
            echo "Error: File '$2' does not exist"
            exit 1
        fi
        
        if [[ ! -f "$3" ]]; then
            echo "Error: File '$3' does not exist"
            exit 1
        fi
        
        compare_env_files "$2" "$3"
        ;;
        
    -f)
        if [[ $# -ne 2 ]]; then
            echo "Error: Format mode requires exactly one file"
            print_usage
        fi
        
        if [[ ! -f "$2" ]]; then
            echo "Error: File '$2' does not exist"
            exit 1
        fi
        
        format_env_file "$2"
        ;;
        
    *)
        print_usage
        ;;
esac