package main

import pd "playdate"
import "core:math"
import "core:c"

DrawWireFrame :: proc(
	display: ^Display,
	vertices: []Vector3,
    triangles: []Triangle,
    projMat: Matrix4x4,
    instensity: f32,
    cullBackFace: bool
) {
	for &tri in triangles {
    v1 := vertices[tri[0]]
    v2 := vertices[tri[1]]
    v3 := vertices[tri[2]]

	if cullBackFace && IsBackFace(v1, v2, v3) {
    continue
	}

	p1 := ProjectToScreen(projMat, v1)
	p2 := ProjectToScreen(projMat, v2)
	p3 := ProjectToScreen(projMat, v3)

	if (IsFaceOutsideFrustum(p1, p2, p3)) {
    continue
	}

	DrawLine(p1.xy, p2.xy, intensity)
    DrawLine(p2.xy, p3.xy, intensity)
    DrawLine(p3.xy, p1.xy, intensity)
    }
}

IsBackFace :: proc(v1, v2, v3: Vector3) -> bool {
	edge1 := v2 - v1
	edge2 := v3 - v1

	cross := Vector3CrossProduct(edge1, edge2)
    crossNorm := Vector3Normalize(cross)
    toCamera := Vector3Normalize(v1)

    return Vector3DotProduct(crossNorm, toCamera) >= 0.0
}

ProjectToScreen :: proc(mat: Matrix4x4, p: Vector3) -> Vector3 {
	clip := Mat4MultVec4(mat, Vector4{p.x, p.y, p.z, 1.0})

	//inverse w (invW)
	invW : f32 = 1.0 / clip.w
	//normalized device coordinants (ndc)
	ndcX := clip.x * invW
	ndcY := clip.y * invW

	screenX := ( ndcX * 0.5 + 0.5) * SCREEN_WIDTH
	screenY := (-ndcY * 0.5 + 0.5) * SCREEN_HEIGHT

	return Vector3{screenX, screenY, invW}
}

IsFaceOutsideFrustum :: proc(p1, p2, p3: Vector3) -> bool {
    if (p1.z >  1.0 || p2.z >  1.0 || p3.z >  1.0) ||
       (p1.z < -1.0 || p2.z < -1.0 || p3.z < -1.0) {
        return true
       }
    minX := math.min(p1.x, math.min(p2.x, p3.x))
    maxX := math.max(p1.x, math.max(p2.x, p3.x))
    minY := math.min(p1.y, math.min(p2.y, p3.y))
    maxY := math.max(p1.y, math.max(p2.y, p3.y))

    if maxX < 0 || minX > SCREEN_WIDTH ||
    	maxY < 0 || minY > SCREEN_HEIGHT {
     	return true
    }
    return false
}


DrawLine :: proc(a, b: Vector2, intensity: f32) {
	dX := b.x - a.x
	dY := b.y - a.y

	longerDelta := math.abs(dX) >= math.abs(dY) ? math.abs(dX) : math.abs(dY)

	incX := dX / longerDelta
	incY := dY / longerDelta

	x := a.x
    y := a.y

    for i := 0; i <= int(longerDelta); i += 1 {
        DisplaySetPixel(&display, i32(x), i32(y), intensity)
        x += incX
        y += incY
    }
}

DrawUnlit :: proc(
	display: ^Display,
	vertices: []Vector3,
    triangles: []Triangle,
    projMat: Matrix4x4,
    intensity: f32,
    zBuffer: ^ZBuffer
){
	for &tri in triangles {
        v1 := vertices[tri[0]]
        v2 := vertices[tri[1]]
        v3 := vertices[tri[2]]

        if IsBackFace(v1, v2, v3) {
            continue
        }

        p1 := ProjectToScreen(projMat, v1)
        p2 := ProjectToScreen(projMat, v2)
        p3 := ProjectToScreen(projMat, v3)

        if IsFaceOutsideFrustum(p1, p2, p3) {
            continue
        }
        DrawFilledTriangle(&p1, &p2, &p3, intensity, zBuffer)
	}
}

DrawFlatShaded :: proc(
	display: ^Display,
	vertices: []Vector3,
    triangles: []Triangle,
    projMat: Matrix4x4,
    light: Light,
    intensity: f32,
    zBuffer: ^ZBuffer,
    ambient:f32 = 0.2
){
	for &tri in triangles {
    v1 := vertices[tri[0]]
    v2 := vertices[tri[1]]
    v3 := vertices[tri[2]]

    cross := Vector3CrossProduct(v2 - v1, v3 - v1)
    crossNorm := Vector3Normalize(cross)
    toCamera := Vector3Normalize(v1)

    if Vector3DotProduct(crossNorm, toCamera) >= 0.0 {
        continue
    }
    p1 := ProjectToScreen(projMat, v1)
    p2 := ProjectToScreen(projMat, v2)
    p3 := ProjectToScreen(projMat, v3)

    if IsFaceOutsideFrustum(p1, p2, p3) {
        continue
    }

    intensity := math.clamp(Vector3DotProduct(crossNorm, light.direction), ambient, 1.0)
    DrawFilledTriangle(&p1, &p2, &p3, intensity, zBuffer)
	}
}

