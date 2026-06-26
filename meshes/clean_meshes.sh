#! /bin/bash

# Remove generated mesh files from the meshes directory.
for file in ./meshes/*.msh; do
    [ -e "$file" ] || continue
    rm "$file"
done

for file in ./meshes/*.npz; do
    [ -e "$file" ] || continue
    rm "$file"
done
