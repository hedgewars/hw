{$INCLUDE "options.inc"}

unit uRust;

interface
uses SDLh, uTypes;

const HWEngineFutureLibName = 'hwengine_future';

{$IFNDEF WINDOWS}
  {$linklib hwengine_future}
{$ENDIF}

type TRGameField = pointer; 
     TRAI = pointer;


function  create_empty_game_field(width, height: Longword): TRGameField; cdecl; external HWEngineFutureLibName;
procedure get_game_field_parameters(game_field: TRGameField; var width: LongInt; var height: LongInt; var play_width: LongInt; var play_height: LongInt); cdecl; external HWEngineFutureLibName;
procedure dispose_game_field(game_field: TRGameField); cdecl; external HWEngineFutureLibName;

function  land_get(game_field: TRGameField; x, y: LongInt): Word; cdecl; external HWEngineFutureLibName;
procedure land_set(game_field: TRGameField; x, y: LongInt; value: Word); cdecl; external HWEngineFutureLibName;
function  land_row(game_field: TRGameField; row: LongInt): PWordArray; cdecl; external HWEngineFutureLibName;
procedure land_fill(game_field: TRGameField; x, y: LongInt; border, fill: Word); cdecl; external HWEngineFutureLibName;

function  land_pixel_get(game_field: TRGameField; x, y: LongInt): Longword; cdecl; external HWEngineFutureLibName;
procedure land_pixel_set(game_field: TRGameField; x, y: LongInt; value: Longword); cdecl; external HWEngineFutureLibName;
function  land_pixel_row(game_field: TRGameField; row: LongInt): PLongwordArray; cdecl; external HWEngineFutureLibName;

function  generate_outline_templated_game_field(feature_size: Longword; seed, template_type, data_path: PChar): TRGameField; cdecl; external HWEngineFutureLibName;
function  generate_wfc_templated_game_field(feature_size: Longword; seed, template_type, data_path: PChar): TRGameField; cdecl; external HWEngineFutureLibName;
function  generate_maze_game_field(feature_size: Longword; seed, template_type, data_path: PChar): TRGameField; cdecl; external HWEngineFutureLibName;
procedure apply_theme(game_field: TRGameField; data_path, theme_name: PChar); cdecl; external HWEngineFutureLibName;

type TAmmoCounts = array[TAmmoType] of Longword;
     PAmmoCounts = ^TAmmoCounts;
     HedgehogState = record
        x, y: real;
        angle: Longword;
        looking_to_the_right,
        is_moving: boolean;
        end;

function create_ai(game_field: TRGameField): TRAI; cdecl; external HWEngineFutureLibName;
procedure ai_clear_team(ai: TRAI); cdecl; external HWEngineFutureLibName;
procedure ai_add_team_hedgehog(ai: TRAI; x, y: real; ammo_counts: PAmmoCounts); cdecl; external HWEngineFutureLibName;
procedure ai_think(ai: TRAI); cdecl; external HWEngineFutureLibName;
function ai_have_plan(ai: TRAI): boolean; cdecl; external HWEngineFutureLibName;
procedure ai_get_action(ai: TRAI; var current_hedgehog_state: HedgehogState; var action: shortstring); cdecl; external HWEngineFutureLibName;
procedure dispose_ai(ai: TRAI); cdecl; external HWEngineFutureLibName;

implementation

end.

