// ============================================================
// Extruded mixed mesh: 90-degree circular sector x [0, 0.2]
//
// Domain: annular sector, r in [0.1, 1.0], theta in [0, 90 deg]
//         extruded in z over [0, 0.2]
//
// Split at the 45-degree bisector into two 45-degree sub-sectors:
//
//   Lower sub-sector  theta in [ 0, 45 deg]: transfinite tris -> PRISMS
//   Upper sub-sector  theta in [45, 90 deg]: transfinite quads -> HEXAHEDRA
//
// Geometry layout (labelled by angle):
//
//        90deg
//         P7 ---arc_outer_upper--- P5(45deg)
//         |                        |
//       rad_top               bisector
//         |                        |
//         P6 ---arc_inner_upper--- P4
//
//         P4 ---arc_inner_lower--- P2(0deg inner)
//         |                        |
//       bisector              rad_right
//         |                        |
//         P5 ---arc_outer_lower--- P3(0deg outer)
//
// Shared edge: bisector from P4 (r=0.1, 45deg) to P5 (r=1.0, 45deg)
// ============================================================

// -----------------------------------------------------------
// Mesh resolution parameters
// -----------------------------------------------------------
Nr     = 20;   // divisions in the radial direction   (r: 0.1 -> 1.0)
Ntheta = 10;   // divisions per sub-sector arc        (theta: 45 deg each)
               // total angular divisions = 2 * Ntheta across 90 deg
Nz     = 4;    // divisions in the extrusion direction (z: 0.0 -> 0.2)
dz     = 0.2;  // extrusion depth

r_in   = 0.1;  // inner radius
r_out  = 1.0;  // outer radius

// -----------------------------------------------------------
// Points (base plane z = 0)
//
// Angles: 0 deg, 45 deg, 90 deg
// Each angle has one inner point (r = r_in) and one outer point (r = r_out)
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

// Lower sub-sector (theta in [0, 45 deg]) -> TRIANGLES -> PRISMS
Curve Loop(1)    = {1, 6, -2, -4};
Plane Surface(1) = {1};

// Upper sub-sector (theta in [45, 90 deg]) -> QUADS -> HEXAHEDRA
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
//
// Both surfaces MUST be transfinite before extruding — without
// this, the extrusion produces tets/pyramids instead of
// clean prisms and hexahedra.
// -----------------------------------------------------------

// Lower sub-sector: structured triangles -> prisms after extrusion
Transfinite Surface{1} = {2, 3, 5, 4} Alternate;

// Upper sub-sector: structured quads -> hexahedra after extrusion
Transfinite Surface{2} = {4, 5, 7, 6};
Recombine Surface{2};

// -----------------------------------------------------------
// Extrusion
//
// Each surface is extruded separately with identical Layers{Nz}
// so z-planes are perfectly aligned across the bisector interface.
//
// Surface(1): transfinite tris  + no Recombine -> PRISMS
// Surface(2): transfinite quads + Recombine    -> HEXAHEDRA
//
// The Recombine inside ext_quad[] recombines the lateral quad
// faces of the extruded quads into proper hex faces.
// -----------------------------------------------------------

// Lower sub-sector extrusion -> PRISMS
ext_tri[] = Extrude {0, 0, dz} {
    Surface{1};
    Layers{Nz};
    Recombine;   // recombine lateral faces -> prims
};

// Upper sub-sector extrusion -> HEXAHEDRA
ext_quad[] = Extrude {0, 0, dz} {
    Surface{2};
    Layers{Nz};
    Recombine;   // recombine lateral faces -> hexahedra
};

// -----------------------------------------------------------
// Extrude return value layout (4-sided surface):
//
//   ext[0]  : top surface (z = dz)
//   ext[1]  : volume
//   ext[2]  : lateral face from 1st curve in loop (radial/bisector)
//   ext[3]  : lateral face from 2nd curve in loop (outer arc)
//   ext[4]  : lateral face from 3rd curve in loop (bisector/top radial, reversed)
//   ext[5]  : lateral face from 4th curve in loop (inner arc, reversed)
// -----------------------------------------------------------

// -----------------------------------------------------------
// Physical groups
// -----------------------------------------------------------

// Volumes
Physical Volume("prisms",    1) = {ext_tri[1]};
Physical Volume("hexahedra", 2) = {ext_quad[1]};

// Bottom faces (z = 0, base plane)
Physical Surface("bottom_tri",  10) = {1};
Physical Surface("bottom_quad", 11) = {2};

// Top faces (z = dz)
Physical Surface("top_tri",  12) = {ext_tri[0]};
Physical Surface("top_quad", 13) = {ext_quad[0]};

// Lateral faces — tri (lower) sub-sector
Physical Surface("right_radial_tri",  20) = {ext_tri[2]};    // theta = 0 deg
Physical Surface("outer_arc_tri",     21) = {ext_tri[3]};    // r = r_out, lower
Physical Surface("inner_arc_tri",     22) = {ext_tri[5]};    // r = r_in,  lower

// Lateral faces — quad (upper) sub-sector
Physical Surface("outer_arc_quad",   30) = {ext_quad[3]};   // r = r_out, upper
Physical Surface("top_radial_quad",  31) = {ext_quad[4]};   // theta = 90 deg
Physical Surface("inner_arc_quad",   32) = {ext_quad[5]};   // r = r_in,  upper

// Bisector interface (internal, x = 0.5 equivalent at 45 deg)
// Expose if needed for post-processing or inter-domain flux computation
Physical Surface("bisector_tri",  40) = {ext_tri[4]};
Physical Surface("bisector_quad", 41) = {ext_quad[2]};

// -----------------------------------------------------------
// Global mesh options
// -----------------------------------------------------------
Mesh.Algorithm   = 6;   // Frontal-Delaunay for the base 2D mesh
Mesh.Algorithm3D = 4;   // Frontal for 3D (consistent with structured extrusion)

Mesh.SecondOrderLinear = 0;
Coherence;
