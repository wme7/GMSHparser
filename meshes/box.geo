// ============================================================
// Rectangular box volume mesh
//
// Domain: x in [-0.05, 0.05]
//         y in [-0.03, 0.03]
//         z in [-0.03, 0.03]
//
// All six faces are tagged as "free" (Physical Surface).
// The enclosed volume is tagged as "fluid" (Physical Volume).
// ============================================================

// -----------------------------------------------------------
// Mesh resolution parameter
// -----------------------------------------------------------
lc = 0.02;   // characteristic element size

// -----------------------------------------------------------
// Points
//
// Bottom face (z = -0.03): Points 1-4
// Top face    (z =  0.03): Points 5-8
//
//   8 --- 7       4 --- 3
//   |     |       |     |
//   5 --- 6       1 --- 2
//   top face      bottom face   (viewed from outside, -z side)
// -----------------------------------------------------------

// Bottom face corners (z = -0.03)
Point(1) = {-0.05, -0.03, -0.03, lc};   // bottom-left-back
Point(2) = { 0.05, -0.03, -0.03, lc};   // bottom-right-back
Point(3) = { 0.05,  0.03, -0.03, lc};   // top-right-back
Point(4) = {-0.05,  0.03, -0.03, lc};   // top-left-back

// Top face corners (z = +0.03)
Point(5) = {-0.05, -0.03,  0.03, lc};   // bottom-left-front
Point(6) = { 0.05, -0.03,  0.03, lc};   // bottom-right-front
Point(7) = { 0.05,  0.03,  0.03, lc};   // top-right-front
Point(8) = {-0.05,  0.03,  0.03, lc};   // top-left-front

// -----------------------------------------------------------
// Lines
//
// Front face edges (z = +0.03): Lines 1-4
// Back  face edges (z = -0.03): Lines 5-8
// Connecting edges (z-direction): Lines 9-12
// -----------------------------------------------------------

// Front face (z = +0.03)
Line(1)  = {8, 7};   // top    edge, front
Line(2)  = {7, 6};   // right  edge, front
Line(3)  = {6, 5};   // bottom edge, front
Line(4)  = {5, 8};   // left   edge, front

// Back face (z = -0.03)
Line(5)  = {3, 2};   // bottom edge, back
Line(6)  = {2, 1};   // left   edge, back
Line(7)  = {1, 4};   // top    edge, back
Line(8)  = {4, 3};   // right  edge, back

// Connecting edges (front-to-back, z-direction)
Line(9)  = {3, 7};   // top-right  connector
Line(10) = {2, 6};   // bot-right  connector
Line(11) = {8, 4};   // top-left   connector
Line(12) = {5, 1};   // bot-left   connector

// -----------------------------------------------------------
// Curve Loops and Surfaces
//
// Six faces of the box. Normal orientations follow the
// right-hand rule; the surface loop below requires outward
// normals for a positive volume.
// -----------------------------------------------------------

// Right face   (x = +0.05)
Curve Loop(13)  = {9, 2, -10, -5};    Plane Surface(14) = {13};

// Top face     (y = +0.03)
Curve Loop(15)  = {1, -9, -8, -11};   Plane Surface(16) = {15};

// Back face    (z = -0.03)
Curve Loop(17)  = {8, 5, 6, 7};       Plane Surface(18) = {17};

// Bottom face  (y = -0.03)
Curve Loop(19)  = {3, 12, -6, 10};    Plane Surface(20) = {19};

// Left face    (x = -0.05)
Curve Loop(21)  = {12, 7, -11, -4};   Plane Surface(22) = {21};

// Front face   (z = +0.03)
// Note: curve loop is reversed (-23) to ensure outward normal
Curve Loop(23)  = {2, 3, 4, 1};       Plane Surface(24) = {-23};

// -----------------------------------------------------------
// Surface Loop and Volume
// -----------------------------------------------------------
Surface Loop(25) = {24, 14, 16, 18, 20, 22};
Volume(26) = {25};

// -----------------------------------------------------------
// Physical groups
// -----------------------------------------------------------
Physical Surface("free",  1) = {14, 16, 18, 20, 22, 24};
Physical Volume("fluid",  2) = {26};
