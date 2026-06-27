// ============================================================
// Extruded mixed mesh on [0,1]^2 x [0,0.2]
//
// Left half  x in [0, 0.5]: transfinite triangles -> PRISMS
// Right half x in [0.5,1]:  transfinite quads     -> HEXAHEDRA
//
// Key requirements for a clean mixed extrusion:
//   1. Both base surfaces must be Transfinite — unstructured
//      base triangulations produce pyramids/tets, not prisms.
//   2. The shared interface Line(2) carries a single node count
//      (Ny+1) enforced before either surface is declared
//      transfinite, guaranteeing conforming nodes at the interface
//      in both 2D and 3D.
//   3. Recombine is applied ONLY to Surface(2) so the right half
//      extrudes into hexahedra while the left half stays as prisms.
//   4. Each Extrude block uses the same Layers{Nz} count so z-layers
//      are aligned across the interface.
// ============================================================

// -----------------------------------------------------------
// Mesh resolution parameters
// -----------------------------------------------------------
lc  = 0.05;   // characteristic length (used for point sizing only)
Nx  = 10;     // divisions in x for the quad half  (x: 0.5 -> 1.0)
Ny  = 20;     // divisions in y for both halves    (y: 0.0 -> 1.0)
Nxt = 10;     // divisions in x for the tri half   (x: 0.0 -> 0.5)
              // set Nxt = Nx for a symmetric element size
Nz  = 4;      // layers in the extrusion direction (z: 0.0 -> 0.2)
dz  = 0.2;    // extrusion depth

// -----------------------------------------------------------
// Points (base plane z = 0)
// -----------------------------------------------------------

// Left half corners
Point(1) = {0.0, 0.0, 0, lc};   // bottom-left
Point(2) = {0.5, 0.0, 0, lc};   // bottom-middle  (interface)
Point(3) = {0.5, 1.0, 0, lc};   // top-middle     (interface)
Point(4) = {0.0, 1.0, 0, lc};   // top-left

// Right half corners (Points 2 and 3 are shared with the left half)
Point(5) = {1.0, 0.0, 0, lc};   // bottom-right
Point(6) = {1.0, 1.0, 0, lc};   // top-right

// -----------------------------------------------------------
// Lines
// -----------------------------------------------------------

// Left (triangular) region
Line(1) = {1, 2};   // bottom edge of left half
Line(2) = {2, 3};   // shared interface (y-direction, CCW for left surface)
Line(3) = {3, 4};   // top edge of left half
Line(4) = {4, 1};   // left boundary

// Right (quadrilateral) region
Line(5) = {2, 5};   // bottom edge of right half
Line(6) = {5, 6};   // right boundary
Line(7) = {6, 3};   // top edge of right half
// Line(2) reused as -2 (reversed) in the right curve loop

// -----------------------------------------------------------
// Curve Loops and Surfaces
// -----------------------------------------------------------

Curve Loop(1) = {1, 2, 3, 4};    // left  surface
Plane Surface(1) = {1};

Curve Loop(2) = {5, 6, 7, -2};   // right surface (-2: interface reversed)
Plane Surface(2) = {2};

// -----------------------------------------------------------
// Transfinite curves
//
// Both surfaces share Line(2) for the interface — its node
// count must be set once and be consistent with Ny used on
// Lines 4, 6 (the outer y-edges of each half).
// -----------------------------------------------------------

// Shared interface and outer y-edges  (y-direction)
Transfinite Curve{2} = Ny + 1;   // interface
Transfinite Curve{4} = Ny + 1;   // left boundary
Transfinite Curve{6} = Ny + 1;   // right boundary

// x-edges of the triangular (left) half
Transfinite Curve{1} = Nxt + 1;  // bottom of left half
Transfinite Curve{3} = Nxt + 1;  // top    of left half

// x-edges of the quadrilateral (right) half
Transfinite Curve{5} = Nx + 1;   // bottom of right half
Transfinite Curve{7} = Nx + 1;   // top    of right half

