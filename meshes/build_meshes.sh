#! /bin/bash

# Build 2D meshes for all the geometries in the meshes directory
for file in ./meshes/square*.geo; do
    gmsh -2 -format msh2 -o ${file%.geo}_v2.msh $file
    gmsh -2 -format msh41 -o ${file%.geo}_v4.msh $file
done

# Build 3D meshes for all the geometries in the meshes directory
for file in ./meshes/extruded*.geo; do
    gmsh -3 -format msh2 -o ${file%.geo}_v2.msh $file
    gmsh -3 -format msh41 -o ${file%.geo}_v4.msh $file
done

# Build 2D meshes with two partitions
for file in ./meshes/rectangle.geo; do
    gmsh -2 -format msh2 -part 2 -o ${file%.geo}_v2.msh $file
    gmsh -2 -format msh41 -part 2 -o ${file%.geo}_v4.msh $file
done

# Build 3D meshes with two partitions
for file in ./meshes/box.geo; do
    gmsh -3 -format msh2 -part 2 -o ${file%.geo}_v2.msh $file
    gmsh -3 -format msh41 -part 2 -o ${file%.geo}_v4.msh $file
done