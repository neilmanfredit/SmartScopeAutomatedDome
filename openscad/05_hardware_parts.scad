// ============================================================
// Part 05: HARDWARE PARTS PLATE V2
// Seestar S50 Nano Dome V2 — Bambu H2S | PETG
//
// All small hardware parts on one 320×320 plate:
//   5a — NEMA17 Motor Mount Bracket (wider for v2 base ring)
//   5b — M8 Lead Screw Lower Bearing Block
//   5c — M8 Lead Screw Upper Pivot Arm
//   5d — M10 Hinge Pin Retainer Clip (×4, upgraded from M8)
//   5e — Limit Switch Bracket (×2)
//   5f — Arduino Nano Tray
//   5g — Slot Rain Cover (optional, snaps over crown slot when parked)
//
// PRINT ORIENTATION: All flat, no supports
// PRINT TIME: ~3.5h  |  FILAMENT: ~90g PETG
// ============================================================

include <params.scad>

// ---- 5a: Motor Mount Bracket ------------------------------------
module motor_bracket() {
    translate([0, 0, 0]) {
        difference() {
            cube([NEMA17_W + 18, 10, NEMA17_W + 18]);
            for (x = [-1, 1], z = [-1, 1])
                translate([NEMA17_W / 2 + 9 + x * 15.5, -1, NEMA17_W / 2 + 9 + z * 15.5])
                    rotate([-90, 0, 0])
                        cylinder(d = 3.4, h = 14);
            translate([NEMA17_W / 2 + 9, -1, NEMA17_W / 2 + 9])
                rotate([-90, 0, 0])
                    cylinder(d = 24, h = 14);
            for (z = [10, NEMA17_W + 8])
                translate([NEMA17_W / 2 + 9, 12, z])
                    rotate([-90, 0, 0])
                        hull() {
                            translate([0, -6, 0]) cylinder(d = 5.5, h = 12);
                            translate([0,  6, 0]) cylinder(d = 5.5, h = 12);
                        }
        }
    }
}

// ---- 5b: Lead Screw Lower Bearing Block -------------------------
module bearing_block() {
    translate([85, 0, 0]) {
        difference() {
            cube([32, 22, 32]);
            translate([16, -1, 16])
                rotate([-90, 0, 0])
                    cylinder(d = LS_D + 0.5, h = 28);
            // F688 bearing pocket
            translate([16, 17, 16])
                rotate([-90, 0, 0])
                    cylinder(d = 16.3, h = 7);
            for (x = [5, 27])
                translate([x, -1, 6])
                    rotate([-90, 0, 0])
                        cylinder(d = 4.5, h = 28);
        }
    }
}

// ---- 5c: Lead Screw Upper Pivot Arm -----------------------------
module pivot_arm() {
    translate([140, 0, 0]) {
        difference() {
            union() {
                cube([22, 12, 44]);
                translate([11, 6, 44]) sphere(d = 22);
            }
            translate([11, -1, 11])
                rotate([-90, 0, 0])
                    cylinder(d = LS_D + 0.5, h = 18);
            translate([11, 5, 11])
                rotate([-90, 30, 0])
                    cylinder(d = LS_NUT_W + 0.6, h = LS_NUT_H + 1, $fn = 6);
            translate([11, -1, 48])
                rotate([-90, 0, 0])
                    cylinder(d = LS_D + 0.5, h = 18);
        }
    }
}

// ---- 5d: M10 Hinge Pin Retainer Clip (×4) -----------------------
module hinge_clips() {
    translate([210, 0, 0]) {
        for (i = [0:3])
            translate([i * 26, 0, 0]) {
                difference() {
                    cylinder(d = 18, h = 5);
                    // Snap slot (1.5mm) — clip over M10 pin
                    cube([19, 1.5, 6], center = true);
                    // Pin bore
                    cylinder(d = 10.3, h = 6);
                }
            }
    }
}

// ---- 5e: Limit Switch Bracket (×2) ------------------------------
module limit_brackets() {
    translate([0, 45, 0]) {
        for (i = [0, 1])
            translate([i * 35, 0, 0]) {
                difference() {
                    cube([SW_W + 10, SW_D + 10, SW_H + 8]);
                    translate([5, 5, 4])
                        cube([SW_W, SW_D, SW_H + 6]);
                    for (x = [2.5, SW_W + 7.5])
                        translate([x, SW_D / 2 + 5, -1])
                            cylinder(d = 2.3, h = SW_H + 12);
                    translate([SW_W / 2 + 5, -1, SW_H / 2 + 4])
                        rotate([-90, 0, 0])
                            cylinder(d = 4.5, h = SW_D + 12);
                }
            }
    }
}

// ---- 5f: Arduino Nano Tray -------------------------------------
module nano_tray() {
    translate([90, 45, 0]) {
        A_W = 19; A_L = 45;
        difference() {
            cube([A_W + 8, A_L + 8, 8]);
            translate([4, 4, 3])
                cube([A_W, A_L, 7]);
            translate([A_W / 2 + 4, -1, 1.5])
                cube([13, 7, 5]);
            for (x = [0, A_W + 8])
                translate([x, A_L / 2 + 4, 6])
                    cylinder(d = 3.5, h = 5);
        }
    }
}

// ---- 5g: Slot Rain / Dew Cover ----------------------------------
// Snaps over the crown slot when dome is parked (closed)
// Prevents rain ingress through the open slot
module slot_cover() {
    translate([160, 45, 0]) {
        COVER_W = SLOT_W + 12;
        COVER_L = 80;
        COVER_H = 8;
        difference() {
            union() {
                // Main cover plate
                hull() {
                    cylinder(d = COVER_W, h = COVER_H);
                    translate([0, COVER_L, 0])
                        cylinder(d = COVER_W, h = COVER_H);
                }
                // Snap clips (×4, grip slot edges)
                for (y = [15, COVER_L - 15])
                    for (x = [-1, 1])
                        translate([x * (SLOT_W / 2 + 3), y, -8])
                            cube([4, 10, 10], center = true);
            }
            // Lightening pocket
            translate([0, COVER_L / 2, 3])
                hull() {
                    cylinder(d = COVER_W - 10, h = COVER_H);
                    translate([0, COVER_L / 2 - 5, 0])
                        cylinder(d = COVER_W - 10, h = COVER_H);
                }
        }
    }
}

// --- Render all ---
motor_bracket();
bearing_block();
pivot_arm();
hinge_clips();
limit_brackets();
nano_tray();
slot_cover();
