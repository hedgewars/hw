{$INCLUDE "options.inc"}

unit uRust;

interface
uses SDLh, uTypes, uFloat;

const HWEngineFutureLibName = 'hwengine_future';

{$IFNDEF WINDOWS}
  {$linklib hwengine_future}
{$ENDIF}

{$PACKRECORDS C}

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

function create_ai(game_field: TRGameField): TRAI; cdecl; external HWEngineFutureLibName;
procedure ai_clear_team(ai: TRAI); cdecl; external HWEngineFutureLibName;
procedure ai_clear_targets(ai: TRAI); cdecl; external HWEngineFutureLibName;
procedure ai_add_target(ai: TRAI; x, y: LongInt; health: LongInt; radius: Longword; density: single); cdecl; external HWEngineFutureLibName;
procedure ai_add_team_hedgehog(ai: TRAI; gear: PGear; ammo_counts: PAmmoCounts); cdecl; external HWEngineFutureLibName;
procedure ai_think(ai: TRAI); cdecl; external HWEngineFutureLibName;
function ai_have_plan(ai: TRAI): boolean; cdecl; external HWEngineFutureLibName;
procedure ai_get_action(ai: TRAI; gear: PGear; var action: shortstring); cdecl; external HWEngineFutureLibName;
procedure dispose_ai(ai: TRAI); cdecl; external HWEngineFutureLibName;

function hwf_new(numerator: LongInt; denominator: LongWord): HWFloat; cdecl; external HWEngineFutureLibName;
function hwf_raw(is_negative: boolean; value: QWord): HWFloat; cdecl; external HWEngineFutureLibName;
function hwf_to_f64(number: HWFloat): double; cdecl; external HWEngineFutureLibName;
function hwf_op_plus(n1, n2: HWFloat): HWFloat; cdecl; external HWEngineFutureLibName;
function hwf_op_minus(n1, n2: HWFloat): HWFloat; cdecl; external HWEngineFutureLibName;
function hwf_op_mul(n1, n2: HWFloat): HWFloat; cdecl; external HWEngineFutureLibName;
function hwf_op_div(n1, n2: HWFloat): HWFloat; cdecl; external HWEngineFutureLibName;
function hwf_op_lt(n1, n2: HWFloat): boolean; cdecl; external HWEngineFutureLibName;
function hwf_op_gt(n1, n2: HWFloat): boolean; cdecl; external HWEngineFutureLibName;
function hwf_op_eq(n1, n2: HWFloat): boolean; cdecl; external HWEngineFutureLibName;
function hwf_is_zero(value: HWFloat): boolean; cdecl; external HWEngineFutureLibName;
function hwf_is_negative(value: HWFloat): boolean; cdecl; external HWEngineFutureLibName;
function hwf_op_neg(value: HWFloat): HWFloat; cdecl; external HWEngineFutureLibName;
function hwf_op_mul_int(n1: HWFloat; n2: LongInt): HWFloat; cdecl; external HWEngineFutureLibName;
function hwf_op_div_int(n1: HWFloat; n2: LongInt): HWFloat; cdecl; external HWEngineFutureLibName;
function hwf_to_str(value: HWFloat): ShortString; cdecl; external HWEngineFutureLibName;
function hwf_round(value: HWFloat): Int64; cdecl; external HWEngineFutureLibName;
function hwf_abs(value: HWFloat): HWFloat; cdecl; external HWEngineFutureLibName;
function hwf_sqr(value: HWFloat): HWFloat; cdecl; external HWEngineFutureLibName;
function hwf_sqrt(value: HWFloat): HWFloat; cdecl; external HWEngineFutureLibName;
function hwf_distance(x, y: HWFloat): HWFloat; cdecl; external HWEngineFutureLibName;
function hwf_sqr_distance(x, y: HWFloat): HWFloat; cdecl; external HWEngineFutureLibName;
function hwf_sign_as(num, signum: HWFloat): HWFloat; cdecl; external HWEngineFutureLibName;
function hwf_with_sign(num: HWFloat; is_negative: boolean): HWFloat; cdecl; external HWEngineFutureLibName;
function hwf_signum(r: HWFloat): LongInt; cdecl; external HWEngineFutureLibName;
function hwf_min_positive(): HWFloat; cdecl; external HWEngineFutureLibName;

function hedgehog_step(game_field: TRGameField; gear: PGear): boolean; cdecl; external HWEngineFutureLibName;

function gear_checksum(gear: PGear): Longword; cdecl; external HWEngineFutureLibName;

implementation

end.

