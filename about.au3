Func GetReleaseNotes()
    Return "v0.5.5" & @CRLF & _
        "  - 增加自定义分类设置及 Ctrl、Shift 批量选择。" & @CRLF & _
        "  - 增加搜索历史、独立搜索及自动保存、右键传送。" & @CRLF & _
        "  - 增加主题、透明度、布局和坐标列设置。" & @CRLF & @CRLF & _
        "v0.5.4" & @CRLF & _
        "  - 分类导航按各地图分组的预设顺序排列。" & @CRLF & _
        "  - 主窗口按 Esc 不再退出。" & @CRLF & _
        "  - 补充收藏坐标的地图 ID。" & @CRLF & @CRLF & _
        "v0.5.3" & @CRLF & _
        "  - 收藏坐标支持地图 ID 和人物朝向。" & @CRLF & _
        "  - 增加 1.12.1 和 1.12.3 地图读取及朝向支持。" & @CRLF & @CRLF & _
        "v0.5.2" & @CRLF & _
        "  - 重构坐标页和设置页，增加关于页。" & @CRLF & _
        "  - 最近传送记录扩展到 20 条，支持双击再次传送。" & @CRLF & _
        "  - 单 WoW 进程自动选择及定时检测 PID；查询间隔可配置。" & @CRLF & @CRLF & _
        "v0.5.1" & @CRLF & _
        "  - 增加分组分类导航 Tab 和三列分类网格，点击分类切换坐标。" & @CRLF & _
        "  - 增加 OnTop 控件，并补充版本入口所需的 MapID 声明。" & @CRLF & @CRLF & _
        "v0.5" & @CRLF & _
        "  - 增加 3.3.5 传送朝向支持。" & @CRLF & _
        "  - 加入 Python/PySide6 版本、自动化测试和 Windows 启动脚本。" & @CRLF & @CRLF & _
        "v0.4.4" & @CRLF & _
        "  - 分类改为动态生成，调整下拉框和日志界面。" & @CRLF & _
        "  - 优化 reload 列表渲染和性能，更新坐标点。" & @CRLF & @CRLF & _
        "v0.4.3" & @CRLF & _
        "  - 为 3.3.5 增加 home 按钮，并补充坐标点。" & @CRLF & @CRLF & _
        "v0.4.2" & @CRLF & _
        "  - 增加 appendPos 与 fastStep，修正 1.12.1/3.3.5 坐标轴。" & @CRLF & _
        "  - 增加分类并打包 favlist.fav。" & @CRLF & @CRLF & _
        "v0.4.1" & @CRLF & _
        "  - 增加 insertPos，在选中坐标前插入新坐标点。" & @CRLF & _
        "  - 改进日志控件及日志行数限制。" & @CRLF & @CRLF & _
        "v0.4" & @CRLF & _
        "  - 增加按分类过滤传送坐标的下拉框。" & @CRLF & @CRLF & _
        "  - 增加 3.3.5 全局移动速度调整及界面控件。" & @CRLF & @CRLF & _
        "v0.3" & @CRLF & _
        "  - 增加巫妖王之怒 3.3.5 基础支持。" & @CRLF & _
        "  - 完善项目文档及 CI。" & @CRLF & @CRLF & _
        "v0.2" & @CRLF & _
        "  - 增加 1.12 支持和快捷键，扩充坐标点。" & @CRLF & _
        "  - 修复未启动 WoW 时的错误并重构部分代码。" & @CRLF & @CRLF & _
        "v0.1" & @CRLF & _
        "  - 初始版本：建立传送工具和早期坐标点。"
EndFunc
