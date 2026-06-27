// ============================================================
// Extruded triangular prism mesh on [0,1]x[0,1]x[0,0.2]
//
// Base: transfinite mesh on [0,1]x[0,1] (z=0)
// Extrusion: z-direction over [0, 0.2] with Nz uniform layers
// Result: triangular prism (wedge) elements
// ============================================================

// -----------------------------------------------------------
// Mesh resolution parameters
// -----------------------------------------------------------
lc = 0.05;   // characteristic element size in the base (xy-plane)
Nz = 4;      // number of layers in the extrusion direction (z)
dz = 0.2;    // extrusion depth

// -----------------------------------------------------------
// Base surface points (z = 0)
// -----------------------------------------------------------
Point(1) = {0.0, 0.0, 0, lc};   // bottom-left
Point(2) = {1.0, 0.0, 0, lc};   // bottom-right
Point(3) = {1.0, 1.0, 0, lc};   // top-right
Point(4) = {0.0, 1.0, 0, lc};   // top-left

// -----------------------------------------------------------
// Lines
// -----------------------------------------------------------
Line(1) = {1, 2};   // bottom
Line(2) = {2, 3};   // right
Line(3) = {3, 4};   // top
Line(4) = {4, 1};   // left

// -----------------------------------------------------------
// Base surface
// -----------------------------------------------------------
Curve Loop(1) = {1, 2, 3, 4};
Plane Surface(1) = {1};

// -----------------------------------------------------------
// Transfinite constraints on the base surface
//
// These are essential to obtain prism/wedge elements after
// extrusion. Without them, Gmsh extrudes an unstructured
// triangulation and produces degenerate pyramid/tet elements
// instead of clean wedges.
//
// N = number of nodes along each edge => N-1 divisions.
// All four edges must be consistently assigned.
// -----------------------------------------------------------
Nxy = Round(1.0 / lc) + 1;   // nodes along x and y edges

Transfinite Curve{1} = Nxy;   // bottom  (x-direction)
Transfinite Curve{3} = Nxy;   // top     (x-direction)
Transfinite Curve{2} = Nxy;   // right   (y-direction)
Transfinite Curve{4} = Nxy;   // left    (y-direction)

// Structured triangulation of the base using the "Left" diagonal
// convention. Alternating (Right/Alternate) diagonals can be used
// instead but Left gives a symmetric wedge pattern.
Transfinite Surface{1} = {1, 2, 3, 4};   // corners in CCW order
Recombine Surface {1};

// -----------------------------------------------------------
// Mesh options for the base surface
// -----------------------------------------------------------
Mesh.Algorithm = 6;   // Frontal-Delaunay (applied outside transfinite regions)

// -----------------------------------------------------------
// Extrusion
//
// Extrude { direction vector } { entity list }
// Layers{Nz} enforces Nz uniform layers in z.
// No Recombine => prism (wedge) elements.
// Adding Recombine => hexahedral elements instead.
// -----------------------------------------------------------
ext[] = Extrude {0, 0, dz} {
    Surface{1};
    Layers{Nz};
    Recombine;   // uncomment for hex elements
};

// -----------------------------------------------------------
// Extracting surface tags from the extrusion result
//
// The Extrude operator returns a list ext[] with the layout:
//   ext[0]  : tag of the new top surface
//   ext[1]  : tag of the new volume
//   ext[2]  : tag of the extruded lateral surface from Line(1) -> bottom face
//   ext[3]  : tag of the extruded lateral surface from Line(2) -> right face
//   ext[4]  : tag of the extruded lateral surface from Line(3) -> top face
//   ext[5]  : tag of the extruded lateral surface from Line(4) -> left face
// -----------------------------------------------------------

// -----------------------------------------------------------
// Physical groups
// -----------------------------------------------------------

// Volume
Physical Volume("domain", 1) = {ext[1]};

// Bottom and top faces (z = 0 and z = dz)
Physical Surface("bottom_z", 2) = {1};        // base surface (z = 0)
Physical Surface("top_z",    3) = {ext[0]};   // extruded top (z = dz)

// Lateral faces
Physical Surface("bottom_y", 4) = {ext[2]};   // y = 0 face
Physical Surface("right_x",  5) = {ext[3]};   // x = 1 face
Physical Surface("top_y",    6) = {ext[4]};   // y = 1 face
Physical Surface("left_x",   7) = {ext[5]};   // x = 0 face
