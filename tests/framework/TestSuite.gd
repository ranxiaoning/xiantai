## TestSuite.gd
## 测试套件辅助工具。
## headless 兼容方案：不使用 class_name，不被 extends，由 TestMain 通过 load().new() 实例化。
## 每个具体测试套件直接 extends RefCounted，内联 _ok/_fail 方法即可。

## 此文件仅作说明保留，实际测试套件为独立 RefCounted 脚本。
extends RefCounted
