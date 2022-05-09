import save_monger
import common
import std/os
import std/strformat
import std/parseopt
import std/strutils

when defined windows:
  const appdata = getEnv("APPDATA")
  let schematics_path = appdata / r"godot\app_userdata\Turing Complete\schematics"
elif defined Linux:
  let schematics_path = expandTilde("~/.local/share/godot/app_userdata/Turing Complete/schematics")
elif defined macosx:
  let schematics_path = expandTilde("~/Library/Application Support/Godot/app_userdata/Turing Complete/schematics")
else:
  echo "Unknown OS", hostOS
  let schematics_path = ""

var levels: seq[string]
var schematics: seq[(string, string)]
var files: seq[string]
var in_place: bool = false
var no_backup: bool = false
var process_all: bool = false
var no_write: bool = false
var verbosity: int = 0

proc fix_component(component: var parse_component): bool=
  if (component.custom_string == "" or
      component.setting_1 != 0 or
      component.setting_2 != 0 or
      component.custom_string == "0"):
    return false
  case component.kind:
    of Counter8, Counter16, Counter32, Counter64, Constant8, Constant16, Constant32, Constant64, Hdd:
      if verbosity > 1:
        echo "Fixing Component: ", component
      component.setting_1 = (uint64) parse_int(component.custom_string)
      return component.setting_1 != 0
    of CheapRam, CheapRamLat, FastRam, Rom, DualLoadRam:
      if verbosity > 1:
        echo "Fixing Component: ", component
      let splits = component.custom_string.split(':')
      component.setting_1 = (uint64) splits[0].parse_int()
      component.setting_2 = (uint64) splits[1].parse_int()
      return component.setting_1 != 0 or component.setting_2 != 0
    else:
      discard
  return false

proc write_usage() =
  stderr.write(fmt"Usage: {getAppFilename()} [--in-place [--no-backup]] [--all] [--dry]  [--level LEVEL_NAME [--schematic SCHEMATIC_NAME]*]* [circuit_path ...]{'\n'}")

proc write_help() =
  write_usage()

proc shorten(file: string): string=
  if file.starts_with(schematics_path):
    return "%TC%"  & file[len(schematics_path).. ^1]
  else:
    return file

var cmd_args = init_opt_parser(short_no_val={'h', 'v'}, long_no_val= @["in-place", "no-backup", "all", "help", "dry", "verbose"])


for kind, key, val in cmd_args.getopt():
  case kind:
    of cmd_end: do_assert(false)
    of cmd_short_option, cmd_long_option:
      case key:
        of "h", "help":
          writeHelp()
          quit()
        of "l", "level":
          levels.add(val)
        of "s", "schematic":
          if levels == @[]:
            stderr.write_line("Can't provide --schematic without a --level preceding it")
          schematics.add((level: levels[^1], schematic: val))
        of "in-place":
          in_place = true
        of "no-backup":
          no_backup = true
        of "all":
          process_all = true
        of "dry":
          no_write = true
        of "v", "verbosity":
          verbosity += 1
        else:
          stderr.write_line(fmt"Unknown option {key}")
          quit()
    of cmd_argument:
      files.add(key)
if levels == @[] and files == @[] and not process_all:
  writeHelp()
  quit()

if verbosity > 5:
  echo "Schematics Path: ", schematics_path

if process_all:
  if levels != @[]:
    for level in levels:
      for file in walkDirRec(schematics_path / level ):
        if file.ends_with("circuit.data"):
          files.add(file)
  else:
    for file in walkDirRec(schematics_path):
      if file.ends_with("circuit.data"):
        files.add(file)

for file in files:
  if verbosity > 0:
    echo "Processing      : ", file.shorten
  let data = file.file_get_bytes()
  var state = parse_state(data)
  var any_changed = false
  for component in state.components.mitems():
    if component.fix_component():
      any_changed = true
  if any_changed:
    var out_name: string
    let data = state_to_binary(
            state.save_version, state.components, state.wires,
            state.gate, state.delay, state.menu_visible,
            state.clock_speed, state.description, state.camera_position,
            state.player_data
    )
    if in_place:
      out_name = file
      if not no_backup:
        if verbosity > 0:
          echo "Making Backup to: ", file.shorten & ".bck"
        if not no_write:
          move_file(file, file & ".bck")
    else:
      out_name = file & ".out"
    echo "Writing to      : ", out_name.shorten
    if not no_write:
      var file = open(out_name, fmWrite)
      discard file.write_bytes(data, 0, data.len)
      file.close()
