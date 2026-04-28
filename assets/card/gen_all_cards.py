# gen_all_cards.py  -- python assets/card/gen_all_cards.py
# 这是一个用于批量生成卡牌图片的脚本，读取JSON数据并结合模板、字体、原画生成最终的卡牌图像。
import os
import json
from PIL import Image, ImageDraw, ImageFont

# ==========================================
# 1. 路径和目录初始化设置
# ==========================================
# 获取当前脚本所在目录的绝对路径，作为基准路径
BASE      = os.path.dirname(os.path.abspath(__file__))
# 卡牌底图模板路径
TEMPLATE  = os.path.join(BASE, "template.png")
# 卡牌数据的JSON配置文件路径 (该文件包含了所有卡牌的属性，如id, name, type, cost_ling等)
JSON_PATH = os.path.join(BASE, "../../scripts/data/all_card.json")
# 生成的卡牌图片的输出目录
OUT_DIR   = os.path.join(BASE, "generated")
# 卡牌原画（插图）所在目录
ART_DIR   = os.path.join(BASE, "art")

# 确保输出目录和原画目录存在，如果不存在则自动创建
os.makedirs(OUT_DIR, exist_ok=True)
os.makedirs(ART_DIR, exist_ok=True)

# ==========================================
# 2. 字体配置
# ==========================================
# Windows系统默认的黑体和楷体路径，用于卡牌上不同文字的渲染
FONT_BOLD  = "/c/Windows/Fonts/simhei.ttf" # 粗体字，通常用于名称、类型、消耗
FONT_KAITI = "/c/Windows/Fonts/simkai.ttf" # 楷体字，通常用于卡牌描述文本

# ==========================================
# 3. 布局锚点配置（基于 1536×2752 像素的模板实测得出）
# ==========================================
# 灵力消耗数字的中心坐标 (X, Y)
LING_CX  = 205
LING_CY  = 272
# 道行(剑意)消耗数字的中心坐标 (X, Y)
DAO_CX   = 1336
DAO_CY   = 274
# 卡牌名称的水平中心位置比例 (0.5 表示在图片正中间) 和垂直坐标
NAME_CX_RATIO = 0.5    # 相对宽度
NAME_CY  = 265
# 卡牌类型的水平中心位置比例和垂直坐标
TYPE_CX_RATIO = 0.5
TYPE_CY  = 1670
# 描述文本区域的顶部和底部 Y 坐标边界
DESC_TOP = 1850
DESC_BOT = 2450
# 描述文本左右两侧的内边距，用于防止文字贴边
DESC_PAD = 200

# ==========================================
# 4. 字体大小配置
# ==========================================
SIZE_COST = 128  # 消耗数字的字体大小
SIZE_NAME = 60   # 卡牌名称的字体大小
SIZE_TYPE = 60   # 卡牌类型的字体大小
SIZE_DESC = 82   # 卡牌描述文本的字体大小

# ==========================================
# 5. 颜色配置 (RGBA格式)
# ==========================================
WHITE  = (255, 255, 255, 255) # 纯白色
DARK   = (40,  20,  0,   255) # 深棕/黑色，用于正文文本等

# 根据卡牌类型决定文字颜色
TYPE_COLORS = {
    "术法": DARK,
    "秘法": DARK,
    "道法": DARK
}

# 根据卡牌稀有度决定卡牌名称的颜色
RARITY_COLORS = {
    "天品": (255, 215, 0, 255),    # 金黄色
    "地品": (148, 0, 211, 255),    # 紫色
    "玄品": (30, 144, 255, 255),   # 蓝色
    "黄品": (40, 40, 40, 255)      # 深灰色 (避免纯黑看不见)
}


# ==========================================
# 6. 核心绘制函数
# ==========================================
# 每次渲染都会接收 draw 对象和画布宽度 W，函数内部不依赖全局变量以保证独立性

