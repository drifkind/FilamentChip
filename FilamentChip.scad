// FilamentChip.scad
//
// 19 Feb 2020 <drifkind@acm.org>
//
// Copyright (c) 2020 David Rifkind. Licensed under Creative Commons
// Attribution-NonCommercial 3.0 Unported (CC BY-NC 3.0) license or any
// future version. For details see:
//   <https://creativecommons.org/licenses/by-nc/3.0/>
//
// Produce a 3D printer filament sample chip. (Or resin or other medium,
// I guess.)
//

/* Parameters */

/* [Basics] */
// Width of chip
width = 25;
// Height of chip
height = 45;
// Label above or below surface?
incise_label = 0; // [0:Above, 1:Below]
// Label text
caption1 = "CHIP";
// Second line (optional)
caption2 = "";
// Compress or stretch label (percent)
label_width_factor = 100; 
// Expand chip if label is too long
expandable = false;
// Binder hole
binder_hole = true;
// Clip corner
clip_corner = true;

/* [Shape] */
// Thickness of chip
thickness = 2;
// Corner radius
corner_radius = 2;

/* [Label] */
// Font height
label_size = 5;
// Font name
label_font = "Arial Narrow:style=Bold";
// Distance from bottom of chip
label_baseline = 4;
// Padding at sides
label_padding = 2;
// Height/depth of label
label_thickness = 1;

/* [Binder Hole] */
// Hole location (only if basics/expandable is off)
hole_location = -1; // [-1:Left, 0:Center, +1:Right]
// Hole diameter
hole_diameter = 5;
// Distance from edge of chip
hole_padding = 2;

/* [Clip Corner] */
// Corner to clip
which_corner = 0; // [-1:Left, 0:Opposite Hole, 1:Right]
// Amount to clip
clip_size = 7;

/* [System] */
// Curve smoothness
$fn=100;

module end_of_header() {}

/* These are a little too miscellaneous for parameterization */
// Extra caption line spacing
extra_caption_leading = 2;

huge = 1000000;
tiny = 0.001;

chip();

module chip() {
    if (incise_label) {
        difference() {
            blank_chip();
            color("SteelBlue")
            translate([0, label_baseline, thickness-label_thickness]) linear_extrude(label_thickness+tiny) label_text();
        }            
    } else { 
        union() {
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
    }
}

module blank_chip() {
    color("LightSteelBlue")
    linear_extrude(thickness) {
        difference() { // Binder hole, clip corner
            offset(r=corner_radius) offset(r=-corner_radius) { // Round corners
                if (expandable) {
                    union() {
                        // Calculated chip size:
                        intersection() {
                            // First term is a tall rectangle with jagged +Y/-Y
                            // ends and width equal to label plus padding
                            // Note: could 'offset(r=-tiny/2)' to make up
                            // for 'square' width if you are obsessive
                            minkowski() {
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
}

// label_text
//
module label_text()
{
    if (caption2 == "") {
        format_text_line(caption1);
    } else {
        scale([label_width_factor/100, 1]) union() {
            translate([0, label_size + extra_caption_leading]) text(caption1, size=label_size, font=label_font, halign="center");
            text(caption2, size=label_size, font=label_font, halign="center");
        }
    }
}

// format_text_line
module format_text_line(line)
{
    text(line, size=label_size, font=label_font, halign="center");
}