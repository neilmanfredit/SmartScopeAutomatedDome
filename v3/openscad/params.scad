// ============================================================
// Seestar S50 Slewing Dome V3 — Shared Parameters
// Printer: Bambu Lab H2S  |  Material: PETG
// Three-motor: Az rotation + Panel A + Panel B
// ============================================================

// --- Seestar S50 ---
s50_w  = 142.5;
s50_d  = 130.0;
s50_h  = 257.0;

// --- Interior clearances (same generous sizing as V2) ---
CLEAR_SIDE  = 55;
CLEAR_FRONT = 50;
CLEAR_TOP   = 40;

inner_w = s50_w + CLEAR_SIDE  * 2;   // 252.5
inner_d = s50_d + CLEAR_FRONT * 2;   // 230.0
dome_h  = s50_h + CLEAR_TOP;         // 297.0

// --- Dome shell geometry ---
SPLIT_Z   = 145;    // lower/upper shell split height
WALL      = 4.5;    // shell wall thickness
RIB_T     = 3.0;
RIB_H     = 10.0;

OW    = inner_w + WALL * 2;   // ~261mm outer width
OD_s  = inner_d + WALL * 2;   // ~239mm outer depth
LID_H = dome_h - SPLIT_Z;     // ~152mm upper section

// --- Rotation system ---
// Lazy-susan bearing: 300mm OD, 240mm ID, 8mm thick (standard)
LS_BEAR_OD  = 300;
LS_BEAR_ID  = 240;
LS_BEAR_H   = 8;

// Ring gear (on base ring outer rim, for pinion drive option)
RING_GEAR_R  = 160;   // pitch radius mm
RING_GEAR_T  = 72;    // number of teeth (5° per tooth)
RING_MODULE  = 2.0;   // module (tooth size)

// Friction wheel (rubber-tired NEMA17 drive on dome rim)
FRICT_WHEEL_D = 30;   // contact wheel diameter

// Az encoder: 36-slot disk = 10° resolution
ENCODER_SLOTS = 36;
ENCODER_R     = 80;   // disk radius

// --- Panel aperture system ---
// The dome crown has two independent sliding panels (A and B)
// Each driven by M6 lead screw (1.0mm pitch) from NEMA 17
// Panel travel: 0 (closed, covers half slot) to 80mm (fully open)
PANEL_SLOT_W   = 80;   // total slot width when both panels open
PANEL_SLOT_L   = OD_s + 20;  // slot runs full dome depth
PANEL_W        = PANEL_SLOT_W / 2 + 10;  // each panel width with overlap
PANEL_TRAVEL   = 85;   // max travel per panel (mm)

// Panel lead screw (M6 × 1.0mm for fine control)
PANEL_LS_D     = 6;
PANEL_LS_PITCH = 1.0;
// Steps per mm: 1600steps/rev ÷ 1.0mm = 1600 steps/mm
// Full panel travel: 85 × 1600 = 136,000 steps

// --- Base ring ---
BASE_OD = max(inner_w, inner_d) + WALL * 2 + 24;  // ~314mm
BASE_H  = 65;

// Bearing seat ring — base ring top face has a recessed seat
// for the lazy-susan bearing outer race
BEAR_SEAT_DEPTH = 5;   // bearing sits 5mm proud of base ring top

// --- Motors ---
NEMA17_W = 42.3;
NEMA17_D = 47.0;

// --- Hinge (panels hinge at dome crown) ---
HINGE_D = 8;
HINGE_L = 35;

// --- Fasteners ---
LS_D     = 8;    // M8 (not used for panels — panels use M6)
LS_NUT_W = 13;
LS_NUT_H = 6.5;

// --- Print settings ---
// Layer: 0.20mm | Infill: 30% Gyroid | Walls: 4 | Top/bottom: 5
// Supports: Tree auto | Brim: 5mm | Nozzle: 240°C | Bed: 70°C
// Fan: 30% | Machine: BambuLab H2S (320×320mm bed)

$fn = 72;
