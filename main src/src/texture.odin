package main

import pd "playdate"
import "core:c"

pd_api: ^pd.Api

// BitmapTex :: struct {
// 	width:            i32,
// 	height:           i32,
// 	rowBytes:         i32,
// 	mask:             []u8,
// 	data:             []u8,
// 	pixels:           [^]u8,
BitmapTex :: struct {
	bitmap: ^pd.Bitmap,
}


LoadBitmap :: proc(gfx: ^pd.Api_Graphics_Procs, path: cstring) -> BitmapTex {
	err: cstring
	bitmap := gfx.load_bitmap(path, &err)

	if bitmap == nil {
	pd_api.system.log_to_console("Hello")
		return BitmapTex{}
	}

	width, height, rowBytes: c.int
	mask, data: [^]u8

	gfx.get_bitmap_data(bitmap, &width, &height, &rowBytes, &mask, &data)

	return BitmapTex {
		// width             = i32(width),
		// height            = i32(height),
		// rowBytes          = i32(rowBytes),
		// pixels            = data,
		bitmap
	}
}
