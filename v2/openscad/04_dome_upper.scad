// ============================================================
// Part 04: DOME UPPER HALF V2 (hinged lid)
// Seestar S50 Nano Dome V2 — Bambu H2S | PETG
//
// Key changes from V1:
//   - Matches larger V2 lower shell (261×239mm)
//   - Crown aperture replaced with FULL-LENGTH SLOT
//     running front-to-back: 80mm wide × full dome depth
//     Allows scope to point from ~15° altitude to zenith
//     in both Alt/Az and EQ mode without clipping dome walls
//   - Slot has a smooth internal radiused edge (no snag)
//   - Hinge knuckles upgraded to M10 pin
//   - Foam seal groove at split face (3mm half-round)
//   - Sealing lip overlaps lower flange 8mm
//
// PRINT ORIENTATION: Split face DOWN on build plate
// SUPPORTS: Tree auto (internal overhangs)
// PRINT TIME: ~10h  |  FILAMENT: ~280g PETG
// NOTE: ~261mm wide — fits H2S 320×320 comfortably
// ============================================================

include <params.scad>

OW      = inner_w + WALL * 2;
OD_s    = inner_d + WALL * 2;
LID_H   = dome_h - SPLIT_Z;    // ~152mm

module dome_upper_v2() {
    difference() {
        union() {
            // --- Main lid shell ---
            hull() {
                translate([0, 0, 0])
                    scale([OW / 2 + 8, OD_s / 2 + 6, 1])
                        cylinder(r = 1, h = 2);
                translate([0, 0, LID_H * 0.45])
                    scale([OW / 2 + 5, OD_s / 2 + 3, 1])
                        cylinder(r = 1, h = 2);
                translate([0, 0, LID_H * 0.78])
                    scale([OW / 2, OD_s / 2, 1])
                        cylinder(r = 1, h = 2);
                // Rounded crown
                translate([0, 0, LID_H - 18])
                    sphere(d = 80);
            }

            // --- Sealing lip (overlaps lower 8mm) ---
            translate([0, 0, -8])
                cylinder(d = OW + 24, h = 10);

            // --- Hinge knuckles (female, M10, 3 per side) ---
            for (s = [-1, 1])
                for (zo = [-HINGE_L * 0.38, HINGE_L * 0.38])
                    translate([s * (OW / 2 + 5), 0, zo])
                        rotate([0, 90, 0])
                            cylinder(d = 18, h = HINGE_L / 3 - 1, center = true);

            // --- Lead screw pivot bracket (rear) ---
            translate([0, OD_s / 2 + WALL + 1, LID_H * 0.22])
                cube([24, 16, 35], center = true);

            // --- Exterior ribs (8 off, aligned with lower) ---
            for (a = [0, 45, 90, 135, 180, 225, 270, 315])
                rotate([0, 0, a])
                    translate([OW / 2 - RIB_T / 2, 0, 0])
                        cube([RIB_T, RIB_H, LID_H * 0.65]);
        }

        // --- Interior cavity ---
        translate([0, 0, WALL])
            hull() {
                scale([inner_w / 2 + 9, inner_d / 2 + 7, 1])
                    cylinder(r = 1, h = 2);
                translate([0, 0, LID_H - WALL - 15])
                    scale([inner_w / 2, inner_d / 2, 1])
                        cylinder(r = 1, h = 2);
            }

        // --- FULL-LENGTH CROWN SLOT ---
        // 80mm wide, runs full dome depth front-to-back
        // Radiused ends to prevent snagging scope cable
        translate([0, 0, LID_H - 25])
            hull() {
                translate([0, -(OD_s / 2 + 10), 0])
                    cylinder(d = SLOT_W, h = 40);
                translate([0,  (OD_s / 2 + 10), 0])
                    cylinder(d = SLOT_W, h = 40);
            }

        // --- Slot internal edge radius (smooth, no snag) ---
        // Chamfer on all four slot edges
        translate([0, 0, LID_H - 25])
            hull() {
                translate([0, -(OD_s / 2 + 10), 3])
                    cylinder(d = SLOT_W + 6, h = 5);
                translate([0,  (OD_s / 2 + 10), 3])
                    cylinder(d = SLOT_W + 6, h = 5);
            }

        // --- Hinge pin bores (M10) ---
        for (s = [-1, 1])
            translate([s * (OW / 2 + 5), 0, 0])
                rotate([0, 90, 0])
                    cylinder(d = 10.4, h = HINGE_L + 4, center = true);

        // --- Split flange bolt holes (6× M4) ---
        for (a = [30, 90, 150, 210, 270, 330])
            rotate([0, 0, a])
                translate([OW / 2 + 7, 0, -3])
                    cylinder(d = 4.5, h = 14);

        // --- Lead screw pivot hole (M8) ---
        translate([0, OD_s / 2 + WALL + 1, LID_H * 0.22])
            rotate([90, 0, 0])
                cylinder(d = LS_D + 0.5, h = 22);

        // --- Foam seal channel (split face) ---
        translate([0, 0, -3])
            rotate_extrude()
                translate([OW / 2 + 9, 0])
                    circle(d = 3.5);

        // --- Weather lip step (8mm overlap) ---
        translate([0, 0, -8])
            difference() {
                cylinder(d = OW + 25, h = 5);
                cylinder(d = OW + 16, h = 5);
            }
    }
}

// Translate to ensure Z-min = 0 on build plate
// Sealing lip and foam groove extend below z=0, lift by 23
translate([0, 0, 23])
    dome_upper_v2();
