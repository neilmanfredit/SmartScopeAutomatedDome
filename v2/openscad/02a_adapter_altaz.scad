// ============================================================
// Part 02a: ADAPTER PLATE — ALT/AZ MODE
// Seestar S50 Nano Dome V2 — Bambu H2S | PETG
//
// Sits between the base ring bottom flange and the S50 tripod.
// In Alt/Az mode the S50 tripod head threads directly into
// this plate's central M10 brass insert (3/8" adaptor).
// The dome then surrounds the scope freely — no contact.
//
// PRINT ORIENTATION: Flat on plate, top face up
// SUPPORTS: None
// PRINT TIME: ~1.5h  |  FILAMENT: ~60g PETG
// ============================================================

include <params.scad>

module adapter_altaz() {
    OD  = BASE_OD + 8;   // matches base ring bottom flange OD
    H   = ADAPTER_H;     // 12mm

    difference() {
        union() {
            cylinder(d = OD, h = H);
            // Central boss (tripod thread area, strengthened)
            cylinder(d = 40, h = H + 8);
        }

        // --- Central M10 brass insert pocket (3/8" tripod thread) ---
        translate([0, 0, -0.1])
            cylinder(d = 10.5, h = 15);

        // --- 6× M5 bolts (matches base ring bolt circle) ---
        for (a = [0, 60, 120, 180, 240, 300])
            rotate([0, 0, a])
                translate([120, 0, -0.1])
                    cylinder(d = 5.5, h = H + 1);

        // --- M5 countersink (so bolt heads sit flush underneath) ---
        for (a = [0, 60, 120, 180, 240, 300])
            rotate([0, 0, a])
                translate([120, 0, -0.1])
                    cylinder(d = 10, h = 5.5);

        // --- Lightening pockets ---
        for (a = [30, 90, 150, 210, 270, 330])
            rotate([0, 0, a])
                translate([75, 0, 3])
                    cylinder(d = 30, h = H);

        // --- Label recess (top face) ---
        translate([-18, -3, H - 1])
            cube([36, 6, 2]);
    }

    // Embossed label
    translate([0, 0, H - 0.4])
        linear_extrude(0.5)
            text("ALT/AZ", size = 5, halign = "center", valign = "center",
                 font = "Liberation Sans:style=Bold");
}

adapter_altaz();
