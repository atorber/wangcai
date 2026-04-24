# 旺财 (WangCai)

**旺财** 是一款设计精美、功能实用的个人记账手机应用，使用 Flutter 构建，旨在帮助您轻松管理个人财务、追踪支出并实现储蓄目标。

## 功能特性

旺财目前已实现以下核心功能界面的构建，为您提供流畅的记账体验：

1.  **资产概览 (`AssetOverviewScreen`)**: 全面掌握您的财务状况。显示总资产、净资产、总负债，并以网格列表的形式展示您关联的各个账户（如储蓄卡、信用卡、支付宝、微信支付、现金等）。
2.  **便捷记账 (`AddTransactionScreen`)**: 随时随地记录收支。通过模态底部工作表（Bottom Sheet），快速输入收入、支出或转账记录，提供直观的分类网格和金额键盘。
3.  **财务统计 (`FinancialStatsScreen`)**: 洞察您的消费习惯。利用直观的环形图展示支出分布，配合柱状图追踪每日支出趋势，让您的资金流向一目了然。
4.  **账户管理 (`AddAccountScreen`)**: 轻松添加和管理您的各类财务账户。您可以设置账户名称、选择账户类型并设定初始余额。
5.  **月度报告 (`MonthlyOverviewScreen`)**: 每月财务情况总结。展示当月的支出速度、最近的交易活动，并跟进您的储蓄目标进度。
6.  **个性化设置 (`SettingsScreen`)**: 定制您的应用体验。管理用户资料、应用偏好设置（如主题、分类管理）、安全选项（面容ID/密码）以及数据导出功能。
7.  **数据云同步 (GitHub Sync)**:
    - **设置 (`GithubSyncSetupScreen`)**: 输入您的 GitHub Personal Access Token 开启安全的数据同步。
    - **配置 (`GithubSyncSettingsScreen`)**: 自由选择同步的目标仓库、文件格式（支持 JSON/CSV）以及同步频率（实时、每日或手动）。
    - **状态 (`GithubSyncStatusScreen`)**: 随时查看当前的同步状态、最后同步时间，并可一键手动触发同步，确保数据安全不丢失。

## 技术栈

*   **跨平台框架:** Flutter
*   **字体设计:** `google_fonts` (采用现代化无衬线字体 Inter)
*   **数据可视化:** `fl_chart` (用于生成精美的统计图表)
*   **图标库:** `material_symbols_icons`
*   **状态管理:** `provider` (为后续业务逻辑处理和数据状态管理提供基础)

## 项目结构

```text
lib/
├── main.dart
├── screens/
│   ├── main_layout.dart               # 包含底部导航栏 (BottomNavigationBar) 的主界面框架
│   ├── home/
│   │   ├── asset_overview_screen.dart   # 资产概览
│   │   └── monthly_overview_screen.dart # 月度概览
│   ├── add/
│   │   └── add_transaction_screen.dart  # 记账面板
│   ├── stats/
│   │   └── financial_stats_screen.dart  # 财务统计
│   ├── accounts/
│   │   └── add_account_screen.dart      # 添加账户
│   └── settings/
│       ├── settings_screen.dart           # 设置中心
│       ├── github_sync_setup_screen.dart  # GitHub 同步向导
│       ├── github_sync_settings_screen.dart # 同步偏好设置
│       └── github_sync_status_screen.dart   # 同步状态面板
└── theme/
    ├── app_colors.dart                # 全局调色板配置
    └── app_theme.dart                 # 应用全局主题配置
```

## 快速开始

如果您想在本地运行和体验“旺财”应用：

1.  **准备工作:** 确保您的计算机上已安装并配置好 Flutter SDK 开发环境。
2.  **克隆仓库:**
    ```bash
    git clone <repository-url>
    cd finance_app
    ```
3.  **获取依赖:**
    ```bash
    flutter pub get
    ```
4.  **运行应用:**
    ```bash
    flutter run
    ```
