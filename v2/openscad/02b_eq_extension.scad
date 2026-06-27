// ============================================================
// Part 02b: EQ BASE EXTENSION COLLAR + ADAPTER PLATE
// Seestar S50 Nano Dome V2 — Bambu H2S | PETG
//
// Two-part solution for EQ mode:
//   02b_collar: Tall cylindrical collar (110mm) that raises
//               the dome shell above the wedge + S50 base.
//               Bottom bolts to 02b_adapter; top bolts to base ring.
//   02b_adapter: Bottom plate that bolts to the wedge top plate
//               (4× M4, 60mm square bolt pattern — matches most
//               DIY printed EQ wedges for S50).
//
// Geometry rationale:
//   Wedge height ~90mm + 20mm margin = 110mm collar
//   At 53°N the scope tilts 53° from vertical on polar axis.
//   The dome shell interior (252×230mm) clears the full RA sweep.
//
// PRINT ORIENTATION:
//   Collar: Upright, open ends up/down. No supports.
//   Adapter: Flat on plate.
// PRINT TIME: Collar ~4h | Adapter ~1h  |  FILAMENT: ~180g + 55g PETG
// ============================================================

include <params.scad>

// ---- EQ COLLAR ------------------------------------------------
module eq_collar() {
    OD = BASE_OD + 8;     // matches base ring flange
    ID = OD - WALL * 2;
    H  = EQ_EXT_H;        // 110mm

    difference() {
        union() {
            // Main collar cylinder
            cylinder(d = OD, h = H);

            // Top flange (mates with base ring bottom flange)
            translate([0, 0, H - 3])
                cylinder(d = OD + 4, h = 5);

            // Bottom flange (mates with eq_adapter)
            cylinder(d = OD + 4, h = 5);

            // Exterior ribs (6 off, structural)
            for (a = [0, 60, 120, 180, 240, 300])
                rotate([0, 0, a])
                    translate([OD / 2 - RIB_T / 2, 0, 0])
                        cube([RIB_T, RIB_H, H], center = false);
        }

        // Interior bore — full open for scope + wedge
        translate([0, 0, -0.1])
            cylinder(d = ID, h = H + 1);

        // --- 6× M5 top bolt circle (base ring) ---
        for (a = [0, 60, 120, 180, 240, 300])
            rotate([0, 0, a])
                translate([120, 0, H - 0.1])
                    cylinder(d = 5.5, h = 10);

        // --- 6× M5 bottom bolt circle (adapter plate) ---
        for (a = [0, 60, 120, 180, 240, 300])
            rotate([0, 0, a])
                translate([120, 0, -0.1])
                    cylinder(d = 5.5, h = 10);
        // M5 countersinks bottom
        for (a = [0, 60, 120, 180, 240, 300])
            rotate([0, 0, a])
                translate([120, 0, -0.1])
                    cylinder(d = 10, h = 5.5);

        // --- Inspection / cable access window (front) ---
        translate([-40, -(OD / 2 + 1), H * 0.3])
            cube([80, WALL + 3, 50]);

        // --- Ventilation slots (sides) ---
        for (a = [90, 270])
            rotate([0, 0, a])
                translate([OD / 2 - WALL / 2, -25, H * 0.35])
                    cube([WALL + 3, 50, 35], center = true);
    }

    // Label
    translate([0, OD / 2 - 1, H / 2])
        rotate([90, 0, 0])
            linear_extrude(1.5)
                text("EQ MODE", size = 6, halign = "center", valign = "center",
                     font = "Liberation Sans:style=Bold");
}

// ---- EQ ADAPTER PLATE -----------------------------------------
module eq_adapter() {
    OD  = BASE_OD + 8;
    H   = ADAPTER_H;   // 12mm

    difference() {
        union() {
            cylinder(d = OD, h = H);
            // Central boss for wedge top plate clearance
            cylinder(d = 80, h = H + 6);
        }

        // --- Wedge top plate bolt pattern ---
        // 4× M4, 60mm square (standard DIY S50 wedge top plate)
        for (x = [-1, 1], y = [-1, 1])
            translate([x * 30, y * 30, -0.1])
                cylinder(d = 4.5, h = H + 10);
        // M4 countersinks
        for (x = [-1, 1], y = [-1, 1])
            translate([x * 30, y * 30, -0.1])
                cylinder(d = 9, h = 5);

        // --- Central clear bore (wedge shaft / scope base) ---
        cylinder(d = 55, h = H + 10);

        // --- 6× M5 top bolt circle (eq_collar) ---
        for (a = [0, 60, 120, 180, 240, 300])
            rotate([0, 0, a])
                translate([120, 0, 2])
                    cylinder(d = 5.5, h = H + 1);

        // --- Lightening pockets ---
        for (a = [30, 90, 150, 210, 270, 330])
            rotate([0, 0, a])
                translate([85, 0, 3])
                    cylinder(d = 28, h = H);
    }

    translate([0, 0, H - 0.4])
        linear_extrude(0.5)
            text("EQ", size = 7, halign = "center", valign = "center",
                 font = "Liberation Sans:style=Bold");
}

// Render both on same plate for preview (export separately for printing)
eq_collar();
translate([OD + 20, 0, 0]) eq_adapter();
