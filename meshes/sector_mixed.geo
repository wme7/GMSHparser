// ============================================================
// 2D mixed mesh: 90-degree circular sector
//
// Domain: annular sector, r in [0.1, 1.0], theta in [0, 90 deg]
//
// Split at the 45-degree bisector into two 45-degree sub-sectors:
//
//   Lower sub-sector  theta in [ 0, 45 deg]: transfinite TRIANGLES
//   Upper sub-sector  theta in [45, 90 deg]: transfinite QUADS
//
// Geometry layout (labelled by angle):
//
//        90deg
//         P4 ---arc_outer_upper--- P3(45deg)
//         |                        |
//       rad_left              bisector
//         |                        |
//         P5 ---arc_inner_upper--- P6
//
//         P6 ---arc_inner_lower--- P7(0deg inner)
//         |                        |
//       bisector              rad_right
//         |                        |
//         P3 ---arc_outer_lower--- P8(0deg outer)
//
// Shared edge: bisector from P6 (r=0.1, 45deg) to P3 (r=1.0, 45deg)
// ============================================================

// -----------------------------------------------------------
// Mesh resolution parameters
// -----------------------------------------------------------
Nr     = 20;   // divisions in the radial direction   (r: 0.1 -> 1.0)
Ntheta = 10;   // divisions per sub-sector arc        (theta: 45 deg each)
               // total angular divisions = 2 * Ntheta across 90 deg

r_in   = 0.1;  // inner radius
r_out  = 1.0;  // outer radius

// -----------------------------------------------------------
// Points
//
// Angles: 0 deg, 45 deg, 90 deg
// Each angle has one inner point (r = r_in) and one outer point (r = r_out)
// Center point for arc definitions
// -----------------------------------------------------------

// Origin (used only as arc centre — not part of any surface)
Point(1) = {0.0, 0.0, 0};

// 0-degree radial boundary (right edge)
Point(2) = {r_in,  0.0,    0};   // inner, 0 deg
Point(3) = {r_out, 0.0,    0};   // outer, 0 deg

// 45-degree bisector
Point(4) = {r_in  * Cos(Pi/4), r_in  * Sin(Pi/4), 0};   // inner, 45 deg
Point(5) = {r_out * Cos(Pi/4), r_out * Sin(Pi/4), 0};   // outer, 45 deg

// 90-degree radial boundary (top edge)
Point(6) = {0.0,   r_in,  0};   // inner, 90 deg
Point(7) = {0.0,   r_out, 0};   // outer, 90 deg

// -----------------------------------------------------------
// Lines and Arcs
//
// Radial lines: straight, connect inner to outer at fixed angle
// Arcs: follow the inner or outer circle between two angles
// Convention: CCW orientation throughout
// -----------------------------------------------------------

// Radial lines
Line(1) = {2, 3};   // right boundary  (theta = 0 deg,  r: in -> out)
Line(2) = {4, 5};   // bisector        (theta = 45 deg, r: in -> out)
Line(3) = {6, 7};   // top  boundary   (theta = 90 deg, r: in -> out)

// Inner arcs (r = r_in), CCW
Circle(4) = {2, 1, 4};   // inner arc, lower sub-sector (0  -> 45 deg)
Circle(5) = {4, 1, 6};   // inner arc, upper sub-sector (45 -> 90 deg)

// Outer arcs (r = r_out), CCW
Circle(6) = {3, 1, 5};   // outer arc, lower sub-sector (0  -> 45 deg)
Circle(7) = {5, 1, 7};   // outer arc, upper sub-sector (45 -> 90 deg)

// -----------------------------------------------------------
// Curve Loops and Surfaces
//
// Lower sub-sector (triangles): bounded by right radial, lower outer arc,
//   reversed bisector, reversed lower inner arc
// Upper sub-sector (quads):     bounded by bisector, upper outer arc,
//   reversed top radial, reversed upper inner arc
// -----------------------------------------------------------

// Lower sub-sector (theta in [0, 45 deg]) -> TRIANGLES
Curve Loop(1)    = {1, 6, -2, -4};
Plane Surface(1) = {1};

// Upper sub-sector (theta in [45, 90 deg]) -> QUADS
Curve Loop(2)    = {2, 7, -3, -5};
Plane Surface(2) = {2};

// -----------------------------------------------------------
// Transfinite curves
//
// Nr+1     nodes along all radial lines and the bisector
// Ntheta+1 nodes along each 45-degree arc segment
//
// The bisector Line(2) is shared: its node count must satisfy
// both sub-sectors and is set once here.
// -----------------------------------------------------------

// Radial directions (r: r_in -> r_out)
Transfinite Curve{1} = Nr + 1;   // right boundary
Transfinite Curve{2} = Nr + 1;   // bisector (shared)
Transfinite Curve{3} = Nr + 1;   // top boundary

// Angular directions (theta, 45 deg each)
Transfinite Curve{4} = Ntheta + 1;   // inner arc, lower
Transfinite Curve{5} = Ntheta + 1;   // inner arc, upper
Transfinite Curve{6} = Ntheta + 1;   // outer arc, lower
Transfinite Curve{7} = Ntheta + 1;   // outer arc, upper

// -----------------------------------------------------------
// Transfinite surfaces
//
// Corner points listed in CCW order matching the curve loop.
// Lower (tri): Alternate diagonal for isotropic triangle pattern.
// Upper (quad): Recombine converts structured tris into quads.
// -----------------------------------------------------------

// Lower sub-sector: structured triangles
Transfinite Surface{1} = {2, 3, 5, 4} Alternate;

// Upper sub-sector: structured quads
Transfinite Surface{2} = {4, 5, 7, 6};
Recombine Surface{2};

// -----------------------------------------------------------
// Physical groups
// -----------------------------------------------------------

// Boundary edges
Physical Curve("inner_arc",    1) = {4, 5};   // full inner arc (r = r_in)
Physical Curve("outer_arc",    2) = {6, 7};   // full outer arc (r = r_out)
Physical Curve("right_radial", 3) = {1};       // theta = 0 deg
Physical Curve("top_radial",   4) = {3};       // theta = 90 deg

// Surface domains
Physical Surface("triangles", 10) = {1};   // lower sub-sector
Physical Surface("quads",     20) = {2};   // upper sub-sector

// -----------------------------------------------------------
// Global mesh options
// -----------------------------------------------------------
Mesh.Algorithm = 6;   // Frontal-Delaunay (applied outside transfinite regions)
