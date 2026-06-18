# VGA Sync Combiner for Audi RNS-E, 74HCT86 based


<p align="center">
  <img src="docs/images/pcb.png" alt="PCB" width="1200">
</p>


This project contains a small KiCad PCB for converting a VGA-style RGBHV signal into an RGBS signal suitable for the RGB video input of an Audi RNS-E navigation unit.

The board was designed for use with HDMI-to-VGA adapters or similar VGA/RGBHV sources. It passes the red, green and blue video signals through and combines the separate horizontal and vertical sync signals into one composite sync signal.

The circuit is based on the VGA to RGB+CSYNC adapter by Tomi Engdahl. The PCB is not a direct 1:1 copy of the original TTL output circuit. It adapts the basic 74HCT86 sync-combiner concept for this specific RNS-E use case, including a series resistor on the C-Sync output and practical connector/power options.

## Purpose

The Audi RNS-E RGB input expects RGBS video, while common VGA sources output RGBHV. This board converts the sync part from RGBHV to RGBS by combining H-Sync and V-Sync into one C-Sync signal. The RGB video lines are routed directly through the PCB.


## PCB

The PCB is designed to be hand-solder friendly. It uses larger SMD packages where practical, mainly 1206 passives and an SOIC-14 logic IC. The layout is intended for manual assembly rather than automated production.

The capacitors are MLCC parts, so they are non-polarized and can be soldered in either orientation. This avoids polarity mistakes during manual assembly.

Power for the logic IC can be selected by jumper:

| Jumper source    | Description           |
| ---------------- | --------------------- |
| VGA +5V          | Via VGA Pin 9         |
| USB-C +5V        | Via USB-C connector   |
| External JST +5V | Via external 5V input |

**Only one jumper position and one 5V power source must be used at a time. Do not connect multiple 5V sources simultaneously.**

The external JST input is intended as an optional 5V supply. Its polarity is marked directly on the PCB. Check polarity before applying power.


## Video Source / HDMI to VGA Adapter

The board expects a VGA/RGBHV input signal. When using a Raspberry Pi or similar HDMI source, an HDMI-to-VGA adapter or cable is required.

Depending on the Raspberry Pi version, this may be a full-size HDMI, Mini HDMI or Micro HDMI to VGA adapter/cable.

For the tested setup, a Raspberry Pi with Micro HDMI output was used together with a Twozoh Micro HDMI to VGA cable, 1 m.

Reference: [Twozoh Micro HDMI to VGA cable](https://www.amazon.de/Twozoh-Geflochten-Micro-HDMI-unterst%C3%BCtzt-kompatibel/dp/B0CC9CVRDV)

# Optional EDID installer

This repository also includes an optional `install_edid.sh` script for the Audi RNS-E Raspberry Pi display setup.

The script can install/test EDID files or apply custom `800x480` HDMI timings. It is mainly intended for experimenting with the RNS-E RGB/RGBS video input and different HDMI/VGA or scaler setups.

I have included two `800x480` EDID files for the 193 / 2010 RNS-E:

```text
Karmannsport_RNSE_EDID.bin
pcbbc_Rpi_RNSE_800x480i_EDID.bin
```

## Audi RNS-E Connection

The board was made for an Audi RNS-E RGBS input setup. The RGB and C-Sync output can be wired to the corresponding RNS-E AV/RGB connector pins.
See the [Audi RNS-E pinout](docs/images/rns-e_pinout.jpg) for the connector reference.


## Case

A matching 3D-printable case is included. The case is intended to protect the PCB and make the adapter easier to install in a vehicle or cable harness.

<p align="center">
  <img src="docs/images/case.png" alt="3D printable case" width="1200">
</p>

The case files are located in:

```text
3d_print_case/
├─ vga_sync_combiner.3mf
├─ vga_sync_combiner.stl
└─ 3d_models/
   ├─ vga_sync_combiner_case.step
   └─ vga_sync_combiner_with_all_pcb_parts.step
```


## Repository structure

```text
/
├─ 3d_print_case/
│  ├─ 3d_models/
│  ├─ vga_sync_combiner.3mf
│  └─ vga_sync_combiner.stl
├─ bom/
│  ├─ bom_vga_sync_combiner_for_audi_rns-e_complete.csv
│  └─ bom_vga_sync_combiner_for_audi_rns-e_assembly_service.csv
├─ docs/
│  └─ images/
├─ edid_installer/
│  ├─ edid/
│  │  ├─ Karmannsport_RNSE_EDID.bin
│  │  └─ pcbbc_Rpi_RNSE_800x480i_EDID.bin
│  └─ install_edid.sh
├─ kicad_files/
│  ├─ 3dmodels/
│  ├─ gerber_to_order/
│  │  ├─ vga_sync_combiner_for_audi_rns-e_31.0x31.0mm_for_Default.zip
│  │  ├─ vga_sync_combiner_for_audi_rns-e_31.0x31.0mm_for_Elecrow.zip
│  │  ├─ vga_sync_combiner_for_audi_rns-e_31.0x31.0mm_for_FusionPCB.zip
│  │  ├─ vga_sync_combiner_for_audi_rns-e_31.0x31.0mm_for_JLCPCB.zip
│  │  └─ vga_sync_combiner_for_audi_rns-e_31.0x31.0mm_for_PCBWay.zip
│  ├─ vga_sync_combiner_for_rns-e_footprints.pretty/
│  ├─ vga_sync_combiner_for_rns-e_symbols.kicad_sym
│  ├─ vga_sync_combiner_for_audi_rns-e.kicad_pro
│  ├─ vga_sync_combiner_for_audi_rns-e.kicad_sch
│  ├─ vga_sync_combiner_for_audi_rns-e.kicad_pcb
│  └─ vga_sync_combiner_for_audi_rns-e.kicad_prl
└─ README.md
````

The BOM is located at:

```text
kicad_files/vga_sync_combiner_for_audi_rns-e.csv
```

The BOM also includes parts that are not mounted directly on the PCB, such as cables, crimp contacts, connector housings and jumper/shunt parts. It is therefore intended as a complete project BOM, not necessarily as a direct assembly BOM for PCB assembly services.

## Notes

This board is intended for experimental/custom RNS-E video input builds. It is not an official Audi product and has no relation to Audi.

The original Engdahl circuit is a TTL-level sync combiner. This PCB keeps the 74HCT86-based sync-combiner principle, but the output stage is adapted for this project. Depending on the target device, video source and wiring, the C-Sync output resistor may need adjustment.


## Credits

The sync-combining logic is based on the original [VGA to RGB + composite sync converter](https://www.epanorama.net/circuits/vga2rgbs.html) circuit by Tomi Engdahl, 1993–1996.

The included PCB adapts the concept for an Audi RNS-E RGBS input use case.

<p align="center">
  <img src="/docs/images/vga2rgbs_ttl.png" alt="Original Engdahl VGA to RGBS schematic" width="1200">
</p>
