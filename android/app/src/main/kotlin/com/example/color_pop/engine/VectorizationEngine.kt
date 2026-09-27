package com.example.color_pop.engine

import android.graphics.Color

object VectorizationEngine {

    fun vectorize(pixels: IntArray, width: Int, height: Int): List<ColoredPath> {
        val inverted = false
        val visited = BooleanArray(width * height)
        val regions = mutableListOf<ColoredPath>()
        val queue = IntArray(width * height)
        
        val dx4 = intArrayOf(1, 0, -1, 0)
        val dy4 = intArrayOf(0, 1, 0, -1)

        for (y in 0 until height) {
            for (x in 0 until width) {
                val idx = y * width + x
                
                if (!visited[idx]) {
                    val isFg = isForeground(pixels[idx], inverted)
                    
                    val outerBoundary = traceBoundary(
                        pixels,
                        width,
                        height,
                        x,
                        y,
                        isFg,
                        inverted,
                    )
                    
                    var head = 0
                    var tail = 0
                    
                    queue[tail++] = idx
                    visited[idx] = true
                    
                    while (head < tail) {
                        val currIdx = queue[head++]
                        val cx = currIdx % width
                        val cy = currIdx / width
                        
                        for (i in 0 until 4) {
                            val nx = cx + dx4[i]
                            val ny = cy + dy4[i]
                            if (nx in 0 until width && ny in 0 until height) {
                                val nIdx = ny * width + nx
                                val nIsFg = isForeground(pixels[nIdx], inverted)
                                
                                if (nIsFg == isFg && !visited[nIdx]) {
                                    visited[nIdx] = true
                                    queue[tail++] = nIdx
                                }
                            }
                        }
                    }
                    
                    if (outerBoundary.size > 2 && !isFg) {
                        // Extract White paintable region with simplified contour
                        val simplified = simplifyPath(outerBoundary, 0.75f)
                        regions.add(ColoredPath(
                            color = Color.WHITE,
                            outerBoundary = simplified,
                            isStroke = false,
                            holes = emptyList()
                        ))
                    }
                }
            }
        }
        
        return regions
    }

    private fun traceBoundary(
        pixels: IntArray,
        width: Int,
        height: Int,
        startX: Int,
        startY: Int,
        componentIsForeground: Boolean,
        inverted: Boolean,
    ): MutableList<Point2D> {
        val boundary = mutableListOf<Point2D>()
        val neighborX = intArrayOf(-1, 0, 1, 1, 1, 0, -1, -1)
        val neighborY = intArrayOf(-1, -1, -1, 0, 1, 1, 1, 0)

        fun isComponentPixel(x: Int, y: Int): Boolean {
            if (x !in 0 until width || y !in 0 until height) return false
            return isForeground(pixels[y * width + x], inverted) == componentIsForeground
        }

        val startBacktrackX = startX - 1
        val startBacktrackY = startY
        var currentX = startX
        var currentY = startY
        var backtrackX = startBacktrackX
        var backtrackY = startBacktrackY
        // Boundary tracing must be bounded by the image perimeter. The old
        // pixel-area bound could spend millions of iterations in a loop when
        // the start/backtrack state never matched again.
        val maxSteps = minOf(width * height * 2, maxOf(width, height) * 16)
        val seenStates = HashSet<Long>()

        for (step in 0 until maxSteps) {
            val state = (currentX.toLong() shl 48) or
                (currentY.toLong() shl 32) or
                ((backtrackX + width).toLong() shl 16) or
                (backtrackY + height).toLong()
            if (!seenStates.add(state)) break

            boundary.add(Point2D(currentX.toFloat(), currentY.toFloat()))

            var backtrackDirection = 7
            for (direction in 0 until 8) {
                if (currentX + neighborX[direction] == backtrackX &&
                    currentY + neighborY[direction] == backtrackY
                ) {
                    backtrackDirection = direction
                    break
                }
            }

            var nextDirection = -1
            for (offset in 1..8) {
                val direction = (backtrackDirection + offset) % 8
                val nextX = currentX + neighborX[direction]
                val nextY = currentY + neighborY[direction]
                if (isComponentPixel(nextX, nextY)) {
                    nextDirection = direction
                    break
                }
            }

            if (nextDirection < 0) break

            val previousDirection = (nextDirection + 7) % 8
            val nextBacktrackX = currentX + neighborX[previousDirection]
            val nextBacktrackY = currentY + neighborY[previousDirection]
            currentX += neighborX[nextDirection]
            currentY += neighborY[nextDirection]
            backtrackX = nextBacktrackX
            backtrackY = nextBacktrackY

            if (currentX == startX && currentY == startY &&
                backtrackX == startBacktrackX && backtrackY == startBacktrackY
            ) {
                break
            }
        }

        return boundary
    }
    
    private fun isForeground(color: Int, inverted: Boolean): Boolean {
        val a = Color.alpha(color)
        if (a < 128) return false // Transparent background is NOT foreground
        
        val r = Color.red(color)
        val g = Color.green(color)
        val b = Color.blue(color)
        
        val luminance = luminance(color)
        val isDark = luminance < 96 // Ignore anti-aliased gray pixels near white areas.
        return if (inverted) !isDark else isDark
    }

    private fun luminance(color: Int): Int {
        val r = Color.red(color)
        val g = Color.green(color)
        val b = Color.blue(color)
        return (r * 299 + g * 587 + b * 114) / 1000
    }

    private fun perpendicularDistance(pt: Point2D, lineStart: Point2D, lineEnd: Point2D): Float {
        val dx = lineEnd.x - lineStart.x
        val dy = lineEnd.y - lineStart.y
        val mag = Math.hypot(dx.toDouble(), dy.toDouble()).toFloat()
        if (mag == 0f) return Math.hypot((pt.x - lineStart.x).toDouble(), (pt.y - lineStart.y).toDouble()).toFloat()
        val area = Math.abs(dy * pt.x - dx * pt.y + lineEnd.x * lineStart.y - lineEnd.y * lineStart.x)
        return area / mag
    }

    private fun simplifyPath(points: List<Point2D>, epsilon: Float): List<Point2D> {
        if (points.size < 3) return points
        
        var dmax = 0f
        var index = 0
        for (i in 1 until points.size - 1) {
            val d = perpendicularDistance(points[i], points.first(), points.last())
            if (d > dmax) {
                index = i
                dmax = d
            }
        }
        
        if (dmax > epsilon) {
            val recResults1 = simplifyPath(points.subList(0, index + 1), epsilon)
            val recResults2 = simplifyPath(points.subList(index, points.size), epsilon)
            val result = mutableListOf<Point2D>()
            result.addAll(recResults1.dropLast(1))
            result.addAll(recResults2)
            return result
        } else {
            return listOf(points.first(), points.last())
        }
    }
}
