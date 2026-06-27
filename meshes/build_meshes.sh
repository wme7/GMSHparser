#! /bin/bash

# Build 2D meshes for all the geometries in the meshes directory
for file in ./meshes/square_*.geo; do
    gmsh -2 -format msh2 -o ${file%.geo}_v2.msh $file
    gmsh -2 -format msh41 -o ${file%.geo}_v4.msh $file
done

# Build 3D meshes for all the geometries in the meshes directory
for file in ./meshes/square_extruded_*.geo; do
    gmsh -3 -format msh2 -o ${file%.geo}_v2.msh $file
    gmsh -3 -format msh41 -o ${file%.geo}_v4.msh $file
done

# Build 2D meshes with two partitions
for file in ./meshes/simple_rectangle.geo; do
    gmsh -2 -format msh2 -part 2 -save_all -o ${file%.geo}_v2.msh $file
    gmsh -2 -format msh41 -part 2 -save_all -o ${file%.geo}_v4.msh $file
done

# Build 3D meshes with two partitions
for file in ./meshes/simple_box.geo; do
    gmsh -3 -format msh2 -part 2 -save_all-o ${file%.geo}_v2.msh $file
    gmsh -3 -format msh41 -part 2 -save_all -o ${file%.geo}_v4.msh $file
done

# Build 2D meshes with 1st-, 2nd- and 3rd-order curved elements
for file in ./meshes/sector_*.geo; do
    gmsh $file -2 -order 1 -format msh2 -o ${file%.geo}_p1_v2.msh
    gmsh $file -2 -order 1 -format msh41 -o ${file%.geo}_p1_v4.msh
    gmsh $file -2 -order 2 -format msh2 -o ${file%.geo}_p2_v2.msh
    gmsh $file -2 -order 2 -format msh41 -o ${file%.geo}_p2_v4.msh
    gmsh $file -2 -order 3 -format msh2 -o ${file%.geo}_p3_v2.msh
    gmsh $file -2 -order 3 -format msh41 -o ${file%.geo}_p3_v4.msh
done

# Build 3D meshes with 1st-, 2nd- and 3rd-order curved elements
for file in ./meshes/sector_extruded_*.geo; do
    gmsh $file -3 -order 1 -format msh2 -o ${file%.geo}_p1_v2.msh
    gmsh $file -3 -order 1 -format msh41 -o ${file%.geo}_p1_v4.msh
    gmsh $file -3 -order 2 -format msh2 -o ${file%.geo}_p2_v2.msh
    gmsh $file -3 -order 2 -format msh41 -o ${file%.geo}_p2_v4.msh
    gmsh $file -3 -order 3 -format msh2 -o ${file%.geo}_p3_v2.msh # Experimental
    gmsh $file -3 -order 3 -format msh41 -o ${file%.geo}_p3_v4.msh # Experimental
done

# NOTES: 
# - 3rd-order prism elements are not supported by Gmsh yet. 
#   It is a well-known limitation for years; see the 2015 Gmsh mailing-list: 
#   https://onelab.info/pipermail/gmsh/2015/009557.html
# - So the mesh is partially produced, but Gmsh is telling you it could not 
#   fully validate/process complete face closure for cubic prisms. 
#   Treat p3 prism meshes as experimental / potentially unreliable until 
#   you verify them in your solver or parser.
# - Use order 2 for 3D prism meshes — the most reliable path today.
# - Keep order 3 only for hex-dominated cases.