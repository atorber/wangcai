# Finance App UI

A beautifully designed personal finance management application built with Flutter, based on a comprehensive Tailwind CSS design reference.

## Features

This repository contains the front-end UI implementation for 9 core screens:

1.  **Asset Overview (`AssetOverviewScreen`)**: Displays total assets, net worth, liabilities, and a grid of connected accounts (Debit, Credit, Cash, etc.).
2.  **Add Transaction (`AddTransactionScreen`)**: A modal bottom sheet to input new income, expenses, or transfers, featuring a bento-style category grid and amount input.
3.  **Financial Statistics (`FinancialStatsScreen`)**: Visualizes spending distribution with a donut chart and tracks daily spending trends with a bar chart using `fl_chart`.
4.  **Add Account (`AddAccountScreen`)**: A form to add new financial accounts, allowing users to set an initial balance, name, and account type.
5.  **Monthly Overview (`MonthlyOverviewScreen`)**: A summary view for a specific month, showing spending speed, recent transactions, and goal tracking progress.
6.  **Settings (`SettingsScreen`)**: Manages user profile, app preferences, security, and support options.
7.  **GitHub Sync Setup (`GithubSyncSetupScreen`)**: A flow for users to enter their GitHub Personal Access Token to enable cloud data syncing.
8.  **GitHub Sync Settings (`GithubSyncSettingsScreen`)**: Allows configuration of the target repository, file format (JSON/CSV), and sync frequency.
9.  **GitHub Sync Status (`GithubSyncStatusScreen`)**: Displays the current synchronization status, last sync time, and a manual trigger button.

## Tech Stack

*   **Framework:** Flutter
*   **Fonts:** `google_fonts` (Inter font family)
*   **Charting:** `fl_chart`
*   **Icons:** `material_symbols_icons`
*   **State Management:** `provider` (Added as a dependency for future logic implementation)

## Project Structure

```text
lib/
├── main.dart
├── screens/
│   ├── main_layout.dart               # Primary scaffold with BottomNavigationBar
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
    ├── app_colors.dart                # Centralized color palette matching the design
    └── app_theme.dart                 # Global ThemeData configuration
```

## Getting Started

1.  **Prerequisites:** Ensure you have Flutter installed and set up on your machine.
2.  **Clone the repo:**
    ```bash
    git clone <repository-url>
    cd finance_app
    ```
3.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
4.  **Run the app:**
    ```bash
    flutter run
    ```