// -----------------------------------------------------------
// Transfinite surfaces
//
// Corners must be listed in CCW order matching the curve loop.
// "Alternate" diagonal gives a more isotropic triangle pattern
// on the left half and is recommended for FEM.
// -----------------------------------------------------------

// Left half: structured triangles (no Recombine -> prisms after extrusion)
//Transfinite Surface{1} = {1, 2, 3, 4} Alternate;

// Right half: structured quads (Recombine -> hexahedra after extrusion)
Transfinite Surface{2} = {2, 5, 6, 3};
Recombine Surface{2};   // recombine face -> quadrilaterals

// -----------------------------------------------------------
// Extrusion
//
// Each surface is extruded separately with identical Layers{Nz}
// so z-planes are aligned across the interface.
//
// Surface(1): triangles + no Recombine  -> prism  (wedge) elements
// Surface(2): quads    + Recombine      -> hexahedral elements
//
// The Recombine inside the Extrude block recombines the lateral
// quad faces of the extruded quads into hex faces.
// -----------------------------------------------------------

// --- Left half extrusion -> PRISMS ---
ext_tri[] = Extrude {0, 0, dz} {
    Surface{1};
    Layers{Nz};
    Recombine;   // recombine here -> prism elements
};

// --- Right half extrusion -> HEXAHEDRA ---
ext_quad[] = Extrude {0, 0, dz} {
    Surface{2};
    Layers{Nz};
    Recombine;   // recombine lateral faces -> hexahedra
};

// -----------------------------------------------------------
// Extrude return value layout for a quad-bounded surface:
//
//   ext[0]  : top surface (z = dz)
//   ext[1]  : volume
//   ext[2]  : lateral face from Line(1) / Line(5)  -> bottom-y face
//   ext[3]  : lateral face from Line(2) / Line(6)  -> interface / right face
//   ext[4]  : lateral face from Line(3) / Line(7)  -> top-y face
//   ext[5]  : lateral face from Line(4)            -> left face
//             (only for the 4-line left surface)
// -----------------------------------------------------------

// -----------------------------------------------------------
// Physical groups
// -----------------------------------------------------------

// --- Volumes ---
Physical Volume("prisms",    1) = {ext_tri[1]};
Physical Volume("hexahedra", 2) = {ext_quad[1]};

// --- Bottom faces (z = 0) ---
Physical Surface("bottom_z_tri",  10) = {1};
Physical Surface("bottom_z_quad", 11) = {2};

// --- Top faces (z = dz) ---
Physical Surface("top_z_tri",  12) = {ext_tri[0]};
Physical Surface("top_z_quad", 13) = {ext_quad[0]};

// --- Lateral boundary faces (tri half) ---
Physical Surface("bottom_y_tri", 20) = {ext_tri[2]};   // y = 0, left half
Physical Surface("top_y_tri",    21) = {ext_tri[4]};   // y = 1, left half
Physical Surface("left_x",       22) = {ext_tri[5]};   // x = 0

// --- Lateral boundary faces (quad half) ---
Physical Surface("bottom_y_quad", 30) = {ext_quad[2]};  // y = 0, right half
Physical Surface("right_x",       31) = {ext_quad[3]};  // x = 1
Physical Surface("top_y_quad",    32) = {ext_quad[4]};  // y = 1, right half

// --- Internal interface (x = 0.5) ---
// The interface is a lateral face of both extrusions; expose it
// if needed for post-processing or flux computation.
Physical Surface("interface_tri",  40) = {ext_tri[3]};
Physical Surface("interface_quad", 41) = {ext_quad[5]};

// -----------------------------------------------------------
// Global mesh options
// -----------------------------------------------------------
Mesh.Algorithm  = 6;   // Frontal-Delaunay for the base 2D mesh
Mesh.Algorithm3D = 4;  // Frontal for 3D (consistent with structured extrusion)

Mesh.SecondOrderLinear = 0;
Coherence;
