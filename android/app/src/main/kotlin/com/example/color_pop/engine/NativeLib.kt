package com.example.color_pop.engine

object NativeLib {
    init {
        System.loadLibrary("color_pop_native")
    }

    external fun generateCpvFromPixels(pixels: IntArray, width: Int, height: Int): ByteArray?
}