def centered(draw, text, font, cx, cy, color, shadow=(0, 0, 0, 200)):
    """
    绘制居中对齐的带有阴影的单行文本
    :param draw: ImageDraw.Draw 对象
    :param text: 要绘制的字符串
    :param font: 字体对象
    :param cx: 文本中心点 X 坐标
    :param cy: 文本中心点 Y 坐标
    :param color: 文本主颜色
    :param shadow: 阴影颜色 (默认黑色半透明)
    """
    # 获取文本边界框，计算文本宽度和高度
    bb = draw.textbbox((0, 0), text, font=font)
    # 计算文本左上角的起始绘制坐标 x, y 以保证视觉中心在 cx, cy
    x = cx - (bb[2] - bb[0]) // 2
    y = cy - (bb[3] - bb[1]) // 2
    # 先在右下方偏移(3,3)的位置绘制阴影
    draw.text((x + 3, y + 3), text, font=font, fill=shadow)
    # 再在原位置绘制文本主体颜色
    draw.text((x, y), text, font=font, fill=color)


def glowing(draw, text, font, cx, cy, fill):
    """
    绘制带有发光效果的居中文本（通常用于消耗数字）
    :param draw: ImageDraw.Draw 对象
    :param text: 要绘制的字符串
    :param font: 字体对象
    :param cx: 文本中心点 X 坐标
    :param cy: 文本中心点 Y 坐标
    :param fill: 文本内部填充主颜色
    """
    # 计算文本居中绘制的起始坐标
    bb = draw.textbbox((0, 0), text, font=font)
    x = cx - (bb[2] - bb[0]) // 2
    y = cy - (bb[3] - bb[1]) // 2
    
    # 循环遍历不同半径和透明度的发光层，由大到小、由淡到浓绘制发光背景
    for r, alpha in [(0, 0), (0, 0), (0, 0)]:
        glow = (255, 220, 100, alpha) # 发光颜色为淡黄色
        # 根据当前半径 r 遍历周围的像素点进行绘制，模拟发光模糊效果
        for dx in range(-r, r + 1, max(1, r // 3)):
            for dy in range(-r, r + 1, max(1, r // 3)):
                draw.text((x + dx, y + dy), text, font=font, fill=glow)
    
    # 绘制一层硬阴影增加立体感
    draw.text((x + 3, y + 3), text, font=font, fill=(0, 0, 0, 220))
    # 绘制最上层的文本主体
    draw.text((x, y), text, font=font, fill=fill)


def wrapped_centered(draw, W, text, font, top, bot, pad, color, line_gap=18):
    """
    绘制自动换行并且垂直、水平居中对齐的多行文本块（用于卡牌效果描述）
    :param draw: ImageDraw.Draw 对象
    :param W: 画布整体宽度
    :param text: 长文本字符串
    :param font: 字体对象
    :param top: 文本区域顶部 Y 坐标
    :param bot: 文本区域底部 Y 坐标
    :param pad: 文本区域左右内边距
    :param color: 文本主颜色
    :param line_gap: 行间距
    """
    # 计算实际可用的最大行宽
    max_w = W - pad * 2
    PUNC = "，。！？" # 标点符号，优先在标点后换行
    lines, cur = [], ""
    
    # 逐字遍历，计算行宽，决定在哪里换行
    for ch in text:
        test = cur + ch
        # 预测加上当前字符后，宽度是否超过最大行宽
        if draw.textbbox((0, 0), test, font=font)[2] > max_w and cur:
            # 如果超宽，尝试往前找标点符号进行优雅换行
            best = -1
            for i in range(len(cur) - 1, -1, -1):
                if cur[i] in PUNC:
                    best = i
                    break
            
            # 如果找到了标点，在标点处截断
            if best >= 0:
                lines.append(cur[:best + 1])
                cur = cur[best + 1:].lstrip() + ch
            else:
                # 没找到标点，硬截断当前行
                lines.append(cur)
                cur = ch
        else:
            # 没超宽，继续追加字符
            cur = test
    
    # 将最后剩余的文字作为最后一行
    if cur:
        lines.append(cur)

    # 计算单行文本的高度，使用"测"字做基准测试高度
    lh = draw.textbbox((0, 0), "测", font=font)[3] + line_gap
    # 计算全部文本占据的总高度
    total_h = lh * len(lines) - line_gap
    # 计算第一行的起始 Y 坐标，使得整个文字块在 top 和 bot 之间垂直居中
    sy = top + ((bot - top) - total_h) // 2
    
    # 逐行绘制
    for ln in lines:
        # 计算当前行的实际宽度
        lw = draw.textbbox((0, 0), ln, font=font)[2]
        # 计算水平居中的 X 坐标
        lx = pad + (max_w - lw) // 2
        # 绘制该行的文字阴影
        draw.text((lx + 2, sy + 2), ln, font=font, fill=(0, 0, 0, 180))
        # 绘制该行的文字主体
        draw.text((lx, sy), ln, font=font, fill=color)
        # 移动到下一行的 Y 坐标位置
        sy += lh


def render_card(card):
    """
    渲染单张卡牌的主流程函数
    :param card: 卡牌数据字典，包含id, name, type, rarity, cost_ling, cost_dao, effect等字段
    :return: 最终生成的图片文件名
    """
    # 1. 加载底图模板并转换为 RGBA 模式以支持透明度
    img  = Image.open(TEMPLATE).convert("RGBA")
    draw = ImageDraw.Draw(img)
    W, H = img.size

    # 2. 实例化各种用途的字体对象
    f_cost = ImageFont.truetype(FONT_BOLD,  SIZE_COST)
    f_name = ImageFont.truetype(FONT_BOLD,  SIZE_NAME)
    f_type = ImageFont.truetype(FONT_BOLD,  SIZE_TYPE)
    f_desc = ImageFont.truetype(FONT_KAITI, SIZE_DESC)

    # 计算基于宽度的水平中心点 X 坐标
    cx = int(W * NAME_CX_RATIO)
    tx = int(W * TYPE_CX_RATIO)

    # 3. 绘制原画插图 (如果在 art 文件夹存在对应 id 的图片)
    art_path = os.path.join(ART_DIR, f"{card['id']:02d}.png")
    if os.path.exists(art_path):
        try:
            # 读取原画并转换为 RGBA 支持透明通道
            art_img = Image.open(art_path).convert("RGBA")
            # 缩放原画，适应卡面中间大框 (大约 1200x1050 的物理区域)
            art_img = art_img.resize((1000, 940))
            # 将原画粘贴到模板图上，坐标为 (270, 450)，使用自身作为 mask 处理透明边缘
            img.paste(art_img, (270, 450), art_img)
        except Exception as e:
            # 捕获图片加载异常并报警，防止个别图片损坏导致整批中断
            print(f"  [图片加载警告] 无法处理原画 {art_path}: {e}")

    # 4. 根据稀有度获取卡牌名字的颜色，如果没有对应的稀有度默认使用白色
    name_color = RARITY_COLORS.get(card.get("rarity", "黄品"), WHITE)

    # 5. 调用绘制函数渲染卡牌的文字元素
    # 绘制左上角灵力消耗数字（发光效果）
    glowing(draw, str(card["cost_ling"]), f_cost, LING_CX, LING_CY, WHITE)
    # 绘制右上角道行消耗数字（发光效果）
    glowing(draw, str(card["cost_dao"]),  f_cost, DAO_CX,  DAO_CY,  WHITE)
    # 绘制顶部卡牌名字（居中，带阴影）
    centered(draw, card["name"],          f_name, cx,      NAME_CY, name_color)
    # 绘制卡牌类型标签（例如：术法，秘法）
    centered(draw, card["type"],          f_type, tx,      TYPE_CY, TYPE_COLORS.get(card["type"], DARK))
    # 绘制卡牌效果描述文本（自动换行、居中，多行排列）
    wrapped_centered(draw, W, card["effect"], f_desc, DESC_TOP, DESC_BOT, DESC_PAD, DARK)

    # 6. 保存最终生成的图片
    # 构建输出文件名，如 01_剑气.png
    fname = f"{card['id']:02d}_{card['name']}.png"
    out   = os.path.join(OUT_DIR, fname)
    # 转换为 RGB 模式去除 Alpha 通道再保存（减少体积，也符合部分游戏引擎直接使用图片的需求）
    img.convert("RGB").save(out)
    return fname


def main():
    """
    程序入口，负责加载数据并触发遍历渲染
    """
    # 1. 打开并解析所有的卡牌 JSON 数据
    with open(JSON_PATH, encoding="utf-8") as f:
        data = json.load(f)

    # 2. 提取出所有卡牌的列表
    cards = data["cards"]
    print(f"开始生成：共计 {len(cards)} 张卡牌，输出目录为 → {OUT_DIR}")
    
    # 3. 遍历每一张卡牌，依次调用 render_card 进行渲染
    for card in cards:
        fname = render_card(card)
        # 打印当前进度
        print(f"  [{card['id']:02d}] 成功生成: {fname}")
        
    print("所有卡牌生成完毕。")


# 只有直接执行本脚本时才触发 main() 函数
if __name__ == "__main__":
    main()
