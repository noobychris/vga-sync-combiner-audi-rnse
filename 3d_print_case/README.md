# 3D Printed Case

<p align="center">
  <img src="/docs/images/case.png" alt="3D printable case" width="1200">
</p>


This folder contains a 3D-printable case for the VGA RGBHV to RGBS / C-Sync Combiner PCB.

The case is designed to hold the PCB and protect it during installation or use in a cable harness. It uses two M2 heat-set inserts and two M2 countersunk screws to close the case.

## Print Material

PETG, ABS or ASA are recommended for the case. PLA may work for testing, but is not recommended for use in a car or other warm environments.

For vehicle use, ABS or ASA is preferred because of the higher temperature resistance. PETG is a reasonable alternative if the case is not exposed to high temperatures.

## Files

```text
3d_print_case/
├─ vga_sync_combiner_for_rns-e_case.3mf
├─ vga_sync_combiner_for_rns-e_case.stl
└─ 3d_models/
   ├─ vga_sync_combiner_for_rns-e.step
   ├─ vga_sync_combiner_for_rns-e_pcb.step
   └─ vga_sync_combiner_for_rns-e_with_all_pcb_parts.step
```

## Required Hardware

| Quantity | Part                  | Notes                |
| :------- | :-------------------- | :------------------- |
| 2        | M2 heat-set inserts   | Maximum length: 7 mm |
| 2        | M2 countersunk screws | Length: 8–12 mm      |

## Optional Light Pipe

An optional light pipe can be added for the onboard LED.

| Quantity | Part                           | Notes                               |
| :------- | :----------------------------- | :---------------------------------- |
| 1        | Plexiglass / acrylic round rod | 2 mm diameter, approx. 12 mm length |

The hole in the case is designed with a diameter of 2.25 mm. This is intentional, because the used acrylic rod was not perfectly consistent in diameter and was slightly larger than 2.00 mm in some areas.

If your rod fits too loosely or too tightly, adjust the hole or rod diameter accordingly.

## Assembly Notes

After soldering the VGA connector, the ground/shield feet of the VGA connector may need to be shortened slightly. Otherwise they may interfere with the case fit.

<p align="center">
  <img src="/docs/images/cut.png" alt="PCB" width="600">
</p>

Before closing the case, check that:

- the PCB sits flat in the case
- the VGA connector does not touch the case unexpectedly
