#! /bin/bash

# Remove generated reference files from the reference directory.
for file in ./tests/reference/*.mat; do
    [ -e "$file" ] || continue
    rm "$file"
done