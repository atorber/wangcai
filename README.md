# 财务应用 UI (Finance App UI)

一个基于 Tailwind CSS 设计参考精美构建的 Flutter 个人财务管理应用程序。

## 功能特性

本仓库包含 9 个核心界面的前端 UI 实现：

1.  **资产概览 (`AssetOverviewScreen`)**: 显示总资产、净资产、总负债以及关联账户的网格列表（如储蓄卡、信用卡、现金等）。
2.  **添加账单 (`AddTransactionScreen`)**: 一个模态底部工作表（Bottom Sheet），用于输入新的收入、支出或转账记录，包含便当式（Bento-style）分类网格和金额输入功能。
3.  **财务统计 (`FinancialStatsScreen`)**: 可视化支出分布的环形图，并使用 `fl_chart` 绘制记录每日支出趋势的柱状图。
4.  **添加账户 (`AddAccountScreen`)**: 添加新财务账户的表单，允许用户设置初始余额、账户名称和账户类型。
5.  **月度概览 (`MonthlyOverviewScreen`)**: 特定月份的汇总视图，展示支出速度、最近交易活动以及储蓄目标进度。
6.  **设置 (`SettingsScreen`)**: 管理用户资料、应用偏好设置、安全以及支持选项。
7.  **GitHub 同步设置 (`GithubSyncSetupScreen`)**: 指引用户输入其 GitHub Personal Access Token (PAT) 以启用云端数据同步。
8.  **GitHub 同步配置 (`GithubSyncSettingsScreen`)**: 允许配置目标仓库、文件格式（JSON/CSV）以及同步频率。
9.  **GitHub 同步状态 (`GithubSyncStatusScreen`)**: 显示当前的同步状态、最后同步时间，以及手动触发同步的按钮。

## 技术栈

*   **框架:** Flutter
*   **字体:** `google_fonts` (使用 Inter 字体)
*   **图表:** `fl_chart`
*   **图标:** `material_symbols_icons`
*   **状态管理:** `provider` (已作为依赖项添加，供后续逻辑实现使用)

## 项目结构

```text
lib/
├── main.dart
├── screens/
│   ├── main_layout.dart               # 带底部导航栏 (BottomNavigationBar) 的主脚手架
│   ├── home/
│   │   ├── asset_overview_screen.dart
│   │   └── monthly_overview_screen.dart
│   ├── add/
│   │   └── add_transaction_screen.dart
│   ├── stats/
│   │   └── financial_stats_screen.dart
│   ├── accounts/
│   │   └── add_account_screen.dart
│   └── settings/
│       ├── settings_screen.dart
│       ├── github_sync_setup_screen.dart
│       ├── github_sync_settings_screen.dart
│       └── github_sync_status_screen.dart
└── theme/
    ├── app_colors.dart                # 匹配设计规范的集中化调色板
    └── app_theme.dart                 # 全局 ThemeData 主题配置
```

## 快速开始

1.  **准备工作:** 确保您的计算机上已安装并配置好 Flutter 环境。
2.  **克隆仓库:**
    ```bash
    git clone <repository-url>
    cd finance_app
    ```
3.  **安装依赖:**
    ```bash
    flutter pub get
    ```
4.  **运行应用:**
    ```bash
    flutter run
    ```
