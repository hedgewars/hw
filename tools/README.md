# tools/ directory

This directory contains various tools for HW development.

To learn more about each individual tool, open its source file in a text editor,
it often contains a brief comment at the top.

## List of tools (excerpt)

### Files
* `update_locale_files.sh`: Update locale files
* `check_engine_locale_files.sh`: Check the engine locale files for missing translations and problems
* `hwmap2lua.sh`: Convert HWMAP files to Lua code for usage in missions
* `create_dmg.sh`: Generate a .dmg file (relevant for Mac)
* `dmg_pkg_install.sh`: Downloads and install a .dmg from a URL (relevant for Mac)
* `docgen.sh`: Generate QTfrontend documentation with Doxygen (it's not very good)

### Directories
* `hwmapconverter`: C++ application to edit HWMAP files in text form
* `pas2c`: Pascal-to-C rewriter. Used when hwengine is built as C application with `BUILD_ENGINE_C=1`
* `old`: Very outdated stuff that needs re-examination and possibly deletion
