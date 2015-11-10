(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *)

{$INCLUDE "options.inc"}

unit PNGh;
interface

uses png;


{$IFDEF DARWIN}
    {$linklib png}
{$ENDIF}

const
    // Constants for libpng, they are not defined in png unit.
    // We actually do not need all of them.

    // These describe the color_type field in png_info.
    // color type masks
    PNG_COLOR_MASK_PALETTE = 1;
    PNG_COLOR_MASK_COLOR   = 2;
    PNG_COLOR_MASK_ALPHA   = 4;

    // color types.  Note that not all combinations are legal
    PNG_COLOR_TYPE_GRAY       = 0;
    PNG_COLOR_TYPE_PALETTE    = PNG_COLOR_MASK_COLOR or PNG_COLOR_MASK_PALETTE;
    PNG_COLOR_TYPE_RGB        = PNG_COLOR_MASK_COLOR;
    PNG_COLOR_TYPE_RGB_ALPHA  = PNG_COLOR_MASK_COLOR or PNG_COLOR_MASK_ALPHA;
    PNG_COLOR_TYPE_GRAY_ALPHA = PNG_COLOR_MASK_ALPHA;

    // aliases
    PNG_COLOR_TYPE_RGBA = PNG_COLOR_TYPE_RGB_ALPHA;
    PNG_COLOR_TYPE_GA   = PNG_COLOR_TYPE_GRAY_ALPHA;

    // This is for compression type. PNG 1.0-1.2 only define the single type.
    PNG_COMPRESSION_TYPE_BASE    = 0; // Deflate method 8, 32K window
    PNG_COMPRESSION_TYPE_DEFAULT = PNG_COMPRESSION_TYPE_BASE;

    // This is for filter type. PNG 1.0-1.2 only define the single type.
    PNG_FILTER_TYPE_BASE        = 0;  // Single row per-byte filtering
    PNG_INTRAPIXEL_DIFFERENCING = 64; // Used only in MNG datastreams
    PNG_FILTER_TYPE_DEFAULT     = PNG_FILTER_TYPE_BASE;

    // These are for the interlacing type.  These values should NOT be changed.
    PNG_INTERLACE_NONE  = 0; // Non-interlaced image
    PNG_INTERLACE_ADAM7 = 1; // Adam7 interlacing
    PNG_INTERLACE_LAST  = 2; // Not a valid value

type
    // where is better place for this definition?
    PFile = ^file;

procedure png_init_pascal_io(png_ptr: png_structp; pf : PFile);

implementation

// We cannot get c-style FILE* pointer to pass it to libpng, so we implement our own writing functions
procedure PngWriteData(png_ptr: png_structp; p: PByte; len: png_size_t); cdecl;
begin
    BlockWrite( PFile(png_get_io_ptr(png_ptr))^, p^, len);
end;

procedure PngFlushData(png_ptr: png_structp); cdecl;
begin
end;

procedure png_init_pascal_io(png_ptr: png_structp; pf : PFile);
begin
    png_set_write_fn(png_ptr, pf, @PngWriteData, @PngFlushData);
end;

end.
