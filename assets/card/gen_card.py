# gen_card.py  -- python assets/card/gen_card.py
# from openpyxl.styles.colors import BLACK
import os
from PIL import Image, ImageDraw, ImageFont

BASE     = os.path.dirname(os.path.abspath(__file__))
TEMPLATE = os.path.join(BASE, "template.png")
OUTPUT   = os.path.join(BASE, "dian_xing_jian_fa.png")

FONT_BOLD  = "/c/Windows/Fonts/simhei.ttf"
FONT_KAITI = "/c/Windows/Fonts/simkai.ttf"

img  = Image.open(TEMPLATE).convert("RGBA")
draw = ImageDraw.Draw(img)
W, H = img.size  # 1536 x 2752

# ── 字体 ────────────────────────────────────────────
f_cost = ImageFont.truetype(FONT_BOLD,  148)  # 宝石数字
f_name = ImageFont.truetype(FONT_BOLD,   72)  # 卡名（缩小）
TYPE_FONT_SIZE = 90
f_meta = ImageFont.truetype(FONT_BOLD, TYPE_FONT_SIZE)  # 类型标签
f_desc = ImageFont.truetype(FONT_KAITI,  82)  # 描述文字

# ── 布局锚点（实测 1536×2752）────────────────────────
LING_CX  = 184          # 蓝宝石中心 x
LING_CY  = 272          # 蓝宝石中心 y
DAO_CX   = 1316         # 红宝石中心 x
DAO_CY   = 274          # 红宝石中心 y
NAME_CX  = W // 2       # 卡名横向居中
NAME_CY  = 265          # 卡名纵向中心（与宝石同高）
TYPE_CX  = W // 2       # 类型居中
TYPE_CY  = 1670         # 类型文字中心（模板【类型】文字所在行）
DESC_TOP = 1850         # 描述文字区上边（实测净空区）
DESC_BOT = 2450         # 描述文字区下边
DESC_PAD = 200          # 左右内边距（加大让换行更自然）


# ── 绘制函数 ─────────────────────────────────────────

def centered(text, font, cx, cy, color, shadow=(0, 0, 0, 200), size=None):
    """居中绘制，带阴影。"""
    if size is not None:
        font = ImageFont.truetype(font.path, size)
    bb = draw.textbbox((0, 0), text, font=font)
    x = cx - (bb[2] - bb[0]) // 2
    y = cy - (bb[3] - bb[1]) // 2
    draw.text((x + 3, y + 3), text, font=font, fill=shadow)
    draw.text((x, y), text, font=font, fill=color)


def centered_with_bg(text, font, cx, cy, color, bg=(30, 15, 0, 180), pad_x=20, pad_y=10, size=None):
    """居中绘制，背后加半透明暗底（用于覆盖模板占位文字）。"""
    if size is not None:
        font = ImageFont.truetype(font.path, size)
    bb = draw.textbbox((0, 0), text, font=font)
    tw, th = bb[2] - bb[0], bb[3] - bb[1]
    x = cx - tw // 2
    y = cy - th // 2
    draw.rounded_rectangle(
        [x - pad_x, y - pad_y, x + tw + pad_x, y + th + pad_y],
        radius=12, fill=bg
    )
    draw.text((x + 2, y + 2), text, font=font, fill=(0, 0, 0, 200))
    draw.text((x, y), text, font=font, fill=color)


def glowing(text, font, cx, cy, fill, size=None):
    """居中绘制，带辉光（向外扩散的半透明层）。"""
    if size is not None:
        font = ImageFont.truetype(font.path, size)
    bb = draw.textbbox((0, 0), text, font=font)
    x = cx - (bb[2] - bb[0]) // 2
    y = cy - (bb[3] - bb[1]) // 2
    for r, alpha in [(10, 20), (6, 40), (3, 60)]:
        glow = (255, 220, 100, alpha)
        for dx in range(-r, r + 1, max(1, r // 3)):
            for dy in range(-r, r + 1, max(1, r // 3)):
                draw.text((x + dx, y + dy), text, font=font, fill=glow)
    draw.text((x + 3, y + 3), text, font=font, fill=(0, 0, 0, 220))
    draw.text((x, y), text, font=font, fill=fill)


def wrapped_centered(text, font, top, bot, pad, color, line_gap=18, size=None):
    """自动换行（优先在中文标点后断行）+ 整体垂直居中。"""
    if size is not None:
        font = ImageFont.truetype(font.path, size)
    max_w = W - pad * 2
    PUNC = "，。！？"
    lines, cur = [], ""
    for ch in text:
        test = cur + ch
        if draw.textbbox((0, 0), test, font=font)[2] > max_w and cur:
            # 优先在最后一个中文标点后断行
            best = -1
            for i in range(len(cur) - 1, -1, -1):
                if cur[i] in PUNC:
                    best = i
                    break
            if best >= 0:
                lines.append(cur[:best + 1])
                cur = cur[best + 1:].lstrip() + ch
            else:
                lines.append(cur)
                cur = ch
        else:
            cur = test
    if cur:
        lines.append(cur)

    lh = draw.textbbox((0, 0), "测", font=font)[3] + line_gap
    total_h = lh * len(lines) - line_gap
    sy = top + ((bot - top) - total_h) // 2

    for ln in lines:
        lw = draw.textbbox((0, 0), ln, font=font)[2]
        lx = pad + (max_w - lw) // 2
        draw.text((lx + 2, sy + 2), ln, font=font, fill=(0, 0, 0, 180))
        draw.text((lx, sy), ln, font=font, fill=color)
        sy += lh


# ── 颜色 ──────────────────────────────────────────────
WHITE  = (255, 255, 255, 255)
GOLD   = (255, 235, 160, 255)
BRONZE = (220, 170, 60,  255)
DARK   = (40,  20,  0,   255)
BLACK = (0,0,0,255)

# ── 渲染 ──────────────────────────────────────────────
glowing("2",        f_cost, LING_CX, LING_CY, WHITE)   # 灵力（带辉光）
glowing("3",        f_cost, DAO_CX,  DAO_CY,  WHITE)   # 道慧（带辉光）
centered("点星剑法", f_name, NAME_CX, NAME_CY, WHITE,size=60)   # 卡名（白色，居中）
centered("术法", f_meta, TYPE_CX, TYPE_CY, DARK,size=60)  # 类型（透明底+白字）
wrapped_centered(
    "造成 10(14) 点伤害，抽取 1 张牌。",
    f_desc, DESC_TOP, DESC_BOT, DESC_PAD, DARK
)

img.convert("RGB").save(OUTPUT)
print("saved:", OUTPUT)
