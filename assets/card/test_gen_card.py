import os
import unittest
import sys

# 设定项目基础路径，以便导入模块
BASE = os.path.dirname(os.path.abspath(__file__))

class TestGenCard(unittest.TestCase):
    def test_run_gen_card(self):
        """
        全方位测试：通过执行 gen_card.py，验证在降低辉光厚度之后
        生图过程是否仍然能够顺畅执行且无错，同时输出文件可以被正确创建。
        """
        # 测试前如已存在旧输出则先删除
        output_file = os.path.join(BASE, "dian_xing_jian_fa.png")
        if os.path.exists(output_file):
            try:
                os.remove(output_file)
            except Exception as e:
                pass
        
        # 将当前目录临时添加到 sys.path 并导入 gen_card 执行
        # 由于 gen_card.py 在全局作用域直接执行了生图逻辑，我们只要引入即可执行整套流程
        try:
            import gen_card
        except Exception as e:
            self.fail(f"执行 gen_card.py 时发生异常: {e}")
            
        # 验证文件是否成功生成
        self.assertTrue(os.path.exists(output_file), "预期图片文件应已成功生成，但并未找到！")

if __name__ == '__main__':
    unittest.main()
