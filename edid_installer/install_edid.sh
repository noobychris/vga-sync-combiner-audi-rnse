#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="/boot/firmware/config.txt"
CMDLINE_FILE="/boot/firmware/cmdline.txt"

# Place your EDID files here.
SOURCE_EDID_DIR="/home/pi/edid"

# Linux loads the EDID firmware from here.
TARGET_EDID_DIR="/lib/firmware/edid"

INITRAMFS_HOOK="/etc/initramfs-tools/hooks/audi-edid"
MARK_BEGIN="# BEGIN AUDI_DISPLAY_MODE_MANAGER"
MARK_END="# END AUDI_DISPLAY_MODE_MANAGER"
STAMP="$(date +%Y%m%d-%H%M%S)"

CUSTOM_800X480_BLOCK='hdmi_force_hotplug=1
hdmi_drive=1
hdmi_group=2
hdmi_mode=87
hdmi_timings=800 0 42 22 180 480 0 2 5 15 0 0 0 60 1 16380000 6'

need_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Please run this script with sudo:"
    echo "  sudo $0"
    exit 1
  fi
}

check_files() {
  [[ -f "$CONFIG_FILE" ]] || { echo "Not found: $CONFIG_FILE"; exit 1; }
  [[ -f "$CMDLINE_FILE" ]] || { echo "Not found: $CMDLINE_FILE"; exit 1; }

  mkdir -p "$SOURCE_EDID_DIR"
  mkdir -p "$TARGET_EDID_DIR"
}

read_edids() {
  mapfile -t EDIDS < <(
    find "$SOURCE_EDID_DIR" -maxdepth 1 -type f \
      \( -iname '*.bin' -o -iname '*.dat' -o -iname '*.edid' \) \
      -printf '%f\n' | sort
  )
}

safe_edid_name() {
  local name="$1"
  # The kernel cmdline must not contain spaces in file names.
  # Everything except letters, numbers, dots, underscores and hyphens is replaced with "_".
  echo "$name" | sed -E 's/[^A-Za-z0-9._-]+/_/g'
}

backup_files() {
  cp -a "$CONFIG_FILE" "${CONFIG_FILE}.bak.${STAMP}"
  cp -a "$CMDLINE_FILE" "${CMDLINE_FILE}.bak.${STAMP}"
  echo ""
  echo "Backup created:"
  echo "  ${CONFIG_FILE}.bak.${STAMP}"
  echo "  ${CMDLINE_FILE}.bak.${STAMP}"
}

remove_managed_config_block() {
  sed -i "/^${MARK_BEGIN//\//\\/}$/, /^${MARK_END//\//\\/}$/d" "$CONFIG_FILE"
}

comment_old_hdmi_config_lines() {
  local keys='hdmi_force_hotplug|hdmi_drive|hdmi_group|hdmi_mode|hdmi_timings|hdmi_edid_file|hdmi_edid_filename|hdmi_ignore_edid'
  sed -i -E "/^[[:space:]]*#/{b}; /^[[:space:]]*(${keys})[[:space:]]*=/{s/^/# disabled by display-mode-manager ${STAMP}: /}" "$CONFIG_FILE"
}

remove_forced_cmdline_entries() {
  python3 - "$CMDLINE_FILE" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text().strip()
parts = text.split()

remove_exact = {
    "drm_kms_helper.edid_firmware",
}

remove_prefixes = (
    "drm.edid_firmware=",
    "drm_kms_helper.edid_firmware=",
    "video=HDMI-A-1:",
    "video=HDMI-A-2:",
    "video=HDMI-1:",
    "video=HDMI-2:",
)

cleaned = []
for part in parts:
    if part in remove_exact:
        continue
    if part.startswith(remove_prefixes):
        continue
    cleaned.append(part)

path.write_text(" ".join(cleaned) + "\n")
PY
}

append_config_block() {
  local title="$1"
  local body="$2"
  {
    echo ""
    echo "$MARK_BEGIN"
    echo "# Mode: $title"
    echo "# Created at: $STAMP"
    echo "[all]"
    echo "$body"
    echo "$MARK_END"
  } >> "$CONFIG_FILE"
}

copy_edid_to_target() {
  local original_base="$1"
  local safe_base
  safe_base="$(safe_edid_name "$original_base")"

  local src="${SOURCE_EDID_DIR}/${original_base}"
  local dst="${TARGET_EDID_DIR}/${safe_base}"

  if [[ ! -f "$src" ]]; then
    echo "EDID file not found:"
    echo "  $src"
    exit 1
  fi

  cp -a "$src" "$dst"
  chmod 0644 "$dst"

  echo ""
  echo "EDID copied:"
  echo "  Source: $src"
  echo "  Target: $dst"

  if [[ "$original_base" != "$safe_base" ]]; then
    echo ""
    echo "Note: file name sanitized for the kernel cmdline:"
    echo "  Original: $original_base"
    echo "  Used:     $safe_base"
  fi

  COPIED_EDID_BASE="$safe_base"
}

install_initramfs_edid_hook() {
  if [[ ! -d "/etc/initramfs-tools/hooks" ]]; then
    echo ""
    echo "Note: /etc/initramfs-tools/hooks does not exist."
    echo "Initramfs hook was skipped."
    return 0
  fi

  cat > "$INITRAMFS_HOOK" <<'HOOK'
#!/bin/sh
set -e

PREREQ=""

prereqs() {
  echo "$PREREQ"
}

case "$1" in
  prereqs)
    prereqs
    exit 0
    ;;
