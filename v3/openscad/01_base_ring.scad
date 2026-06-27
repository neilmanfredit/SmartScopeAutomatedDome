// ============================================================
// Part 01: STATIC BASE RING V3
// Seestar S50 Slewing Dome V3 — Bambu H2S | PETG
//
// This ring does NOT rotate. The dome shell sits on top via
// the lazy-susan bearing. The ring gear (72 teeth, module 2)
// is on the outer rim and is driven by the Az pinion motor.
//
// Key features:
//   - Lazy-susan bearing seat on top face (recessed 5mm)
//   - Ring gear teeth on outer circumference (pinion drive option)
//   - Friction drive rail (smooth rim, rubber-wheel option)
//   - Rear motor bay: Az motor (motor 1) + panel motors (2 & 3)
//     routed via flex cable chase to dome shell above
//   - Electronics bay: Arduino Mega 2560 + 3× A4988 drivers
//   - 6× M5 adapter plate bolts (bottom, same as V2)
//   - Az encoder IR sensor bracket (rear right)
//
// PRINT ORIENTATION: Flat, open top face up
// SUPPORTS: None required
// PRINT TIME: ~7h  |  FILAMENT: ~260g PETG
// BED: 320×320mm — rotate 45° in Bambu Studio
// ============================================================

include <params.scad>

module base_ring_v3() {
    OD = BASE_OD;
    ID = OD - WALL * 2;
    H  = BASE_H;

    difference() {
        union() {
            // Main cylinder
            cylinder(d = OD, h = H);

            // Bearing seat lip (top — bearing outer race sits here)
            translate([0, 0, H - BEAR_SEAT_DEPTH])
                difference() {
                    cylinder(d = LS_BEAR_OD + 8, h = BEAR_SEAT_DEPTH + 3);
                    cylinder(d = LS_BEAR_OD - 4, h = BEAR_SEAT_DEPTH + 4);
                }

            // Bottom flange (adapter plate)
            cylinder(d = OD + 8, h = 6);

            // ---- Ring gear on outer rim (pinion drive option) ----
            // Module 2, 72 teeth, pitch radius 160mm → OD ~328mm
            // Teeth sit proud of base ring outer surface
            for (i = [0 : RING_GEAR_T - 1]) {
                rotate([0, 0, i * (360 / RING_GEAR_T)])
                    translate([OD / 2, 0, H * 0.35])
                        cube([RING_MODULE * 2, RING_MODULE * PI, H * 0.3],
                             center = true);
            }

            // Az motor boss (rear, external)
            translate([0, OD / 2 - WALL - 2, H * 0.35])
                cube([NEMA17_W + 14, NEMA17_D + WALL * 2 + 4, NEMA17_W + 14],
                     center = true);

            // Encoder sensor bracket (right side, near rim)
            translate([OD / 2 - 10, -15, H - 20])
                cube([18, 12, 22]);
        }

        // Interior bore
        translate([0, 0, -0.1])
            cylinder(d = ID, h = H + 1);

        // Bearing seat recess (top face — fits lazy-susan outer race)
        translate([0, 0, H - BEAR_SEAT_DEPTH - 0.1])
            cylinder(d = LS_BEAR_OD + 0.5, h = BEAR_SEAT_DEPTH + 1);

        // 6× M5 bottom bolt circle (adapter plate)
        for (a = [0, 60, 120, 180, 240, 300])
            rotate([0, 0, a])
                translate([120, 0, -0.1]) {
                    cylinder(d = 5.5, h = 10);
                    cylinder(d = 10, h = 5.5);  // countersink
                }

        // Az NEMA17 motor pocket (rear)
        translate([0, OD / 2 - WALL + 0.1, H * 0.35]) {
            rotate([90, 0, 0]) {
                cube([NEMA17_W, NEMA17_W, NEMA17_D + 6], center = true);
                for (x = [-1, 1], y = [-1, 1])
                    translate([x * 15.5, y * 15.5, -NEMA17_D / 2 - 4])
                        cylinder(d = 3.4, h = 10);
                cylinder(d = 24, h = NEMA17_D + 12, center = true);
            }
        }

        // Enlarged electronics bay (Arduino Mega 2560: 101×53mm)
        translate([ID / 2 - 62, -30, 6])
            cube([56, 100, 56]);

        // Slip-ring cable chase (centre, vertical) —
        // panel motor cables route through dome centre to stay tidy
        // as dome rotates
        translate([-4, -4, -0.1])
            cube([8, 8, H + 1]);

        // Az encoder sensor pocket (right side)
        translate([OD / 2 - 9, -14, H - 18])
            cube([10, 10, 20]);

        // Friction drive rail (smooth rim strip, for rubber wheel option)
        // Just a smooth arc — no feature needed, it IS the outer surface

        // Ventilation slots
        for (a = [45, 135, 225, 315])
            rotate([0, 0, a])
                translate([OD / 2 - WALL / 2, -22, H * 0.3])
                    cube([WALL + 3, 44, 28], center = true);

        // Cable exit (front, low — scope USB-C)
        translate([0, -(OD / 2 - 1), 20])
            rotate([90, 0, 0])
                hull() {
                    translate([-8, 0, 0]) cylinder(d = 8, h = WALL + 3);
                    translate([ 8, 0, 0]) cylinder(d = 8, h = WALL + 3);
                }
    }
}

base_ring_v3();
