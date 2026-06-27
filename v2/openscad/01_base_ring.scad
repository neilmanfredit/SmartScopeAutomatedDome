// ============================================================
// Part 01: UNIVERSAL BASE RING V2
// Seestar S50 Nano Dome V2 — Bambu H2S | PETG
//
// Changes from V1:
//   - Larger diameter to match bigger dome shell (314mm OD vs 232mm)
//   - Bottom face is FLAT — accepts swappable adapter plates
//     (02a_adapter_altaz.scad or 02b_adapter_eq.scad)
//   - 6× M5 bolt circle on bottom flange for adapter plates
//   - Scope locating ribs REMOVED — scope moves freely
//   - Electronics bay enlarged for cleaner wiring
//   - Motor pocket repositioned to rear-centre
//
// PRINT ORIENTATION: Flat on build plate, open top face up
// SUPPORTS: None required
// PRINT TIME: ~6h  |  FILAMENT: ~220g PETG
// H2S bed: 320×320 — part is 314mm dia, ROTATED 45° on plate
//          to fit (diagonal of square = 226mm < 320mm)
//          OR print in two halves and epoxy (see docs)
// NOTE: At 314mm this is tight on the H2S.
//       Bambu Studio: rotate 45° on plate before slicing.
// ============================================================

include <params.scad>

module base_ring_v2() {
    OD = BASE_OD;     // ~314mm
    ID = OD - WALL * 2;
    H  = BASE_H;      // 65mm

    difference() {
        union() {
            // Main cylinder body
            cylinder(d = OD, h = H);

            // Top flange (mates with lower dome half)
            translate([0, 0, H - 3])
                cylinder(d = OD + 8, h = 5);

            // Bottom flange (adapter plate seats here)
            cylinder(d = OD + 8, h = 6);

            // Rear motor boss (external pad, wider than v1)
            translate([0, OD / 2 - WALL - 2, H * 0.35])
                cube([NEMA17_W + 14, NEMA17_D + WALL * 2 + 4, NEMA17_W + 14], center = true);
        }

        // Interior bore
        translate([0, 0, -0.1])
            cylinder(d = ID, h = H + 1);

        // --- 6× M5 bolt circle (bottom, adapter plate) ---
        // 120mm radius bolt circle
        for (a = [0, 60, 120, 180, 240, 300])
            rotate([0, 0, a])
                translate([120, 0, -0.1])
                    cylinder(d = 5.5, h = 10);

        // --- 4× M4 top flange bolts (dome lower) ---
        for (a = [45, 135, 225, 315])
            rotate([0, 0, a])
                translate([OD / 2 + 1, 0, H + 1])
                    cylinder(d = 4.5, h = 8);

        // --- NEMA 17 motor pocket (rear, horizontal) ---
        translate([0, OD / 2 - WALL + 0.1, H * 0.35]) {
            rotate([90, 0, 0]) {
                cube([NEMA17_W, NEMA17_W, NEMA17_D + 6], center = true);
                for (x = [-1, 1], y = [-1, 1])
                    translate([x * 15.5, y * 15.5, -NEMA17_D / 2 - 4])
                        cylinder(d = 3.4, h = 10);
                cylinder(d = 24, h = NEMA17_D + 12, center = true);
            }
        }

        // --- M8 lead screw bore (rear, vertical) ---
        translate([0, OD / 2 - WALL - NEMA17_D - 6, H * 0.5])
            rotate([90, 0, 0])
                cylinder(d = LS_D + 0.5, h = 50);

        // --- Electronics bay (front interior, enlarged) ---
        translate([ID / 2 - 52, -30, 6])
            cube([46, 90, 52]);

        // --- Cable routing channels ---
        for (x = [-3, 3])
            translate([x, -ID / 2 + 2, 12])
                cube([4, WALL + 3, 42]);

        // --- Limit switch pocket (top rear) ---
        translate([0, OD / 2 - WALL / 2, H - SW_H - 3])
            cube([SW_W + 2, WALL + 3, SW_H + 2], center = true);

        // --- Ventilation slots (4 sides) ---
        for (a = [45, 135, 225, 315])
            rotate([0, 0, a])
                translate([OD / 2 - WALL / 2, -18, H * 0.3])
                    cube([WALL + 3, 36, 22], center = true);
    }
}

base_ring_v2();
