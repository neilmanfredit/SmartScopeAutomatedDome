// ============================================================
// Part 03: DOME LOWER HALF V2
// Seestar S50 Nano Dome V2 — Bambu H2S | PETG
//
// Key changes from V1:
//   - Inner cavity 252×230mm (up from 192×170mm)
//   - Scope locating ribs REMOVED — scope moves freely
//   - Hinge bosses larger (M10 pin, 40mm knuckles)
//   - Lead screw nut tower at rear
//   - Front face open channel for scope cable management
//   - Split at 145mm (up from 130mm)
//   - Bottom flange bolts to base ring top flange (6× M4)
//
// PRINT ORIENTATION: Flat bottom on plate, dome interior up
// SUPPORTS: Tree auto (internal arch overhangs)
// PRINT TIME: ~11h  |  FILAMENT: ~320g PETG
// NOTE: 252mm wide — fits H2S 320×320 bed portrait orientation
// ============================================================

include <params.scad>

OW      = inner_w + WALL * 2;   // ~261mm outer width
OD_s    = inner_d + WALL * 2;   // ~239mm outer depth

module dome_lower_v2() {
    difference() {
        union() {
            // --- Main ovoid shell ---
            hull() {
                translate([0, 0, 0])
                    scale([OW / 2, OD_s / 2, 1])
                        cylinder(r = 1, h = 2);
                translate([0, 0, SPLIT_Z * 0.5])
                    scale([OW / 2 + 10, OD_s / 2 + 8, 1])
                        cylinder(r = 1, h = 2);
                translate([0, 0, SPLIT_Z - 2])
                    scale([OW / 2 + 8, OD_s / 2 + 6, 1])
                        cylinder(r = 1, h = 2);
            }

            // --- Bottom mounting flange (to base ring) ---
            translate([0, 0, -8])
                cylinder(d = BASE_OD + 10, h = 10);

            // --- Top split-line flange ---
            translate([0, 0, SPLIT_Z - 3])
                cylinder(d = OW + 22, h = 6);

            // --- Hinge bosses (left & right, M10 pin) ---
            for (s = [-1, 1])
                translate([s * (OW / 2 + 5), 0, SPLIT_Z])
                    rotate([0, 90, 0])
                        cylinder(d = 18, h = HINGE_L, center = true);

            // --- Rear lead screw nut tower ---
            translate([0, OD_s / 2 - WALL, SPLIT_Z / 2 - 5])
                cube([LS_NUT_W + 10, 14, 30], center = true);

            // --- Exterior vertical ribs (8 off, wider dome) ---
            for (a = [0, 45, 90, 135, 180, 225, 270, 315])
                rotate([0, 0, a])
                    translate([OW / 2 - RIB_T / 2, 0, 0])
                        cube([RIB_T, RIB_H, SPLIT_Z - 12], center = false);
        }

        // --- Interior dome cavity (scope moves freely) ---
        translate([0, 0, WALL])
            hull() {
                scale([inner_w / 2, inner_d / 2, 1])
                    cylinder(r = 1, h = 2);
                translate([0, 0, SPLIT_Z - WALL - 5])
                    scale([inner_w / 2 + 9, inner_d / 2 + 7, 1])
                        cylinder(r = 1, h = 2);
            }

        // --- Base flange bolt holes (6× M4 to base ring) ---
        for (a = [0, 60, 120, 180, 240, 300])
            rotate([0, 0, a])
                translate([BASE_OD / 2 + 1, 0, -9])
                    cylinder(d = 4.5, h = 16);

        // --- Split flange bolt holes (6× M4 to upper half) ---
        for (a = [30, 90, 150, 210, 270, 330])
            rotate([0, 0, a])
                translate([OW / 2 + 7, 0, SPLIT_Z - 2])
                    cylinder(d = 4.5, h = 12);

        // --- Hinge pin bores (M10 stainless rod) ---
        for (s = [-1, 1])
            translate([s * (OW / 2 + 5), 0, SPLIT_Z])
                rotate([0, 90, 0])
                    cylinder(d = 10.4, h = HINGE_L + 4, center = true);

        // --- Lead screw nut trap (rear) ---
        translate([0, OD_s / 2 - 2, SPLIT_Z / 2 - 5])
            rotate([90, 0, 0])
                cylinder(d = LS_D + 0.5, h = 22);
        translate([0, OD_s / 2 - 7, SPLIT_Z / 2 - 5])
            rotate([90, 30, 0])
                cylinder(d = LS_NUT_W + 0.6, h = LS_NUT_H + 1, $fn = 6);

        // --- Front cable channel (scope USB-C + power) ---
        translate([0, -(OD_s / 2 - 1), 25])
            rotate([90, 0, 0])
                hull() {
                    translate([-8, 0, 0]) cylinder(d = 8, h = WALL + 3);
                    translate([ 8, 0, 0]) cylinder(d = 8, h = WALL + 3);
                }

        // --- Side cable chase (left, for motor wiring) ---
        translate([-(inner_w / 2 - 4), 0, 30])
            cube([6, inner_d - 10, 20], center = true);
    }
}

dome_lower_v2();
