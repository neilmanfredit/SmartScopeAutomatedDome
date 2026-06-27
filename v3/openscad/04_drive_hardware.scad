// ============================================================
// Part 04: DRIVE HARDWARE PARTS V3
// Seestar S50 Slewing Dome V3 — Bambu H2S | PETG
//
// All on one or two plates depending on bed fit.
// Export each module separately for printing.
//
// 04a — Az Pinion Gear (module 2, 12 teeth — meshes with ring gear)
// 04b — Az Friction Drive Wheel Mount (rubber wheel on dome rim)
// 04c — Az Motor Bracket (holds NEMA17 Az motor in base ring)
// 04d — Panel Motor Bracket (×2, left + right crown motors)
// 04e — M6 Panel Lead Screw Bearing Block (×2)
// 04f — Panel Lead Screw Pivot Arm (×2)
// 04g — Az Encoder Disk (36-slot, IR reflective)
// 04h — IR Sensor Bracket (mounts TCRT5000 at base ring rim)
// 04i — Arduino Mega Tray
// 04j — A4988 Triple Driver Board Tray (3× A4988 side by side)
// 04k — Slip-Ring Spacer (keeps cable tidy through centre bore)
//
// PRINT ORIENTATION: All flat, no supports
// PRINT TIME: ~4h total  |  FILAMENT: ~110g PETG
// ============================================================

include <params.scad>

// ── 04a: Az Pinion Gear ──────────────────────────────────────
// Module 2, 12 teeth. Mounts on NEMA17 shaft (5mm bore).
// Meshes with base ring ring gear (72 teeth).
// Gear ratio: 72:12 = 6:1 → 1600 steps × 6 = 9600 steps/rev
// At 1/8 microstepping: 9600 steps = 1 dome revolution
// Angular resolution: 360° / 9600 = 0.0375° per step
module az_pinion() {
    TEETH = 12;
    MODULE = 2.0;
    PD = MODULE * TEETH;  // pitch diameter = 24mm
    BORE = 5.0;           // NEMA17 shaft

    difference() {
        union() {
            // Gear body (simplified — true involute via post-process
            // or use OpenSCAD MCAD library in production)
            cylinder(d = PD + MODULE * 2, h = 18);
            // Hub
            cylinder(d = BORE + 8, h = 22);
        }
        // Shaft bore
        cylinder(d = BORE + 0.2, h = 24);
        // D-flat (NEMA17 shaft flat)
        translate([BORE / 2 - 0.5 + BORE / 4, -BORE, -1])
            cube([BORE, BORE * 2, 26]);
        // M3 set screw (radial)
        translate([PD / 2 + 2, 0, 10])
            rotate([0, 90, 0])
                cylinder(d = 3.0, h = 10);
        // Tooth profile (simplified as cylinders for printability)
        for (i = [0 : TEETH - 1])
            rotate([0, 0, i * (360 / TEETH)])
                translate([PD / 2 + MODULE * 0.8, 0, -1])
                    cylinder(d = MODULE * 1.8, h = 20);
        // Lightening
        for (i = [0:5])
            rotate([0, 0, i * 60])
                translate([PD / 4, 0, -1])
                    cylinder(d = 5, h = 20);
    }
}

// ── 04b: Friction Drive Wheel Mount ─────────────────────────
// Holds NEMA17 with a 30mm OD rubber-tired wheel
// that presses against the smooth outer rim of the rotating dome.
// Adjustable radial position via slot for preload setting.
module friction_wheel_mount() {
    translate([80, 0, 0]) {
        difference() {
            cube([NEMA17_W + 16, NEMA17_D + WALL * 2, NEMA17_W + 16]);
            // Motor pocket
            translate([NEMA17_W/2+8, -1, NEMA17_W/2+8])
                rotate([-90,0,0]) {
                    cube([NEMA17_W, NEMA17_W, NEMA17_D+4], center=true);
                    cylinder(d=22, h=NEMA17_D+6, center=true);
                    for(x=[-1,1],y=[-1,1])
                        translate([x*15.5,y*15.5,-NEMA17_D/2-3])
                            cylinder(d=3.4,h=8);
                }
            // Adjustment slots (×2, radial)
            for(z=[8, NEMA17_W+8])
                translate([NEMA17_W/2+8, NEMA17_D+WALL, z])
                    rotate([-90,0,0])
                        hull() {
                            translate([-6,0,0]) cylinder(d=5.5,h=12);
                            translate([ 6,0,0]) cylinder(d=5.5,h=12);
                        }
            // Wheel shaft bore (5mm)
            translate([NEMA17_W/2+8,-1,NEMA17_W/2+8])
                rotate([-90,0,0])
                    cylinder(d=5.3,h=NEMA17_D+8);
        }
        // Rubber wheel (30mm OD, 10mm wide — order separately)
        // Print a spacer for the wheel hub:
        translate([NEMA17_W/2+8, -8, NEMA17_W/2+8])
            difference() {
                cylinder(d=FRICT_WHEEL_D, h=10, center=true);
                cylinder(d=5.3, h=12, center=true);
                // D-flat
                translate([5/2-0.5+5/4,-5,-7])
                    cube([5,10,14]);
            }
    }
}

