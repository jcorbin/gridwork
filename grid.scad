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
      if (next_height > 0 && next_i < len(steps)) {
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
      "up", // remaining height == height - 4.65 == height - 0.7 - 1.8 - 2.15
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

// Conctructs a grid baseplate with a certain number of cell rows and columns.
module grid_baseplate(
  n,
  wall = 4, // TODO what's typical default
  lift = 0, // TODO what's typcial default? depends on magnets?
  anchor=CENTER, spin=0, orient=UP
) {

  $grid_cols = is_list(n) ? n[0] : n;
  $grid_rows = is_list(n) ? n[1] : n;

  lip_height = 4.65;

  size=[
    $grid_cols * $grid_unit * $grid_cell_size + 2*wall,
    $grid_rows * $grid_unit * $grid_cell_size + 2*wall,
    lip_height + lift
  ];

  cell_center = [0, 0, -size.z] - [$grid_cols+1, $grid_rows+1]/2 * $grid_unit * $grid_cell_size;

  attachable(size=size, anchor=anchor, spin=spin, orient=orient,
    anchors = [
      for (col = [1:$grid_cols])
      for (row = [1:$grid_rows])
      let (
        name = str("cell_",col,"_",row),
        pos = [
          col * $grid_unit * $grid_cell_size,
          row * $grid_unit * $grid_cell_size,
          0 // FIXME Z value here seems ineffective, attachments end up centered no matter what
        ] + cell_center
      ) named_anchor(name, pos)
    ]
  ) {

    diff() cuboid(
      size=size,
      rounding=$grid_rounding,
      edges="Z"
    ) {
      tag("remove")
      grid_copies(
        n=[$grid_cols, $grid_rows],
        spacing=$grid_unit * $grid_cell_size
      )
      attach(BOTTOM, TOP, overlap=lip_height+$eps+lift)
      grid_base_profile(
        size=$grid_unit * $grid_cell_size,
        height=lip_height+2*$eps
      );
    }

    children();
  }
}

grid_baseplate([4, 3]) {

  show_anchors();

  // NOTE: maybe attach bins with overlap=-$grid_tolerance

  // hf = (41.5-2.95)/2;
  //   left(hf/2) back(hf/2)
  //   down(4.65/2) // FIXME whhy
  //   cuboid([hf, hf, 0.1], rounding=0.8, edges="Z");

  attach("cell_1_1", BOTTOM)
    down(4.65/2) // FIXME why
    #render()
    grid_bin_profile(height=3*$grid_unit);

  attach("cell_4_3", BOTTOM)
    down(4.65/2) // FIXME why
    #render()
    grid_bin_profile(height=3*$grid_unit);

}

// TODO block -- a body with feet and a lip
// TODO baseplate -- base, maybe body, with additional features (weights, mangets, screws, connectors, surrounding material, tunnels, etc)
// TODO cup -- a block with a void

// TODO grid cell distributor
// TODO grid cell movement?
// TODO grid (cell) corner distributor
// TODO grid (cell) line distributor -- can this just be an offset of the regular cell dist?
