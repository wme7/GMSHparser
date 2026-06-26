// ============================================================
// Mixed Triangular / Quadrilateral mesh on [0,1]x[0,1]
//
// Left half  x in [0, 0.5]: unstructured triangular mesh
// Right half x in [0.5, 1]: transfinite quadrilateral mesh
// ============================================================

// -----------------------------------------------------------
// Mesh resolution parameters
// -----------------------------------------------------------
lc  = 0.1;    // characteristic length for the triangular region
Nx  = 10;     // number of divisions along x in the quad region (x: 0.5 -> 1)
Ny  = 10;     // number of divisions along y in the quad region (y: 0   -> 1)
// Note: for a uniform mesh in the tri region set lc ~ 0.5/Nx

// -----------------------------------------------------------
// Points
// Corner points of the full domain, plus the shared interface
// -----------------------------------------------------------

// Left half corners
Point(1) = {0.0, 0.0, 0, lc};   // bottom-left
Point(2) = {0.5, 0.0, 0, lc};   // bottom-middle (interface)
Point(3) = {0.5, 1.0, 0, lc};   // top-middle    (interface)
Point(4) = {0.0, 1.0, 0, lc};   // top-left

// Right half corners  (reuse points 2 and 3 on the interface)
Point(5) = {1.0, 0.0, 0, lc};   // bottom-right
Point(6) = {1.0, 1.0, 0, lc};   // top-right

// -----------------------------------------------------------
// Lines
// -----------------------------------------------------------

// --- Left (triangular) region ---
Line(1) = {1, 2};   // bottom edge of left half
Line(2) = {2, 3};   // shared interface (vertical)
Line(3) = {3, 4};   // top edge of left half
Line(4) = {4, 1};   // left boundary

// --- Right (quadrilateral) region ---
Line(5) = {2, 5};   // bottom edge of right half
Line(6) = {5, 6};   // right boundary
Line(7) = {6, 3};   // top edge of right half
// Line(2) is the shared interface, reused with reversed orientation

// -----------------------------------------------------------
// Curve Loops and Surfaces
// -----------------------------------------------------------

// Left surface (triangles)
Curve Loop(1) = {1, 2, 3, 4};
Plane Surface(1) = {1};

// Right surface (quads via transfinite)
Curve Loop(2) = {5, 6, 7, -2};   // -2 = Line(2) traversed in reverse
Plane Surface(2) = {2};

// -----------------------------------------------------------
// Transfinite settings for the right (quad) surface
// -----------------------------------------------------------

// Assign number of nodes on each bounding curve of Surface(2)
// Transfinite Curve: N means N+1 nodes => N elements along that edge

Transfinite Curve{5}  = Nx + 1;   // bottom (x-direction)
Transfinite Curve{7}  = Nx + 1;   // top    (x-direction)
Transfinite Curve{2}  = Ny + 1;   // interface (y-direction)
Transfinite Curve{6}  = Ny + 1;   // right boundary (y-direction)

// Make Surface(2) transfinite (structured)
Transfinite Surface{2};

// Recombine triangles into quads for Surface(2)
Recombine Surface{2};

// -----------------------------------------------------------
// Physical groups (for boundary conditions / export)
// -----------------------------------------------------------

// Boundary edges
Physical Curve("left",      10) = {4};
Physical Curve("bottom",    11) = {1, 5};
Physical Curve("right",     12) = {6};
Physical Curve("top",       13) = {3, 7};
Physical Curve("interface", 14) = {2};

// Surface domains
Physical Surface("triangles", 20) = {1};
Physical Surface("quads",     21) = {2};

// -----------------------------------------------------------
// Global mesh options
// -----------------------------------------------------------

// Use Delaunay for the unstructured region
Mesh.Algorithm = 5;          // Delaunay (robust for mixed meshes)

// Ensure conforming nodes on the shared interface
Mesh.SecondOrderLinear = 0;
Coherence;                   // merge duplicate points
