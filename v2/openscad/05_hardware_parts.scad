// ============================================================
// Part 05: HARDWARE PARTS PLATE V2
// Seestar S50 Nano Dome V2 — Bambu H2S | PETG
//
// All small hardware parts on one 320×320 plate.
// ALL parts oriented FLAT on build plate — Z min = 0 throughout.
//
//   5a — Motor Mount Bracket (lying flat, wide face down)
//   5b — Lead Screw Bearing Block (lying flat, wide face down)
//   5c — Lead Screw Pivot Arm (lying flat)
//   5d — M10 Hinge Pin Retainer Clip (×4)
//   5e — Limit Switch Bracket (×2)
//   5f — Arduino Nano Tray
//   5g — Slot Rain / Dew Cover
//
// PRINT ORIENTATION: All flat, no supports
// PRINT TIME: ~3.5h  |  FILAMENT: ~90g PETG
// ============================================================

include <params.scad>

// ---- 5a: Motor Mount Bracket --------------------------------
// Printed flat (wide face on bed). Motor bolts through the
// 10mm wall face once fitted to the base ring.
module motor_bracket() {
    // Outer dims: (NEMA17_W+18) × 10 × (NEMA17_W+18)
    // Lay on its 10mm face → height on plate = 10mm
    W = NEMA17_W + 18;  // 60.3
    D = 10;
    H = NEMA17_W + 18;  // 60.3
    translate([0, 0, 0]) {
        // Rotate so the 10mm depth becomes the print height
        rotate([90, 0, 0])
        translate([0, 0, -D])
        difference() {
            cube([W, D, H]);
            // NEMA17 bolt holes (M3, 31mm square)
            for (x = [-1, 1], z = [-1, 1])
                translate([W/2 + x*15.5, -1, H/2 + z*15.5])
                    rotate([-90,0,0]) cylinder(d=3.4, h=D+2);
            // Shaft clearance
            translate([W/2, -1, H/2])
                rotate([-90,0,0]) cylinder(d=24, h=D+2);
            // Mount slots (×2)
            for (z = [10, H-10])
                translate([W/2, D+1, z])
                    rotate([90,0,0])
                        hull() {
                            translate([0,-6,0]) cylinder(d=5.5, h=D+4);
                            translate([0, 6,0]) cylinder(d=5.5, h=D+4);
                        }
        }
    }
}

// ---- 5b: Lead Screw Bearing Block ---------------------------
// Printed flat (32×22 footprint on bed, 32mm tall → lay 32×32 face down)
module bearing_block() {
    translate([75, 0, 0]) {
        // Lay on the 32×22 face (longest dimension along bed)
        // Part is 32(X) × 22(Y) × 32(Z) standing up
        // Rotate to put 32×32 face on bed, bore running Y direction
        difference() {
            cube([32, 32, 22]);
            // M8 bore (runs through Y=22 face, now pointing up in Z)
            translate([16, 16, -1])
                cylinder(d=LS_D+0.5, h=24);
            // F688 bearing pocket (top face, Z=22)
            translate([16, 16, 16])
                cylinder(d=16.3, h=8);
            // M4 mount holes
            for (x=[5, 27])
                translate([x, 16, -1])
                    cylinder(d=4.5, h=24);
        }
    }
}

// ---- 5c: Lead Screw Pivot Arm -------------------------------
// Printed flat on its widest face (22×55mm footprint, 12mm tall)
// Pivot bores run vertically (Z) — drill out after printing if needed
module pivot_arm() {
    translate([125, 0, 0]) {
        // Lay flat: 22(X) × 55(Y) × 12(Z)
        // Lower pivot at Y=11, upper pivot at Y=48
        difference() {
            union() {
                // Main body
                cube([22, 44, 12]);
                // Rounded boss at top end
                translate([11, 44, 0])
                    cylinder(d=22, h=12);
            }
            // M8 lower pivot bore (vertical through Z)
            translate([11, 11, -1])
                cylinder(d=LS_D+0.5, h=14);
            // M8 hex nut recess (top face, for captured nut)
            translate([11, 11, 6])
                rotate([0,0,30])
                    cylinder(d=LS_NUT_W+0.6, h=LS_NUT_H+1, $fn=6);
            // M8 upper pivot bore
            translate([11, 48, -1])
                cylinder(d=LS_D+0.5, h=14);
            // Lightening slot
            translate([5, 18, 2])
                cube([12, 20, 11]);
        }
    }
}

// ---- 5d: M10 Hinge Pin Retainer Clips (×4) ------------------
// Small snap rings — print flat, snap slot in XY plane
module hinge_clips() {
    translate([190, 0, 0]) {
        for (i = [0:3])
            translate([i * 26, 0, 0]) {
                difference() {
                    cylinder(d=18, h=5);
                    // Snap slot (1.5mm wide, cut through full height)
                    translate([-9.5, -0.75, -1])
                        cube([19, 1.5, 7]);
                    // M10 pin bore
                    cylinder(d=10.3, h=6);
                }
            }
    }
}

// ---- 5e: Limit Switch Brackets (×2) -------------------------
module limit_brackets() {
    translate([0, 75, 0]) {
        for (i = [0, 1])
            translate([i * 40, 0, 0]) {
                difference() {
                    cube([SW_W+10, SW_D+10, SW_H+8]);
                    translate([5, 5, 4])
                        cube([SW_W, SW_D, SW_H+6]);
                    for (x = [2.5, SW_W+7.5])
                        translate([x, SW_D/2+5, -1])
                            cylinder(d=2.3, h=SW_H+12);
                    translate([SW_W/2+5, -1, SW_H/2+4])
                        rotate([-90,0,0])
                            cylinder(d=4.5, h=SW_D+12);
                }
            }
    }
}

// ---- 5f: Arduino Nano Tray ----------------------------------
module nano_tray() {
    translate([100, 75, 0]) {
        A_W=19; A_L=45;
        difference() {
            cube([A_W+8, A_L+8, 8]);
            translate([4, 4, 3]) cube([A_W, A_L, 7]);
            translate([A_W/2+4, -1, 1.5]) cube([13, 7, 5]);
            for (x=[0, A_W+8])
                translate([x, A_L/2+4, 6])
                    cylinder(d=3.5, h=5);
        }
    }
}

// ---- 5g: Slot Rain / Dew Cover ------------------------------
// Snap clips corrected — all geometry above Z=0
module slot_cover() {
    translate([160, 75, 0]) {
        COVER_W = SLOT_W + 12;  // 92
        COVER_L = 80;
        COVER_H = 8;
        CLIP_H  = 10;
        difference() {
            union() {
                // Main cover plate
                hull() {
                    cylinder(d=COVER_W, h=COVER_H);
                    translate([0, COVER_L, 0])
                        cylinder(d=COVER_W, h=COVER_H);
                }
                // Snap clips — sit ABOVE and BESIDE plate (no negative Z)
                for (y = [15, COVER_L-15])
                    for (sx = [-1, 1])
                        translate([sx*(SLOT_W/2+3), y, 0])
                            cube([4, 10, CLIP_H], center=false);
            }
            // Lightening pocket
            translate([0, COVER_L/2, 3])
                hull() {
                    cylinder(d=COVER_W-14, h=COVER_H+1);
                    translate([0, COVER_L/2-8, 0])
                        cylinder(d=COVER_W-14, h=COVER_H+1);
                }
        }
    }
}

// --- Render all on plate ---
motor_bracket();
bearing_block();
pivot_arm();
hinge_clips();
limit_brackets();
nano_tray();
slot_cover();
