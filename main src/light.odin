package main

Light :: struct {
	direction: Vector3,
	strength:   f32,
}

MakeLight :: proc(direction: Vector3, strength: f32) -> Light {
	return{
		Vector3Normalize(direction),
		strength
	}
}

Bayer4x4Matrix := [4][4]f32{
	{ 0.0/16.0,  8.0/16.0,  2.0/16.0, 10.0/16.0 },
    {12.0/16.0,  4.0/16.0, 14.0/16.0,  6.0/16.0 },
    { 3.0/16.0, 11.0/16.0,  1.0/16.0,  9.0/16.0 },
    {15.0/16.0,  7.0/16.0, 13.0/16.0,  5.0/16.0 },
}

BayerDither :: proc(x, y: i32, intensity: f32) -> bool {
	threshold := Bayer4x4Matrix[y % 4][x % 4]
	return intensity > threshold
}
