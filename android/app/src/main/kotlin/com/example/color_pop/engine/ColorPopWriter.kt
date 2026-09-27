package com.example.color_pop.engine

import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder

object ColorPopWriter {
    private const val MAGIC_BYTES = 0x504F5043 // 'CPOP'

    fun writeToFile(regions: List<ColoredPath>, width: Double, height: Double, outputPath: String): Boolean {
        try {
            val file = File(outputPath)
            val stream = FileOutputStream(file)
            
            // Calculate size to allocate buffer (or just use chunks)
            // For simplicity in Kotlin, we'll write directly using ByteBuffer for small chunks
            
            val headerBuffer = ByteBuffer.allocate(28).order(ByteOrder.LITTLE_ENDIAN)
            headerBuffer.putInt(MAGIC_BYTES)
            headerBuffer.putInt(1) // Version 1
            headerBuffer.putDouble(width)
            headerBuffer.putDouble(height)
            headerBuffer.putInt(regions.size)
            
            stream.write(headerBuffer.array())
            
            for (region in regions) {
                // Region header: ID(4), Color(4), isStroke(1), Confidence(8), OuterLoopPts(4)
                val isStrokeByte: Byte = if (region.isStroke) 1 else 0
                val regionHeader = ByteBuffer.allocate(4 + 4 + 1 + 8).order(ByteOrder.LITTLE_ENDIAN)
                regionHeader.putInt(region.hashCode()) // ID
                regionHeader.putInt(region.color) // Color
                regionHeader.put(isStrokeByte) // isStroke
                regionHeader.putDouble(1.0) // Confidence
                
                stream.write(regionHeader.array())
                
                // Write Outer Loop
                val outerCountBuf = ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN)
                outerCountBuf.putInt(region.outerBoundary.size)
                stream.write(outerCountBuf.array())
                
                val outerPtsBuf = ByteBuffer.allocate(region.outerBoundary.size * 8).order(ByteOrder.LITTLE_ENDIAN)
                for (pt in region.outerBoundary) {
                    outerPtsBuf.putFloat(pt.x)
                    outerPtsBuf.putFloat(pt.y)
                }
                stream.write(outerPtsBuf.array())
                
                // Write Holes
                val holeCountBuf = ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN)
                holeCountBuf.putInt(region.holes.size)
                stream.write(holeCountBuf.array())
                
                for (hole in region.holes) {
                    val hCountBuf = ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN)
                    hCountBuf.putInt(hole.size)
                    stream.write(hCountBuf.array())
                    
                    val hPtsBuf = ByteBuffer.allocate(hole.size * 8).order(ByteOrder.LITTLE_ENDIAN)
                    for (pt in hole) {
                        hPtsBuf.putFloat(pt.x)
                        hPtsBuf.putFloat(pt.y)
                    }
                    stream.write(hPtsBuf.array())
                }
            }
            
            stream.flush()
            stream.close()
            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }
}
