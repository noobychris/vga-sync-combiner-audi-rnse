# Audi RNS-E Display / EDID Manager

Small shell script for configuring Raspberry Pi display output for the **Audi RNS-E**.

The script was created for my Audi RNS-E Raspberry Pi project and helps switch between a custom `800x480` HDMI timing mode, forced EDID files, and the original/automatic display configuration.

It modifies:

```text
/boot/firmware/config.txt
/boot/firmware/cmdline.txt
```

## What it does

The script can:

- apply custom `800x480` HDMI timings
- install and force a selected EDID file
- copy EDID files from `/home/pi/edid` to `/lib/firmware/edid`
- add the required EDID firmware entry to the kernel command line
- remove forced EDID and custom timing settings again
- create backups before changing system files
- update initramfs if needed

## Included EDID files

I have included two `800x480` EDID files for the **193 RNS-E / 2010 RNS-E**:

```text
Karmannsport_RNSE_EDID.bin
pcbbc_Rpi_RNSE_800x480i_EDID.bin
```

These files are included as possible options for testing. You still need to check yourself which EDID works correctly with your specific RNS-E version, Raspberry Pi setup, HDMI adapter, scaler, sync combiner, and wiring.

## Important

This script is intended **only for Audi RNS-E display experiments**.

It is not a universal HDMI or EDID configuration tool. You must check yourself which EDID file or display mode is correct for your specific setup.

I have only tested it with:

- Raspberry Pi 4B
- 4 GB RAM version
- Raspberry Pi OS Trixie
- Audi RNS-E
- custom RGB/RGBS video setup

Other setups may behave differently.

## Usage

Place your EDID files in:

```bash
/home/pi/edid
```

Supported file extensions:

```text
.bin
.dat
.edid
```

Make the script executable:

```bash
sudo chmod +x install_edid.sh
```

Run it:

```bash
sudo ./install_edid.sh
```

Select one of the available modes or EDID files from the menu.

Example:

```text
pi@raspberrypi:~ $ sudo ./install_edid.sh

Display/EDID Manager

Config:      /boot/firmware/config.txt
Cmdline:     /boot/firmware/cmdline.txt
EDID source: /home/pi/edid
EDID target: /lib/firmware/edid

Found EDID files in /home/pi/edid:
  - Karmannsport_RNSE_EDID.bin
  - pcbbc_Rpi_RNSE_800x480i_EDID.bin

Options:
  1) 800x480 custom HDMI timings
  2) EDID: Karmannsport_RNSE_EDID.bin
  3) EDID: pcbbc_Rpi_RNSE_800x480i_EDID.bin
  4) Auto/original: remove EDID and custom timings
  q) Cancel

Selection: 2

Backup created:
  /boot/firmware/config.txt.bak.20260618-184710
  /boot/firmware/cmdline.txt.bak.20260618-184710

EDID copied:
  Source: /home/pi/edid/Karmannsport_RNSE_EDID.bin
  Target: /lib/firmware/edid/Karmannsport_RNSE_EDID.bin

Initramfs hook installed:
  /etc/initramfs-tools/hooks/audi-edid

Updating initramfs ...

Enabled: EDID Karmannsport_RNSE_EDID.bin for HDMI-A-1 and HDMI-A-2

Done. Please reboot:
  sudo reboot
```

After selecting a mode, reboot:

```bash
sudo reboot
```

## Disclaimer

This script modifies Raspberry Pi boot configuration files. Use it at your own risk and only if you are able to recover the system manually if the display output stops working.
