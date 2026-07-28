import json
from pathlib import Path

# ============================================
# Tự động xác định thư mục gốc của project
# generate_library.py nằm trong:
# assets/mock_data/generate_library.py
# ============================================

PROJECT_ROOT = Path(__file__).resolve().parents[2]

IMAGE_ROOT = PROJECT_ROOT / "assets" / "images" / "categories"
OUTPUT_JSON = PROJECT_ROOT / "assets" / "mock_data" / "library.json"

IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}

artworks = []

print(f"Project Root : {PROJECT_ROOT}")
print(f"Image Folder : {IMAGE_ROOT}")
print()

if not IMAGE_ROOT.exists():
    raise FileNotFoundError(f"Không tìm thấy thư mục:\n{IMAGE_ROOT}")

# Quét toàn bộ ảnh
for image_file in IMAGE_ROOT.rglob("*"):

    if not image_file.is_file():
        continue

    if image_file.suffix.lower() not in IMAGE_EXTENSIONS:
        continue

    # Đường dẫn relative từ project
    relative_path = image_file.relative_to(PROJECT_ROOT).as_posix()

    parts = relative_path.split("/")

    # assets/images/categories/<category>/<subcategory>/image.jpg
    #                0        1         2          3          4

    category = parts[3] if len(parts) > 3 else ""
    subcategory = parts[4] if len(parts) > 4 else ""

    title = image_file.stem

    artworks.append({
        "id": relative_path,
        "title": title,
        "category": category,
        "subcategory": subcategory,
        "imagePath": relative_path
    })

# Sắp xếp
artworks.sort(
    key=lambda x: (
        x["category"],
        x["subcategory"],
        x["title"]
    )
)

# Ghi JSON
OUTPUT_JSON.parent.mkdir(parents=True, exist_ok=True)

with open(OUTPUT_JSON, "w", encoding="utf-8") as f:
    json.dump(
        artworks,
        f,
        ensure_ascii=False,
        indent=2
    )

print("===================================")
print(f"Images found : {len(artworks)}")
print(f"Output       : {OUTPUT_JSON}")
print("Done!")
print("===================================")