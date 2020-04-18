// FilamentChip.scad
//
// 19 Feb 2020 <drifkind@acm.org>
//
// Copyright (c) 2020 David Rifkind. Licensed under Creative Commons
// Attribution-NonCommercial 3.0 Unported (CC BY-NC 3.0) license or any
// future version. For details see:
//   <https://creativecommons.org/licenses/by-nc/3.0/>
//
// Revision history and latest version:
//   <https://github.com/drifkind/FilamentChip/>
//
// Produce a 3D printer filament sample chip. (Or resin or other medium,
// I guess.)
//

/* Parameters */

/* [Basics] */
// Width of chip
width = 25; // [1:1000]
// Height of chip
height = 45; // [1:1000]
// Treatment of label
label_treatment = "relieve"; // ["emboss":Embossed, "engrave":Engraved, "relieve":Relieved]
// Label text
caption1 = "CHIP";
// Second line (optional)
caption2 = "";
// Compress or stretch label (percent)
label_width_factor = 100; // [1:1:1000]
// Expand chip if label is too long
expandable = false;
// Binder hole
binder_hole = true;
// Clip corner
clip_corner = true;

/* [Shape] */
// Thickness of chip
thickness = 2; // [0.1:0.1:100]
// Corner radius
corner_radius = 2; // [0.1:0.1:100]
// Relieved border width
border_width = 1; // [0.1:0.1:100]

/* [Label] */
// Font height
label_size = 5; // [0.1:0.1:100]
// Font name
label_font = "Arial Narrow:style=Bold";
// Distance from bottom of chip
label_baseline = 4; // [0.1:0.1:100]
// Padding at sides when chip is expandable
label_padding = 2; // [0.1:0.1:100]
// Height/depth of label
label_thickness = 1; // [0.1:0.1:100]

/* [Binder Hole] */
// Hole location (only if basics/expandable is off)
hole_location = -1; // [-1:Left, 0:Center, +1:Right]
// Hole diameter
hole_diameter = 5; // [0.1:0.1:100]
// Distance from edge of chip
hole_padding = 2; // [0.1:0.1:100]

/* [Clip Corner] */
// Corner to clip
which_corner = 0; // [-1:Left, 0:Opposite Hole, 1:Right]
// Amount to clip
clip_size = 7; // [0.1:0.1:100]

/* [System] */
// Curve smoothness
$fn=100;

module end_of_header() {}

/* A little too miscellaneous for parameterization */
// Extra caption line spacing
extra_caption_leading = 2;

huge = 1000000;
tiny = 0.001;

chip();

module chip() {
    if (label_treatment == "engrave") {
        difference() {
            blank_chip();
            color("SteelBlue")
            translate([0, label_baseline, thickness-label_thickness]) linear_extrude(label_thickness+tiny) label_text();
        }
    }
    if (label_treatment == "emboss") {
        blank_chip();
        // Clip the label to the edges of the chip, then stretch
        // in Z to protrude above top surface
        color("SteelBlue")
        resize([0, 0, thickness+label_thickness]) {
            intersection() {
                blank_chip();
                translate([0, label_baseline, 0]) linear_extrude(tiny) label_text();
            }
        }
    }
    if (label_treatment == "relieve") {
        difference() {
            blank_chip();
            color("SteelBlue")
            translate([0, 0, thickness-label_thickness]) linear_extrude(label_thickness+tiny)
            difference() {
                // Use hull() to ignore binder hole
                offset(r=-border_width) hull() blank_chip_outline();
                translate([0, label_baseline]) label_text();
            }
        }
    }
}

// blank_chip
//
module blank_chip() {
    color("LightSteelBlue")
    union() {
        linear_extrude(thickness) blank_chip_outline();
    }
}

// blank_chip_outline
//
module blank_chip_outline() {
    difference() { // Binder hole, clip corner
        offset(r=corner_radius) offset(r=-corner_radius) { // Round corners
            if (expandable) {
                union() {
                    // Calculated chip size:
                    intersection() {
                        // Result is a tall rectangle with jagged +Y/-Y
                        // ends and width equal to label plus padding
                        // Note: could 'offset(r=-tiny/2)' to make up
                        // for 'square' width if you are obsessive
                        minkowski() {
                            // hull() to simplify geometry
                            offset(delta=label_padding) hull() label_text();
                            square([tiny, huge], center=true);
                        }
                        // Second term is a wide rectangle with correct
                        // height
                        translate([-huge, 0]) square([huge*2, height]);
                    }
                    // Minimum size:
                    translate([-width/2, 0]) square([width, height]);
                }
            } else { // Not expandable
                translate([-width/2, 0]) square([width, height]);
            }
        } // offset
        if (binder_hole) {
            tx = (width/2 - hole_padding - hole_diameter/2) * (expandable ? 0 : hole_location);
            translate([tx, height-hole_padding-hole_diameter/2]) circle(d=hole_diameter);
        }
        if (clip_corner) {
            which = which_corner ? which_corner : hole_location ? -hole_location : 1;
            tx = (width/2 - clip_size) * which;
            translate([tx, height]) rotate([0, 0, 45-90*which]) square([huge, huge]);
        }
    }
}

// label_text
//
module label_text() {
    scale([label_width_factor/100, 1]) {
        if (caption2 == "") {
            format_text_line(caption1);
        } else {
            union() {
                translate([0, label_size + extra_caption_leading]) format_text_line(caption1);
                format_text_line(caption2);
            }
        }
    }
}

// format_text_line
module format_text_line(line) {
    text(line, size=label_size, font=label_font, halign="center");
}
