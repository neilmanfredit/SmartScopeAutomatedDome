// ============================================================
// Part 03: CROWN PANEL FRAME + PANEL A + PANEL B
// Seestar S50 Slewing Dome V3 — Bambu H2S | PETG
//
// The crown panel frame sits on top of the lower dome shell
// and provides the slot + linear guides for Panel A and B.
//
// Panel A = left panel (Motor 2), Panel B = right panel (Motor 3)
// Both panels slide laterally (X axis) in the crown slot.
// When both panels are centred, the slot is fully closed.
// When both panels retract outward, the slot opens.
// Max slot opening: 80mm wide × full dome depth.
//
// Panel mechanism:
//   - M6 × 1.0mm lead screw, driven by NEMA17 via flexible coupler
//   - Panel has captured M6 nut (anti-rotation pin in guide rail)
//   - Linear guide: 8mm OD rod + LM8UU linear bearing per panel
//   - Guide rods span the crown frame front-to-back
//   - Sealing lip: 3mm foam on mating edges, 6mm overlap
//
// Print: Panel A and B separately; Frame as one piece.
//
// FRAME:
//   ORIENTATION: Split face down, dome exterior up
//   SUPPORTS: Tree auto
//   PRINT TIME: ~8h  |  FILAMENT: ~250g
//
// EACH PANEL:
//   ORIENTATION: Flat on plate
//   SUPPORTS: None
//   PRINT TIME: ~2h each  |  FILAMENT: ~70g each
// ============================================================

include <params.scad>

// ── Crown Panel Frame ────────────────────────────────────────
module crown_frame() {
    difference() {
        union() {
            // Outer shell (mirrors upper dome V2 geometry)
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
                translate([0, 0, LID_H - 18])
                    sphere(d = 80);
            }

            // Sealing lip (overlaps lower shell 8mm)
            translate([0, 0, -8])
                cylinder(d = OW + 24, h = 10);

            // Panel guide rail housings (left + right of slot)
            for (side = [-1, 1])
                translate([side * (PANEL_SLOT_W / 2 + 5), 0, LID_H - 40])
                    cube([16, OD_s + 10, 35], center = true);

            // Crown slot surround (structural ring around opening)
            translate([0, 0, LID_H - 30])
                difference() {
                    hull() {
                        translate([0, -(OD_s/2+12), 0])
                            cylinder(d = PANEL_SLOT_W + 24, h = 32);
                        translate([0,  (OD_s/2+12), 0])
                            cylinder(d = PANEL_SLOT_W + 24, h = 32);
                    }
                    hull() {
                        translate([0, -(OD_s/2+13), 1])
                            cylinder(d = PANEL_SLOT_W + 4, h = 34);
                        translate([0,  (OD_s/2+13), 1])
                            cylinder(d = PANEL_SLOT_W + 4, h = 34);
                    }
                }

            // Exterior ribs (8 off)
            for (a = [0, 45, 90, 135, 180, 225, 270, 315])
                rotate([0, 0, a])
                    translate([OW / 2 - RIB_T / 2, 0, 0])
                        cube([RIB_T, RIB_H, LID_H * 0.65]);
        }

        // Interior cavity
        translate([0, 0, WALL])
            hull() {
                scale([inner_w / 2 + 9, inner_d / 2 + 7, 1])
                    cylinder(r = 1, h = 2);
                translate([0, 0, LID_H - WALL - 15])
                    scale([inner_w / 2, inner_d / 2, 1])
                        cylinder(r = 1, h = 2);
            }

        // Crown slot (full length opening — panels slide here)
        translate([0, 0, LID_H - 32])
            hull() {
                translate([0, -(OD_s/2 + 15), 0])
                    cylinder(d = PANEL_SLOT_W, h = 36);
                translate([0,  (OD_s/2 + 15), 0])
                    cylinder(d = PANEL_SLOT_W, h = 36);
            }

        // 8mm guide rod bores (front-to-back, left + right of slot)
        for (side = [-1, 1])
            translate([side * (PANEL_SLOT_W / 2 + 5),
                       0, LID_H - 38])
                rotate([90, 0, 0])
                    cylinder(d = 8.3, h = OD_s + 30, center = true);

