"""
宠标通 · 桌面应用样式表
暖橙金色系 — 轻拟物卡片风格
"""

# 应用全局样式
APP_STYLESHEET = """
/* ===== 全局 ===== */
QWidget {
    font-family: "Microsoft YaHei", "PingFang SC", "Segoe UI", sans-serif;
    color: #3d2e1f;
}

/* ===== 主窗口背景 ===== */
QMainWindow {
    background-color: #FFFBEB;
}

/* ===== 滚动区域 ===== */
QScrollArea {
    border: none;
    background: transparent;
}
QScrollArea QWidget#scrollContent {
    background: transparent;
}
QScrollBar:vertical {
    width: 6px;
    background: transparent;
    border: none;
}
QScrollBar::handle:vertical {
    background: #d0c8b8;
    border-radius: 3px;
    min-height: 30px;
}
QScrollBar::handle:vertical:hover {
    background: #b8a890;
}
QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical {
    height: 0px;
}

/* ===== 卡片面板 ===== */
QFrame#cardPanel {
    background: #ffffff;
    border: 1px solid #ede5d5;
    border-radius: 18px;
}

/* ===== 图片网格 ===== */
QFrame#gridCell {
    background: #f8f5ee;
    border: 2px solid #e8e0ce;
    border-radius: 14px;
}
QFrame#gridCell:hover {
    border-color: #F59E0B;
}

QFrame#addCell {
    background: #FEF3C7;
    border: 2px dashed #F59E0B;
    border-radius: 14px;
}
QFrame#addCell:hover {
    background: #FDE68A;
    border-color: #D97706;
}

/* ===== 删除按钮 ===== */
QPushButton#deleteBtn {
    background: #EF4444;
    color: white;
    border: none;
    border-radius: 10px;
    font-weight: bold;
    font-size: 14px;
    min-width: 24px;
    max-width: 24px;
    min-height: 24px;
    max-height: 24px;
}
QPushButton#deleteBtn:hover {
    background: #DC2626;
}

/* ===== 替换按钮 ===== */
QPushButton#replaceBtn {
    background: rgba(59, 130, 246, 0.85);
    color: white;
    border: none;
    border-radius: 10px;
    font-size: 11px;
    padding: 3px 8px;
}
QPushButton#replaceBtn:hover {
    background: #3B82F6;
}

/* ===== 主要按钮（审核提交） ===== */
QPushButton#submitBtn {
    background: qlineargradient(x1:0, y1:0, x2:0, y2:1,
        stop:0 #F59E0B, stop:1 #D97706);
    color: #ffffff;
    border: none;
    border-radius: 22px;
    font-size: 18px;
    font-weight: bold;
    padding: 16px 0;
    letter-spacing: 3px;
}
QPushButton#submitBtn:hover {
    background: qlineargradient(x1:0, y1:0, x2:0, y2:1,
        stop:0 #FBBF24, stop:1 #F59E0B);
}
QPushButton#submitBtn:pressed {
    background: qlineargradient(x1:0, y1:0, x2:0, y2:1,
        stop:0 #D97706, stop:1 #B45309);
}
QPushButton#submitBtn:disabled {
    background: qlineargradient(x1:0, y1:0, x2:0, y2:1,
        stop:0 #FCD34D, stop:1 #FBBF24);
    color: rgba(255,255,255,0.7);
}

/* ===== 模型选择器卡片 ===== */
QFrame#modelCard {
    background: #F8FAFC;
    border: 1px solid #E3E8EF;
    border-radius: 16px;
}
QFrame#modelCard:hover {
    border-color: #F59E0B;
    background: #FEF3C7;
}

/* ===== 快速模型按钮 ===== */
QPushButton#quickModelBtn {
    background: #ffffff;
    border: 2px solid #E8ECF0;
    border-radius: 14px;
    padding: 12px 8px;
    font-size: 13px;
    font-weight: 600;
    color: #3D5A80;
}
QPushButton#quickModelBtn:hover {
    border-color: #F59E0B;
    background: #FEF3C7;
}
QPushButton#quickModelBtn[active="true"] {
    background: qlineargradient(x1:0, y1:0, x2:0, y2:1,
        stop:0 #FEF3C7, stop:1 #FDE68A);
    border-color: #F59E0B;
    color: #B45309;
}

/* ===== 下拉模型选项 ===== */
QPushButton#modelOption {
    background: #faf6ee;
    border: 1px solid #e8e0ce;
    border-radius: 12px;
    padding: 12px 16px;
    text-align: left;
    font-size: 14px;
}
QPushButton#modelOption:hover {
    background: #FEF3C7;
    border-color: #F59E0B;
}
QPushButton#modelOption[selected="true"] {
    background: #FEF3C7;
    border-color: #F59E0B;
    font-weight: bold;
}

/* ===== 分割线 ===== */
QFrame#divider {
    background: qlineargradient(x1:0, y1:0, x2:1, y2:0,
        stop:0 transparent, stop:0.5 #e2e8f0, stop:1 transparent);
    max-height: 2px;
}

/* ===== 结果区域 ===== */
QTextEdit#resultView {
    background: #ffffff;
    border: 1px solid #ede5d5;
    border-radius: 14px;
    padding: 18px;
    font-size: 14px;
    line-height: 1.7;
    selection-background-color: #FEF3C7;
}

/* ===== 复制/分享按钮 ===== */
QPushButton#actionBtn {
    border: none;
    border-radius: 22px;
    padding: 10px 24px;
    font-size: 14px;
    font-weight: 600;
    color: white;
}
QPushButton#copyBtn {
    background: qlineargradient(x1:0, y1:0, x2:0, y2:1,
        stop:0 #10B981, stop:1 #059669);
}
QPushButton#copyBtn:hover {
    background: qlineargradient(x1:0, y1:0, x2:0, y2:1,
        stop:0 #34D399, stop:1 #10B981);
}
QPushButton#shareBtn {
    background: qlineargradient(x1:0, y1:0, x2:0, y2:1,
        stop:0 #F59E0B, stop:1 #D97706);
}
QPushButton#shareBtn:hover {
    background: qlineargradient(x1:0, y1:0, x2:0, y2:1,
        stop:0 #FBBF24, stop:1 #F59E0B);
}

/* ===== 加载覆盖层 ===== */
QFrame#loadingOverlay {
    background: rgba(0, 0, 0, 0.45);
    border-radius: 0px;
}
QFrame#loadingCard {
    background: #f7f2e7;
    border: 2px solid #ede5d5;
    border-radius: 24px;
}

/* ===== 输入框 ===== */
QLineEdit {
    border: 2px solid #e8e0ce;
    border-radius: 12px;
    padding: 10px 14px;
    font-size: 14px;
    background: #faf8f2;
}
QLineEdit:focus {
    border-color: #F59E0B;
    background: #ffffff;
}

/* ===== 标签 ===== */
QLabel#sectionTitle {
    font-size: 16px;
    font-weight: bold;
    color: #1A1A2E;
}
QLabel#sectionSubtitle {
    font-size: 12px;
    color: #8E99A4;
}
QLabel#modelName {
    font-size: 15px;
    font-weight: 600;
    color: #1A1A2E;
}
QLabel#modelDesc {
    font-size: 11px;
    color: #8E99A4;
}
QLabel#footerText {
    font-size: 12px;
    color: #8E99A4;
}
"""