DrawTexFlatShaded :: proc(
	display: ^Display,
	vertices: []Vector3,
    triangles: []Triangle,
    projMat: Matrix4x4,
    uvs: []Vector2,
    light: Light,
    bitmap: ^pd.Bitmap,
    intensity: f32,
    zBuffer: ^ZBuffer,
    ambient:f32 = 0.2
){
	for &tri in triangles {
        v1 := vertices[tri[0]]
        v2 := vertices[tri[1]]
        v3 := vertices[tri[2]]

        uv1 := uvs[tri[3]]
        uv2 := uvs[tri[4]]
        uv3 := uvs[tri[5]]

        cross := Vector3CrossProduct(v2 - v1, v3 - v1)
        crossNorm := Vector3Normalize(cross)
        toCamera := Vector3Normalize(v1)

        if (Vector3DotProduct(crossNorm, toCamera) >= 0.0) {
            continue
        }

        p1 := ProjectToScreen(projMat, v1)
        p2 := ProjectToScreen(projMat, v2)
        p3 := ProjectToScreen(projMat, v3)

        if (IsFaceOutsideFrustum(p1, p2, p3)) {
            continue
        }

        intensity := math.clamp(Vector3DotProduct(crossNorm, light.direction), ambient, 1.0)

        DrawTexTriFlatShaded(
        	&p1, &p2, &p3,
            &uv1, &uv2, &uv3,
            bitmap, intensity, zBuffer
        )
	}
}

DrawTexTriFlatShaded :: proc(
	p1, p2, p3: ^Vector3,
    uv1, uv2, uv3: ^Vector2,
    bitmap: ^pd.Bitmap,
    intensity: f32,
    zBuffer: ^ZBuffer,
){
	Sort(p1, p2, p3, uv1, uv2, uv3)

    FloorXY(p1)
    FloorXY(p2)
    FloorXY(p3)

    // Draw a flat-bottom triangle
    if p2.y != p1.y {
        invSlope1 := (p2.x - p1.x) / (p2.y - p1.y)
        invSlope2 := (p3.x - p1.x) / (p3.y - p1.y)

        for y := p1.y; y <= p2.y; y += 1 {
            xStart := p1.x + (y - p1.y) * invSlope1
            xEnd := p1.x + (y - p1.y) * invSlope2

            if xStart > xEnd {
                xStart, xEnd = xEnd, xStart
            }

            for x := xStart; x <= xEnd; x += 1 {
                DrawTexelFlatShaded(
                    x, y,
                    p1, p2, p3,
                    uv1, uv2, uv3,
                    bitmap, intensity, zBuffer
                )
            }
        }
    }
// Draw a flat-top triangle
    if p3.y != p1.y {
        invSlope1 := (p3.x - p2.x) / (p3.y - p2.y)
        invSlope2 := (p3.x - p1.x) / (p3.y - p1.y)

        for y := p2.y; y <= p3.y; y += 1 {
            xStart := p2.x + (y - p2.y) * invSlope1
            xEnd := p1.x + (y - p1.y) * invSlope2

            if xStart > xEnd {
                xStart, xEnd = xEnd, xStart
            }

            for x := xStart; x <= xEnd; x += 1 {
                DrawTexelFlatShaded(
                    x, y,
                    p1, p2, p3,
                    uv1, uv2, uv3,
                    bitmap, intensity, zBuffer
                )
            }
        }
    }
}


DrawTexUnlit :: proc(
	display: ^Display,
	vertices: []Vector3,
    triangles: []Triangle,
    projMat: Matrix4x4,
    uvs: []Vector2,
    bitmap: ^pd.Bitmap,
    zBuffer: ^ZBuffer,
){
    for &tri in triangles {
        v1 := vertices[tri[0]]
        v2 := vertices[tri[1]]
        v3 := vertices[tri[2]]

        uv1 := uvs[tri[3]]
        uv2 := uvs[tri[4]]
        uv3 := uvs[tri[5]]

        if IsBackFace(v1, v2, v3) {
            continue
        }

        p1 := ProjectToScreen(projMat, v1)
        p2 := ProjectToScreen(projMat, v2)
        p3 := ProjectToScreen(projMat, v3)

        if (IsFaceOutsideFrustum(p1, p2, p3)) {
            continue
        }

        DrawTexTriFlatShaded(
            &p1, &p2, &p3,
            &uv1, &uv2, &uv3,
            bitmap,
            1.0, // Unlit
            zBuffer
        )
    }
}