// ── 04c: Az Motor Bracket ────────────────────────────────────
module az_motor_bracket() {
    translate([0, 60, 0]) {
        difference() {
            cube([NEMA17_W+16, 10, NEMA17_W+16]);
            translate([NEMA17_W/2+8,-1,NEMA17_W/2+8])
                rotate([-90,0,0]) {
                    cube([NEMA17_W,NEMA17_W,NEMA17_D+4],center=true);
                    cylinder(d=22,h=NEMA17_D+6,center=true);
                    for(x=[-1,1],y=[-1,1])
                        translate([x*15.5,y*15.5,-NEMA17_D/2-3])
                            cylinder(d=3.4,h=10);
                }
            for(z=[10,NEMA17_W+6])
                translate([NEMA17_W/2+8,12,z])
                    rotate([-90,0,0])
                        hull() {
                            translate([0,-5,0]) cylinder(d=5.5,h=10);
                            translate([0, 5,0]) cylinder(d=5.5,h=10);
                        }
        }
    }
}

// ── 04d: Panel Motor Bracket (×2) ────────────────────────────
module panel_motor_bracket() {
    translate([180, 0, 0]) {
        for(i=[0,1])
            translate([i*(NEMA17_W+20), 0, 0]) {
                difference() {
                    cube([NEMA17_W+12, 8, NEMA17_W+12]);
                    translate([NEMA17_W/2+6,-1,NEMA17_W/2+6])
                        rotate([-90,0,0]) {
                            cube([NEMA17_W,NEMA17_W,NEMA17_D+4],center=true);
                            cylinder(d=22,h=NEMA17_D+6,center=true);
                            for(x=[-1,1],y=[-1,1])
                                translate([x*15.5,y*15.5,-NEMA17_D/2-3])
                                    cylinder(d=3.4,h=8);
                        }
                    for(z=[8,NEMA17_W+4])
                        translate([NEMA17_W/2+6,10,z])
                            rotate([-90,0,0])
                                cylinder(d=4.5,h=10);
                }
            }
    }
}

// ── 04e: M6 Lead Screw Bearing Block (×2) ────────────────────
module panel_bearing_block() {
    translate([0, 90, 0]) {
        for(i=[0,1])
            translate([i*36, 0, 0]) {
                difference() {
                    cube([28, 18, 28]);
                    translate([14,-1,14])
                        rotate([-90,0,0])
                            cylinder(d=PANEL_LS_D+0.4,h=22);
                    // F626ZZ pocket (6mm bore, 19mm OD, 6mm)
                    translate([14,14,14])
                        rotate([-90,0,0])
                            cylinder(d=19.2,h=7);
                    for(x=[4,24])
                        translate([x,-1,5])
                            rotate([-90,0,0])
                                cylinder(d=4.5,h=22);
                }
            }
    }
}

// ── 04f: Panel Lead Screw Pivot Arms (×2) ────────────────────
module panel_pivot_arms() {
    translate([80, 90, 0]) {
        for(i=[0,1])
            translate([i*28, 0, 0]) {
                difference() {
                    union() {
                        cube([18, 10, 36]);
                        translate([9,5,36]) sphere(d=18);
                    }
                    translate([9,-1,9])
                        rotate([-90,0,0])
                            cylinder(d=PANEL_LS_D+0.4,h=14);
                    translate([9,4,9])
                        rotate([-90,30,0])
                            cylinder(d=11.6,h=5.5,$fn=6);
                    translate([9,-1,40])
                        rotate([-90,0,0])
                            cylinder(d=PANEL_LS_D+0.4,h=14);
                }
            }
    }
}

