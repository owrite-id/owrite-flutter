import json
import re

with open('scratch_posts.json', 'r', encoding='utf-8') as f:
    posts = json.load(f)

for p in posts:
    print(f"=== POST ID: {p.get('id')} - {p.get('title', {}).get('rendered')} ===")
    content = p.get('content', {}).get('rendered', '')
    imgs = re.findall(r'<img[^>]+>', content)
    if not imgs:
        print("  No <img> tags found in content.")
    for img in imgs:
        print("  IMG TAG:", img)
        # Extract src, data-src, srcset, data-lazy-src, class, etc.
        src_m = re.search(r'src=["\']([^"\']+)["\']', img)
        datasrc_m = re.search(r'data-src=["\']([^"\']+)["\']', img)
        datalazysrc_m = re.search(r'data-lazy-src=["\']([^"\']+)["\']', img)
        srcset_m = re.search(r'srcset=["\']([^"\']+)["\']', img)
        print(f"    src: {src_m.group(1) if src_m else None}")
        print(f"    data-src: {datasrc_m.group(1) if datasrc_m else None}")
        print(f"    data-lazy-src: {datalazysrc_m.group(1) if datalazysrc_m else None}")
        print(f"    srcset: {srcset_m.group(1) if srcset_m else None}")
    print()
