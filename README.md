# color_pop

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## CPV Vector Format

This project now supports `.cpv` (Color Pop Vector), a JSON-based vector format for coloring pages.

The workspace loads a `.cpv` file directly, or it will look for a sidecar `.cpv` file next to the original image path with the same base name. When a CPV document is available, the canvas renders vector regions with `CustomPainter` instead of drawing a raster image.

Minimal CPV structure:

```json
{
	"version": 1,
	"canvas": {
		"width": 1024,
		"height": 1024,
		"backgroundColor": 4294967295
	},
	"layers": [
		{
			"type": "region",
			"id": "petal-1",
			"name": "Petal 1",
			"points": [{"x": 120, "y": 120}, {"x": 220, "y": 60}, {"x": 280, "y": 150}],
			"fillColor": 4294967295,
			"borderColor": 4278190080,
			"borderWidth": 3
		}
	]
}
```
