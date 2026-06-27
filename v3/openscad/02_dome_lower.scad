// ============================================================
// Part 02: ROTATING DOME LOWER SHELL V3
// Seestar S50 Slewing Dome V3 — Bambu H2S | PETG
//
// This part ROTATES on top of the base ring via the lazy-susan
// bearing. The bearing inner race bolts to the underside of
// this shell. The two panel motors (NEMA17 #2 and #3) are
// mounted on this shell and rotate with it.
//
// Key features:
//   - Bearing inner race seat (underside, 240mm ID ring)
//   - 8× M4 bolts clamp bearing inner race to shell bottom
//   - Panel motor mounts: left (Motor 2 — Panel A) and
//     right (Motor 3 — Panel B), mounted on crown rim
//   - Panel lead screw guides (M6, vertical, run up crown)
//   - Encoder disk mount (underside, faces base ring sensor)
//   - Az encoder disk: 36-slot, IR-reflective
//   - Scope free — no ribs, full clearance
//   - Crown opening: full-length slot for panels to slide in
//
// PRINT ORIENTATION: Flat bottom on plate, interior up
// SUPPORTS: Tree auto (internal overhangs)
// PRINT TIME: ~11h  |  FILAMENT: ~330g PETG
// BED: 320×320mm
// ============================================================

include <params.scad>

module dome_lower_v3() {
    difference() {
        union() {
            // Main shell (ovoid)
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

            // Bearing inner race seat (bottom flange)
            // 240mm ID, sits on lazy-susan inner race
            translate([0, 0, -LS_BEAR_H])
                difference() {
                    cylinder(d = LS_BEAR_ID + 8, h = LS_BEAR_H + 4);
                    cylinder(d = LS_BEAR_ID - 4, h = LS_BEAR_H + 5);
                }

            // Split-line flange (top — mates with upper panel frame)
            translate([0, 0, SPLIT_Z - 3])
                cylinder(d = OW + 22, h = 6);

            // Panel motor mounts (left = Panel A, right = Panel B)
            // Motors sit at crown level, drive M6 screws vertically
            for (side = [-1, 1])
                translate([side * (OW / 2 - NEMA17_W / 2 - 4),
                           0, SPLIT_Z - 5])
                    cube([NEMA17_W + 8, NEMA17_D + 6, NEMA17_W + 8],
                         center = true);

            // Exterior ribs (8 off)
            for (a = [0, 45, 90, 135, 180, 225, 270, 315])
                rotate([0, 0, a])
                    translate([OW / 2 - RIB_T / 2, 0, 0])
                        cube([RIB_T, RIB_H, SPLIT_Z - 12]);

            // Encoder disk hub (underside centre)
            translate([0, 0, -LS_BEAR_H - 6])
                cylinder(d = 30, h = 6);
        }

        // Interior bore (scope floats freely)
        translate([0, 0, WALL])
            hull() {
                scale([inner_w / 2, inner_d / 2, 1])
                    cylinder(r = 1, h = 2);
                translate([0, 0, SPLIT_Z - WALL - 5])
                    scale([inner_w / 2 + 9, inner_d / 2 + 7, 1])
                        cylinder(r = 1, h = 2);
            }

        // Bearing inner race bore (under flange)
        translate([0, 0, -LS_BEAR_H - 0.1])
            cylinder(d = LS_BEAR_ID + 0.5, h = LS_BEAR_H + 2);

        // 8× M4 bearing clamp bolts (bearing inner race to shell)
        for (a = [0, 45, 90, 135, 180, 225, 270, 315])
            rotate([0, 0, a])
                translate([LS_BEAR_ID / 2 - 8, 0, -LS_BEAR_H - 0.1])
                    cylinder(d = 4.5, h = LS_BEAR_H + 8);

        // Panel A motor pocket (left crown)
        translate([-(OW / 2 - NEMA17_W / 2 - 4), 0, SPLIT_Z - 5]) {
            rotate([0, 90, 0]) {
                cube([NEMA17_W, NEMA17_W, NEMA17_D + 6], center = true);
                cylinder(d = 24, h = NEMA17_D + 10, center = true);
                for (x = [-1,1], y = [-1,1])
                    translate([x*15.5, y*15.5, -NEMA17_D/2-4])
                        cylinder(d = 3.4, h = 8);
            }
        }

        // Panel B motor pocket (right crown)
        translate([(OW / 2 - NEMA17_W / 2 - 4), 0, SPLIT_Z - 5]) {
            rotate([0, -90, 0]) {
                cube([NEMA17_W, NEMA17_W, NEMA17_D + 6], center = true);
                cylinder(d = 24, h = NEMA17_D + 10, center = true);
                for (x = [-1,1], y = [-1,1])
                    translate([x*15.5, y*15.5, -NEMA17_D/2-4])
                        cylinder(d = 3.4, h = 8);
            }
        }

        // M6 panel lead screw bores (left + right, vertical)
        for (side = [-1, 1])
            translate([side * (PANEL_SLOT_W / 2 + 5), 0, SPLIT_Z - 30])
                cylinder(d = PANEL_LS_D + 0.4, h = 35);

        // Panel lead screw nut traps (M6 hex, at crown)
        for (side = [-1, 1])
            translate([side * (PANEL_SLOT_W / 2 + 5), 0, SPLIT_Z - 16])
                rotate([0, 0, 30])
                    cylinder(d = 11.6, h = 5.5, $fn = 6);

        // Split flange bolt holes (6× M4)
        for (a = [30, 90, 150, 210, 270, 330])
            rotate([0, 0, a])
                translate([OW / 2 + 7, 0, SPLIT_Z - 2])
                    cylinder(d = 4.5, h = 12);

        // Encoder disk recess + slot pattern (36 slots)
        translate([0, 0, -LS_BEAR_H - 6 - 0.1])
            cylinder(d = 28, h = 4);
        for (i = [0 : ENCODER_SLOTS - 1])
            rotate([0, 0, i * (360 / ENCODER_SLOTS)])
                translate([ENCODER_R * 0.5, 0, -LS_BEAR_H - 6])
                    cylinder(d = 4, h = 4);

        // Slip-ring / cable chase (centre vertical through shell)
        cylinder(d = 12, h = SPLIT_Z + 10);

        // Front cable channel (scope USB-C)
        translate([0, -(OD_s / 2 - 1), 25])
            rotate([90, 0, 0])
                hull() {
                    translate([-8, 0, 0]) cylinder(d = 8, h = WALL + 3);
                    translate([ 8, 0, 0]) cylinder(d = 8, h = WALL + 3);
                }
    }
}

// Lift to ensure Z-min = 0 on build plate
// Encoder hub extends to -(LS_BEAR_H+6) = -14mm below shell base
translate([0, 0, 15])
    dome_lower_v3();
