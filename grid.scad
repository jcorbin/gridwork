include <BOSL2/std.scad>

$fa = 4;
$fs = 0.2;

$eps = 0.01;

$grid_unit = 7;         // Gridfinity unit
$grid_cell_size = 6;    // Gridfinity cells are 6u = 42mm
$grid_tolerance = 0.25; // Gridfinity spec: 0.25mm tolerance betwen bin and base ()
$grid_rounding = 4;     // Gridfinity spec: 4mm rounding radius (8mm diameter)

// grid_profile recursively builds a stepped base profile for a grid block.
// Its overall geometry is prismoidal, and each recursive step is a prismoid.
module grid_profile(
  steps,
  size,
  height,
  inset = 0,
  step_i = 0,
  anchor=CENTER,
  spin=0,
  orient=UP
) {

  // NOTE: a more common functional idiom maybe to pass a tail list along when we recurse,
  //       ala steps = [for (i = [1:len(steps)]) steps[i]],
  //       but recursing along the lines of step_i+1 allows us to provide more useful assertion messages.

  step =
    is_num(steps[step_i]) ? [steps[step_i], steps[step_i]]
    : steps[step_i] == "out" ? [inset, inset]
    : steps[step_i] == "up" ? [0, height]
    : steps[step_i];

  assert(
    is_list(step) &&
    is_num(step[0]) &&
    is_num(step[1]),
    str("invalid grid_profile step_", step_i));

  in = step[0];
  assert(
    in <= inset,
    str("grid_profile step_", step_i, "[0] exceeds available inset:", in, ">", inset));

  up = step[1];
  assert(
    up <= height,
    str("grid_profile step_", step_i, "[1] exceeds available height:", up, ">", height));

  next_i = step_i + 1;
  next_inset = inset - in;
  next_height = height - up;

  w = size - 2*inset;
  w2 = size - 2*next_inset;

  attachable(
    size=[w, w, height],
    size2=[size, size],
    anchor=anchor, spin=spin, orient=orient) {

    down(height/2) prismoid(
      w,
      w2,
      rounding1=$grid_rounding - inset,
      rounding2=$grid_rounding - next_inset,
      h=next_i < len(steps) ? up + $eps : up
    )
      if (next_i < len(steps)) {
        attach(TOP, BOTTOM, overlap=$eps)
        grid_profile(
          steps = steps,
          size = size,
          step_i = next_i,
          height = next_height,
          inset = next_inset
        );
      } else {
        assert(next_height == 0, str("unused grid_profile height:", height));
        assert(next_inset == 0, str("unused grid_profile inset:", inset));
      }

    children();
  }

}

// The step profile to subtract from a baseplate
module grid_base_profile(
  size=$grid_unit * $grid_cell_size,
  height=$grid_unit,
  anchor=CENTER, spin=0, orient=UP
) {
  grid_profile(
    [
      // TODO can these be computed from $grid_unit?
      0.7,
      [0, 1.8],
      "out", // remaining inset == 2.15
      "up", // remaining height == 7 - 4.65 == 7 - 0.7 - 1.8 - 2.15
    ],
    size = size,
    inset = 2.85,
    height = height,
    anchor=anchor, spin=spin, orient=orient)
    children();
}

// The step profile for a bin's base
module grid_bin_profile(
  size=$grid_unit * $grid_cell_size - 2*$grid_tolerance,
  height=$grid_unit,
  anchor=CENTER, spin=0, orient=UP
) {
  grid_profile(
    [
      // TODO can these be computed from $grid_unit?
      0.8,
      [0, 1.8],
      "out", // remaining inset == 2.15
      "up", // remaining height == 7 - 4.75 == 7 - 0.8 - 1.8 - 2.15
    ],
    size = size,
    inset = 2.95,
    height = height,
    anchor=anchor, spin=spin, orient=orient)
    children();
}

module q1() {
  intersection() {
    cube([21, 21, 7]);
    children();
  }
}

#render() q1()
grid_bin_profile(
  height=3*$grid_unit,
  anchor=BOTTOM
);

q1()
up(7/2)
diff() cuboid(
  size=[
    $grid_unit * $grid_cell_size,
    $grid_unit * $grid_cell_size,
    $grid_unit
  ],
  rounding=$grid_rounding,
  edges="Z"
)
  tag("remove") grid_base_profile(
    size=$grid_unit * $grid_cell_size + 2*$eps,
    height=$grid_unit + $eps
  );

// TODO block -- a body with feet and a lip
// TODO baseplate -- base, maybe body, with additional features (weights, mangets, screws, connectors, surrounding material, tunnels, etc)
// TODO cup -- a block with a void

// TODO grid cell distributor
// TODO grid cell movement?
// TODO grid (cell) corner distributor
// TODO grid (cell) line distributor -- can this just be an offset of the regular cell dist?