DrawFilledTriangle :: proc(
	p1, p2, p3: ^Vector3,
	intensity: f32,
	zBuffer: ^ZBuffer
){
	Sort(p1, p2, p3)
	FloorXY(p1)
	FloorXY(p2)
	FloorXY(p3)

	// Draw a flat-bottom triangle
	if p2.y != p1.y {
	    invSlope1 := (p2.x - p1.x) / (p2.y - p1.y)
	    invSlope2 := (p3.x - p1.x) / (p3.y - p1.y)

		for y := p1.y; y <= p2.y; y += 1 {
        	xStart := p1.x + (y - p1.y) * invSlope1
         	xEnd := p1.x + (y - p1.y) * invSlope2

          	if xStart > xEnd {
            	xStart, xEnd = xEnd, xStart
           	}
	        for x := xStart; x <= xEnd; x += 1 {
		        DrawPixel(x, y, p1, p2, p3, intensity, zBuffer)
	        }
		}
	}
		// Draw flat-top triangle
	if p3.y != p1.y {
        invSlope1 := (p3.x - p2.x) / (p3.y - p2.y)
        invSlope2 := (p3.x - p1.x) / (p3.y - p1.y)

        for y := p2.y; y <= p3.y; y += 1 {
            xStart := p2.x + (y - p2.y) * invSlope1
            xEnd := p1.x + (y - p1.y) * invSlope2

            if xStart > xEnd {
                xStart, xEnd = xEnd, xStart
            }

            for x := xStart; x <= xEnd; x += 1 {
                DrawPixel(x, y, p1, p2, p3, intensity, zBuffer)
			}
		}
    }
}

DrawTexelFlatShaded :: proc(
	x, y: f32,
	p1, p2, p3: ^Vector3,
	uv1, uv2, uv3: ^Vector2,
	bitmap: ^pd.Bitmap,
	intensity: f32,
	zBuffer: ^ZBuffer
){
	ix := i32(x)
	iy := i32(y)

	if IsPointOutsideViewport(ix, iy){
		return
	}
	p       := Vector2{x, y}
	weights := BarycentricWeights(p1.xy, p2.xy, p3.xy, p)
	alpha   := weights.x
	beta    := weights.y
	gamma   := weights.z

	denom  := alpha*p1.z + beta*p2.z + gamma*p3.z
	depth := 1.0 / denom

	zIndex := SCREEN_WIDTH*iy +ix
	if depth <= zBuffer[zIndex] {

		interpU := ((uv1.x*p1.z)*alpha + (uv2.x*p2.z)*beta + (uv3.x*p3.z)*gamma) * depth
		interpV := ((uv1.x*p1.z)*alpha + (uv2.x*p2.z)*beta + (uv3.x*p3.z)*gamma) * depth

		width, height, rowBytes: c.int
        mask, data: [^]u8
        display.gfx.get_bitmap_data(bitmap, &width, &height, &rowBytes, &mask, &data)

		texX := i32(interpU * f32(width)) % width
		texY := i32(interpU * f32(height)) % height

		// Read the pixel bit from the packed 1-bit data
        byteIndex := texY * rowBytes + texX / 8
        bitMask   := u8(1 << uint(7 - (texX % 8)))
        isWhite   := (data[byteIndex] & bitMask) != 0

		//tex := bitmap.pixels[texY*bitmap.width + texX]
		//
		// Use bitmap pixel to modulate intensity
        texIntensity := intensity * (1.0 if isWhite else 0.0)

		DisplaySetPixel(&display, ix, iy, texIntensity)
        zBuffer[zIndex] = depth
	}
}


DrawPixel :: proc(
    x, y: f32,
    p1, p2, p3: ^Vector3,
    intensity: f32,
    zBuffer: ^ZBuffer
) {
    ix := i32(x)
    iy := i32(y)
    if IsPointOutsideViewport(ix, iy) {
        return
    }

    p       := Vector2{x, y}
    weights := BarycentricWeights(p1.xy, p2.xy, p3.xy, p)
    alpha   := weights.x
    beta    := weights.y
    gamma   := weights.z

    denom  := alpha*p1.z + beta*p2.z + gamma*p3.z
    depth := 1.0 / denom

    zIndex := SCREEN_WIDTH*iy + ix
    if (depth < zBuffer[zIndex]) {
        DisplaySetPixel(&display, ix, iy, intensity)
        zBuffer[zIndex] = depth
    }
}

BarycentricWeights :: proc(a, b, c, p: Vector2) -> Vector3 {
	ac := c - a
	ab := b - a
	ap := p - a
	pc := c - p
	pb := b - p

	area := (ac.x * ab.y - ac.y * ab.x)
	alpha := (pc.x * pb.y - pc.y * pb.x) / area
	beta := (ac.x * ap.y - ac.y * ap.x) / area

	gamma := 1.0 - alpha - beta

	return Vector3{alpha, beta, gamma}
}

IsPointOutsideViewport :: proc(x, y: i32) -> bool {
    return x < 0 || x >= SCREEN_WIDTH || y < 0 || y >= SCREEN_HEIGHT
}
