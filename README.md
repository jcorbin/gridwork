# Gridwork -- Grid(finity) BOSL2 Framwork

This is my own take at a from scratch rebuild of gridfinity withing BOSL2.

## Status: explorative developement, doesn't even have a completed bin or baseplate yet

- [x] basic grid stepped profile
- [ ] base plate grid ; WIP
  - [x] basic attachable baseplate mostly works...
  - [ ] ... but the attachment point Z values aren't still slightly off
- [ ] solid blank bin blocks
- [ ] magnet holes
- [ ] screw holes
- [ ] printable hole remedy
- [ ] scalability to different grid metrics

## Scope: make a library, not user models

The target audience of this repository is (eventually) other OpenSCAD gridfinity developers,
wanting a simpler base library and/or something that's BOSL2 native,
as a jumping off point to create user facing models.

This repository **does not** aspire to provide customizable user friendly models like [kennetek] or [vector76].

[kennetek]: https://github.com/kennetek/gridfinity-rebuilt-openscad
[vector76]: https://github.com/vector76/gridfinity_openscad