esac

if [ -d /lib/firmware/edid ]; then
  mkdir -p "${DESTDIR}/lib/firmware/edid"
  cp -a /lib/firmware/edid/* "${DESTDIR}/lib/firmware/edid/" 2>/dev/null || true
fi
HOOK

  chmod +x "$INITRAMFS_HOOK"
  echo ""
  echo "Initramfs hook installed:"
  echo "  $INITRAMFS_HOOK"
}

warn_executable_disabled_hooks() {
  local bad=0
  local f

  for f in /etc/initramfs-tools/hooks/*.disabled /etc/initramfs-tools/hooks/edid; do
    [[ -e "$f" ]] || continue
    if [[ -x "$f" && "$f" != "$INITRAMFS_HOOK" ]]; then
      if [[ "$bad" -eq 0 ]]; then
        echo ""
        echo "Warning: the following old initramfs hooks are still executable and may block update-initramfs:"
      fi
      echo "  $f"
      bad=1
    fi
  done

  if [[ "$bad" -eq 1 ]]; then
    echo ""
    echo "If update-initramfs fails, disable them, for example with:"
    echo "  sudo chmod -x /etc/initramfs-tools/hooks/edid.disabled"
    echo "  sudo chmod -x /etc/initramfs-tools/hooks/edid"
  fi
}

update_initramfs_if_available() {
  warn_executable_disabled_hooks

  if command -v update-initramfs >/dev/null 2>&1; then
    echo ""
    echo "Updating initramfs ..."
    update-initramfs -u
  else
    echo ""
    echo "Note: update-initramfs was not found."
    echo "EDID is available in $TARGET_EDID_DIR, but the initramfs was not updated."
  fi
}

set_custom_800x480() {
  remove_managed_config_block
  comment_old_hdmi_config_lines
  remove_forced_cmdline_entries
  append_config_block "800x480 custom HDMI timings" "$CUSTOM_800X480_BLOCK"
  echo ""
  echo "Enabled: 800x480 via custom hdmi_timings in config.txt"
}

set_edid() {
  local original_base="$1"

  copy_edid_to_target "$original_base"
  local base="$COPIED_EDID_BASE"

  remove_managed_config_block
  comment_old_hdmi_config_lines
  remove_forced_cmdline_entries

  append_config_block "EDID: $base" $'hdmi_force_hotplug=1\nhdmi_drive=1'

  python3 - "$CMDLINE_FILE" "$base" <<'PY'
import sys
from pathlib import Path

cmdline = Path(sys.argv[1])
base = sys.argv[2]

text = cmdline.read_text().strip()
parts = text.split()

entry = f"drm.edid_firmware=HDMI-A-1:edid/{base},HDMI-A-2:edid/{base}"
parts.append(entry)

cmdline.write_text(" ".join(parts) + "\n")
PY

  install_initramfs_edid_hook
  update_initramfs_if_available

  echo ""
  echo "Enabled: EDID $base for HDMI-A-1 and HDMI-A-2"
}

set_auto_mode() {
  remove_managed_config_block
  comment_old_hdmi_config_lines
  remove_forced_cmdline_entries
  echo ""
  echo "Enabled: Auto/original mode without forced EDID and without custom HDMI timings"
}

print_menu() {
  echo ""
  echo "Display/EDID Manager"
  echo ""
  echo "Config:      $CONFIG_FILE"
  echo "Cmdline:     $CMDLINE_FILE"
  echo "EDID source: $SOURCE_EDID_DIR"
  echo "EDID target: $TARGET_EDID_DIR"
  echo ""
  echo "Found EDID files in $SOURCE_EDID_DIR:"
  if [[ "${#EDIDS[@]}" -eq 0 ]]; then
    echo "  No EDID files found."
    echo "  Place EDIDs there, for example like this:"
    echo "    mkdir -p $SOURCE_EDID_DIR"
    echo "    cp RNSE_EDID.bin $SOURCE_EDID_DIR/"
  else
    local e
    for e in "${EDIDS[@]}"; do
      echo "  - $e"
    done
  fi

  echo ""
  echo "Options:"
  echo "  1) 800x480 custom HDMI timings"

  local i=2
  local edid
  for edid in "${EDIDS[@]}"; do
    printf '  %d) EDID: %s\n' "$i" "$edid"
    ((i++))
  done

  printf '  %d) Auto/original: remove EDID and custom timings\n' "$i"
  echo "  q) Cancel"
  echo ""
}

handle_choice() {
  local auto_option=$(( ${#EDIDS[@]} + 2 ))

  read -rp "Selection: " choice

  if [[ "$choice" == "q" || "$choice" == "Q" ]]; then
    echo "Cancelled."
    exit 0
  fi

  if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
    echo "Invalid selection."
    exit 1
  fi

  if [[ "$choice" -eq 1 ]]; then
    backup_files
    set_custom_800x480
  elif [[ "$choice" -ge 2 && "$choice" -lt "$auto_option" ]]; then
    backup_files
    set_edid "${EDIDS[$((choice-2))]}"
  elif [[ "$choice" -eq "$auto_option" ]]; then
    backup_files
    set_auto_mode
  else
    echo "Invalid selection."
    exit 1
  fi
}

main() {
  need_root
  check_files
  read_edids
  print_menu
  handle_choice

  echo ""
  echo "Done. Please reboot:"
  echo "  sudo reboot"
}

main "$@"
