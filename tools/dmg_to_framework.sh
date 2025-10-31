#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
FRAMEWORK_DEST_DIR="$HOME/Library/Frameworks"
TEMP_DIR=$(mktemp -d)

# --- Functions ---

# Function to clean up the temporary directory on exit
cleanup() {
  echo "Cleaning up..."
  # Remove the temporary directory
  if [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
  fi
  echo "Cleanup complete."
}

# Set the trap to call cleanup() on script exit (EXIT), interrupt (INT), or terminate (TERM)
trap cleanup EXIT INT TERM

# Function to print usage
usage() {
  echo "Usage: $0 <url_to_dmg>"
  echo "Example: $0 https://github.com/libsdl-org/SDL/releases/download/release-2.32.10/SDL2-2.32.10.dmg"
  exit 1
}

# --- Script Start ---

# Check for correct number of arguments
if [ "$#" -ne 1 ]; then
  echo "Error: Invalid number of arguments."
  usage
fi

# Check for 7zz
if ! command -v 7zz &> /dev/null; then
  echo "Error: 7zz (7zip) is not installed. This script requires it for extraction."
  echo "You can install it with Homebrew: brew install 7zip"
  exit 1
fi

DMG_URL="$1"
DMG_NAME=$(basename "$DMG_URL")
DMG_PATH="$TEMP_DIR/$DMG_NAME"

# 1. Ensure destination directory exists
echo "Ensuring framework directory exists at $FRAMEWORK_DEST_DIR"
mkdir -p "$FRAMEWORK_DEST_DIR"

# 2. Download the DMG
echo "Downloading $DMG_URL to $DMG_PATH..."
curl -L "$DMG_URL" -o "$DMG_PATH"

# 3. Extract the DMG
echo "Extracting $DMG_PATH to $TEMP_DIR..."
EXTRACT_DIR="$TEMP_DIR/extracted"
mkdir -p "$EXTRACT_DIR"

# Extract the DMG using 7z.
# We redirect stdout/stderr to /dev/null for a clean run,
# but re-run with output if it fails, for debugging.
if ! 7zz x "$DMG_PATH" -o"$EXTRACT_DIR" &> /dev/null; then
  echo "Error: 7z failed to extract $DMG_PATH"
  echo "Running again with output for debugging:"
  7zz x "$DMG_PATH" -o"$EXTRACT_DIR"
  exit 1
fi

echo "DMG extracted to $EXTRACT_DIR"

# 4. Find and copy all .framework files
# We find all items ending in .framework and copy them.
# -maxdepth 3 is a reasonable precaution against searching too deep.

# Count frameworks first
FRAMEWORK_COUNT=$(find "$EXTRACT_DIR" -maxdepth 3 -name "*.framework" -type d | wc -l)

if [ "$FRAMEWORK_COUNT" -gt 0 ]; then
  echo "Found $FRAMEWORK_COUNT framework(s)"
  
  # Loop through each framework and copy it
  # Using -print0 and read -d '' to handle spaces in filenames safely
  while IFS= read -r -d '' FRAMEWORK_PATH; do
    FRAMEWORK_NAME=$(basename "$FRAMEWORK_PATH")
    echo "Copying $FRAMEWORK_NAME to $FRAMEWORK_DEST_DIR..."
    
    # Use rsync for a reliable copy. -a preserves permissions, symlinks, etc.
    rsync -a "$FRAMEWORK_PATH" "$FRAMEWORK_DEST_DIR/"
    
    echo "Successfully copied $FRAMEWORK_NAME to $FRAMEWORK_DEST_DIR"
  done < <(find "$EXTRACT_DIR" -maxdepth 3 -name "*.framework" -type d -print0)
else
  echo "Error: Could not find any .framework files in the extracted DMG."
  find "$EXTRACT_DIR" -maxdepth 3 # List contents for debugging
  exit 1
fi

# 5. Cleanup is handled by the 'trap' automatically
# The script will exit, and the trap remove the temp dir.

exit 0
