// ============================================================
// Seestar S50 Nano Dome V2 — Shared Parameters
// Printer: Bambu Lab H2S  |  Material: PETG
// Supports: Alt/Az mode + EQ wedge mode (53°N latitude)
// ============================================================

// --- Seestar S50 Body ---
s50_w  = 142.5;   // X width
s50_d  = 130.0;   // Y depth
s50_h  = 257.0;   // Z height (collapsed on tripod base)

// --- EQ Wedge geometry (existing 3D printed wedge, 53°N) ---
// Wedge adds height and tilts scope axis 53° from vertical
LATITUDE    = 53.0;          // degrees N (Stockport)
WEDGE_H     = 90.0;          // wedge stack height mm (measured from tripod top to S50 base)
WEDGE_TILT  = LATITUDE;      // polar axis tilt = latitude

// --- Dome interior clearances ---
// Must clear scope at ALL positions: Az 0-360°, Alt 10-90° (AltAz)
// AND polar-tilted 53°, rotating about RA axis (EQ)
// EQ mode worst case: scope horizontal on one side = needs most lateral clearance
CLEAR_SIDE  = 55;    // generous side clearance for EQ tilt sweep
CLEAR_FRONT = 50;    // front/rear - scope barrel sweeps this in EQ
CLEAR_TOP   = 40;    // above scope top (zenith pointing)

// Interior cavity
inner_w = s50_w + CLEAR_SIDE  * 2;   // 252.5mm
inner_d = s50_d + CLEAR_FRONT * 2;   // 230.0mm

// --- Dome heights ---
// AltAz: just scope height + top clearance
dome_h_altaz = s50_h + CLEAR_TOP;              // 297mm

// EQ: wedge height + scope + extra for tilt sweep
dome_h_eq    = s50_h + WEDGE_H + CLEAR_TOP + 30; // 417mm — split across two shell prints

// V2 uses AltAz dome height; EQ uses same shell with taller base adapter
dome_h = dome_h_altaz;  // 297mm

// --- Shell split ---
SPLIT_Z = 145;   // increased from v1 (130) to give more lower clearance for EQ tilt

// --- Wall thickness ---
WALL  = 4.5;     // slightly thicker than v1 for larger dome
RIB_T = 3.0;
RIB_H = 10.0;

// --- Crown slot (replaces v1 square aperture) ---
// Full-length slot runs front-to-back: scope can point horizon→zenith in any mode
SLOT_W = 80;     // slot width (just wider than S50 barrel)
SLOT_L = inner_d + 20;  // full depth of dome top

// --- Base ring ---
BASE_OD  = max(inner_w, inner_d) + WALL * 2 + 24;  // ~314mm diameter
BASE_H   = 65;

// --- Adapter plate thickness ---
ADAPTER_H = 12;  // swappable adapter plate sits between base ring and tripod/wedge

// --- EQ base extension (raises dome over wedge) ---
EQ_EXT_H = WEDGE_H + 20;  // 110mm tall extension collar

// --- Motor / hardware (unchanged from v1) ---
NEMA17_W   = 42.3;
NEMA17_D   = 47.0;
HINGE_D    = 8;
HINGE_L    = 35;
LS_D       = 8;
LS_NUT_W   = 13;
LS_NUT_H   = 6.5;
SW_W = 12.8; SW_D = 6.4; SW_H = 5.8;

// --- Print settings (Bambu H2S, PETG) ---
// Layer: 0.20mm | Infill: 30% gyroid | Walls: 4 | Top/bottom: 5
// Supports: Tree auto | Brim: 5mm
// Nozzle: 240°C | Bed: 70°C | Fan: 30%

$fn = 72;
