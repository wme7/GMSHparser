// ============================================================
//  Gmsh geometry: structured quad mesh on [0,1] x [0,1]
//  Uses Transfinite Lines + Transfinite Surface + Recombine
// ============================================================

// --- Parameters -------------------------------------------
N = 10;          // number of elements along each edge
lc = 1.0 / N;   // characteristic length (cosmetic, not used by transfinite)

// --- Points (corners of the square) ----------------------
Point(1) = {0, 0, 0, lc};
Point(2) = {1, 0, 0, lc};
Point(3) = {1, 1, 0, lc};
Point(4) = {0, 1, 0, lc};

// --- Lines (edges of the square) -------------------------
Line(1) = {1, 2};   // bottom
Line(2) = {2, 3};   // right
Line(3) = {3, 4};   // top  (reversed orientation)
Line(4) = {4, 1};   // left (reversed orientation)

// --- Closed curve loop and surface -----------------------
Curve Loop(1) = {1, 2, 3, 4};
Plane Surface(1) = {1};

// --- Transfinite Lines ------------------------------------
//  Syntax: Transfinite Curve {id} = N+1  Using Progression 1;
//  N+1 points => N elements along the edge.
//  "Progression 1" gives a uniform distribution.
//  Replace with "Progression r" (r > 1) for geometric growth toward end,
//  or "Bump r" (r < 1) for refinement at both ends.

Transfinite Curve {1} = N + 1 Using Progression 1;
Transfinite Curve {2} = N + 1 Using Progression 1;
Transfinite Curve {3} = N + 1 Using Progression 1;
Transfinite Curve {4} = N + 1 Using Progression 1;

// --- Transfinite Surface ----------------------------------
//  List the four corner points in order (consistent with curve orientations).
Transfinite Surface {1} = {1, 2, 3, 4};

// --- Recombine: turn triangles into quads -----------------
//  Without this, Gmsh produces triangles even with Transfinite.
Recombine Surface {1};

// --- Mesh algorithm (optional but explicit) ---------------
//  Algorithm 8 = Frontal-Delaunay for quads — not needed for transfinite,
//  but keeps intent clear when mixing with other surfaces.
// Mesh.Algorithm = 8;

// --- Physical groups (needed for most solvers) -----------
Physical Curve("bottom", 10) = {1};
Physical Curve("right",  11) = {2};
Physical Curve("top",    12) = {3};
Physical Curve("left",   13) = {4};
Physical Surface("domain", 20) = {1};