        // M6 lead screw bores (coaxial with guide rods, just inside)
        for (side = [-1, 1])
            translate([side * (PANEL_SLOT_W / 2 + 5), 0, LID_H - 22])
                cylinder(d = PANEL_LS_D + 0.4, h = 30);

        // Split flange bolt holes (6× M4)
        for (a = [30, 90, 150, 210, 270, 330])
            rotate([0, 0, a])
                translate([OW / 2 + 7, 0, -3])
                    cylinder(d = 4.5, h = 14);

        // Foam seal groove
        translate([0, 0, -3])
            rotate_extrude()
                translate([OW / 2 + 9, 0])
                    circle(d = 3.5);
    }
}

// ── Individual Panel (parametric, mirrored for A + B) ────────
// Printed FLAT on build plate — Z=0 is bed face, Z=PH is top
// side: +1 = Panel B (right), -1 = Panel A (left)
module panel(side = 1) {
    PW = PANEL_W;       // panel width including overlap
    PL = OD_s + 20;     // panel length (front to back)
    PH = 6;             // panel thickness

    // Bearing housing height above panel top face
    BH = PH + 8;        // total height of bearing boss

    difference() {
        union() {
            // Main panel plate — Z=0 (bed) to Z=PH (top)
            cube([PW, PL, PH]);

            // Leading edge overlap lip — above bed (Z=PH to Z=PH+3)
            // Sits on top face edge, no negative Z
            translate([side == 1 ? 0 : PW - 6, 0, PH])
                cube([6, PL, 3]);

            // LM8UU bearing housings (front + rear) — above bed
            for (y = [8, PL - 28])
                translate([side == 1 ? PW - 16 : 0, y, 0])
                    cube([16, 20, BH]);

            // M6 nut tower — above bed
            translate([side == 1 ? PW - 32 : 20, PL/2 - 6, 0])
                cube([12, 12, PH + 10]);
        }

        // LM8UU bearing bores (15mm OD, run along Y axis)
        for (y = [18, PL - 18])
            translate([side == 1 ? PW - 8 : 8, y, BH/2])
                rotate([90, 0, 0])
                    cylinder(d = 15.3, h = 26, center = true);

        // 8mm guide rod bore (full length, Y axis)
        translate([side == 1 ? PW - 8 : 8, PL/2, BH/2])
            rotate([90, 0, 0])
                cylinder(d = 8.3, h = PL + 10, center = true);

        // M6 lead screw bore (vertical, Z axis through nut tower)
        translate([side == 1 ? PW - 26 : 26, PL/2, -1])
            cylinder(d = PANEL_LS_D + 0.4, h = PH + 14);

        // M6 hex nut pocket (from top, captured)
        translate([side == 1 ? PW - 26 : 26, PL/2, PH + 2])
            rotate([0, 0, 30])
                cylinder(d = 11.6, h = 5.5, $fn = 6);

        // Anti-rotation slot
        translate([side == 1 ? PW - 22 : 18, PL/2 - 10, -1])
            cube([3, 20, PH + 14]);

        // Lightening pockets (in main plate)
        for (y = [PL*0.2, PL*0.6])
            translate([side == 1 ? 8 : 8, y, -1])
                cube([PW/2 - 12, PL/5, PH + 2]);

        // Foam seal groove (top face, leading edge)
        translate([side == 1 ? 2 : PW - 5.5, 5, PH - 2])
            cube([3.5, PL - 10, 3.5]);
    }
}

// ── Render all three parts on plate ─────────────────────────
// Crown frame: sealing lip extends -8mm below z=0, lift by 9
translate([0, 0, 9])
    crown_frame();

// Panel A: flat on bed, offset to side of frame
// Panel is (PANEL_W × PANEL_L × 6mm) — print flat
translate([-(OW/2 + PANEL_W + 20), 0, 0])
    panel(-1);   // Panel A (left)

// Panel B: flat on bed, other side
translate([ OW/2 + PANEL_W + 20, 0, 0])
    panel(+1);   // Panel B (right)