// ── 04g: Az Encoder Disk ─────────────────────────────────────
// 36 reflective/non-reflective slots for TCRT5000 IR sensor
// Mounts on dome lower shell underside hub
module encoder_disk() {
    translate([150, 90, 0]) {
        difference() {
            cylinder(d = ENCODER_R * 2 + 10, h = 3);
            // Centre bore (fits over hub)
            cylinder(d = 28.5, h = 4);
            // 36 slots (alternating black/white = IR trigger)
            for(i=[0:ENCODER_SLOTS-1])
                rotate([0,0,i*(360/ENCODER_SLOTS)])
                    translate([ENCODER_R,0,-0.1])
                        cylinder(d=5,h=4);
            // M3 mount holes (×3)
            for(a=[0,120,240])
                rotate([0,0,a])
                    translate([14,0,-0.1])
                        cylinder(d=3.4,h=4);
        }
    }
}

// ── 04h: IR Sensor Bracket ───────────────────────────────────
// Mounts TCRT5000 reflective sensor on base ring rim
// facing up at the encoder disk slots on dome underside
module ir_sensor_bracket() {
    translate([250, 90, 0]) {
        difference() {
            cube([24, 18, 30]);
            // TCRT5000 pocket (10.2×5.8mm)
            translate([4,4,5])
                cube([10.5,6,26]);
            // M3 screw holes
            for(x=[2,22])
                translate([x,9,-1])
                    cylinder(d=3.4,h=32);
            // M4 mount holes to base ring
            for(y=[4,14])
                translate([12,y,26])
                    rotate([-90,0,0])
                        cylinder(d=4.5,h=20);
        }
    }
}

// ── 04i: Arduino Mega 2560 Tray ──────────────────────────────
// Arduino Mega: 101×53mm
module mega_tray() {
    translate([0, 145, 0]) {
        AM_W=53; AM_L=101;
        difference() {
            cube([AM_W+8, AM_L+8, 8]);
            translate([4,4,3]) cube([AM_W,AM_L,7]);
            // USB-B access
            translate([AM_W/2+4,-1,1.5]) cube([16,8,5]);
            // Power jack access
            translate([AM_W+5,10,1.5]) cube([8,12,5]);
            // Snap tabs
            for(x=[0,AM_W+8]) translate([x,AM_L/2+4,6])
                cylinder(d=3.5,h=5);
        }
    }
}

// ── 04j: Triple A4988 Driver Tray ────────────────────────────
module triple_driver_tray() {
    translate([80, 145, 0]) {
        // 3× A4988 side by side (each 20×15mm footprint)
        D_W=20; D_L=15;
        difference() {
            cube([D_W*3+12, D_L+8, 8]);
            for(i=[0:2])
                translate([4+i*(D_W+2),4,3])
                    cube([D_W,D_L,7]);
            // Label slots
            for(i=[0:2])
                translate([4+i*(D_W+2)+D_W/2,-1,4])
                    cube([8,5,5],center=true);
        }
        // Labels (embossed)
        for(i=[0:2]) {
            labels=["AZ","PA","PB"];
            translate([4+i*(D_W+2)+D_W/2, D_L+8-0.4, 1])
                linear_extrude(0.5)
                    text(labels[i],size=4,halign="center",
                         font="Liberation Sans:style=Bold");
        }
    }
}

// ── 04k: Slip-Ring Spacer ─────────────────────────────────────
// Guides the 3 panel motor cables (6 wires total) through
// the centre bore as the dome rotates. Uses a 12mm OD
// 6-wire slip ring (order separately) or just routes flex cable
// with enough slack for 360° rotation.
module slip_ring_spacer() {
    translate([220, 145, 0]) {
        difference() {
            cylinder(d=22, h=20);
            cylinder(d=12.3, h=21);
            // 3 cable notches
            for(a=[0,120,240])
                rotate([0,0,a])
                    translate([8,0,-1])
                        cube([4,4,22]);
        }
    }
}

// ── Render all ───────────────────────────────────────────────
az_pinion();
friction_wheel_mount();
az_motor_bracket();
panel_motor_bracket();
panel_bearing_block();
panel_pivot_arms();
encoder_disk();
ir_sensor_bracket();
mega_tray();
triple_driver_tray();
slip_ring_spacer();
