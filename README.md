# 旺财 (WangCai)

**旺财** 取“兴旺发财”之意，是一款以**本地优先、数据自主可控**为核心理念的个人记账应用。项目基于 Flutter 构建，目标是让用户在不依赖平台会员体系的前提下，也能完整、长期、安全地管理自己的财务数据。

## 项目缘起：为什么会有旺财

这个项目并非从“做一个新 App”出发，而是来自一个长期存在的真实痛点：

- 长期使用的记账软件在**非会员**情况下大量核心功能受限，连最基础的导出与统计能力都无法正常使用，严重影响日常记账体验和数据可用性。
- 个人财务数据本质上属于高敏感信息。随着对数据安全认知的提升，我们越来越意识到：频繁接到诈骗、贷款推销电话等现象，背后可能与平台侧的数据泄露或滥用风险有关。

基于上述问题，旺财选择了明确方向：  
**把财务数据控制权交还给用户自己**。

- 账本数据默认保留在本地设备，降低对第三方平台的被动依赖；
- 可通过 WebDAV / S3 兼容协议备份到自有网盘或对象存储，实现可追溯、可迁移、可长期保存的数据资产；
- App、CLI 与 AI Skill 共用 `wangcai_core`，以 `revision` + 锁文件保证多端写入互斥；
- 功能设计以“可用、可导出、可统计”为基础能力，而不是被会员体系绑定的特权。

得益于当下 AI 编程工具的成熟，个人开发者可以更高效地打造真正贴合自身需求的记账产品。旺财也是这一实践：  
**我们可以自由定义自己的记账软件，而不是被动适应平台规则。**

## 仓库结构

| 路径 | 说明 |
|------|------|
| `lib/` | Flutter App |
| `packages/wangcai_core` | 纯 Dart 账本核心（模型、余额副作用、统计、导入、SyncClient） |
| `packages/wangcai_cli` | 命令行客户端，编译为独立可执行文件 |
| `skills/wangcai-ai` | 可独立安装的 AI Skill（自带 CLI 二进制 + 配置模板） |
| `docs/apis/` | 能力契约文档（供 Skill / 多端对齐） |

## 多端同步（WebDAV / S3）

- 账本为整文件 JSON（`LedgerBundle`），含单调递增 `revision`
- **读**：仅当 `remote.revision > local` 时用远端覆盖本地；本地已新则保持本地
- **写**：加锁后按 revision 选底稿——远端更新则先拉齐再改；本地更新或相等则保留本地再改并上传（更新云端）
- **手动推送**：远端更新且未确认/`--force` 时返回 `CONFLICT`
- **手动拉取**：远端整包覆盖本地
- 写入前加锁：远端同路径 `.lock` 租约；冲突返回 `LOCK_BUSY`
- WebDAV `putIfAbsent` 先探测存在性（兼容坚果云忽略 `If-None-Match`）
- App 首页 / 账单 / 统计进入时会 `ensureFresh`；日常记账经 `CloudLedgerBridge` 写穿
- CLI / Skill 与 App 共用同一套协议与远端账本

### 坚果云 WebDAV 示例

`~/.wangcai/config.json`（权限建议 `chmod 600`，勿提交到 Git）：

```json
{
  "protocol": "webdav",
  "deviceId": "wc_cli_mac",
  "serverUrl": "https://dav.jianguoyun.com/dav",
  "username": "你的邮箱",
  "password": "应用密码",
  "remotePath": "/wangcai/records.json"
}
```

密码请使用坚果云「安全选项」里生成的**应用密码**，不要使用登录密码。更多示例见 `packages/wangcai_cli/config.example.*.json` 与 `skills/wangcai-ai/config.example.*.json`。

## CLI 与 AI Skill

### 本机编译 CLI

```bash
cd packages/wangcai_cli
./scripts/build.sh
# 产物写入 skills/wangcai-ai/bin/wangcai-<os>-<arch>
```

运行无需安装 Dart（仅编译需要）。当前 Skill 已随包提供：

- `skills/wangcai-ai/bin/wangcai` — macOS/Linux 启动器
- `skills/wangcai-ai/bin/wangcai.cmd` — Windows 启动器
- `skills/wangcai-ai/bin/wangcai-macos-arm64` — macOS Apple Silicon 二进制

> Windows x64 需在 Windows 或 GitHub Actions（`.github/workflows/build-cli.yml`）上编译，再用 `./scripts/sync-from-ci.sh` 同步到 Skill。

### 使用 Skill（独立安装）

Skill **不依赖本仓库工作区**。将目录整体拷到个人 Skills 后即可在任意项目对话中使用：

```bash
mkdir -p ~/.cursor/skills
cp -R skills/wangcai-ai ~/.cursor/skills/wangcai-ai
chmod +x ~/.cursor/skills/wangcai-ai/bin/wangcai \
         ~/.cursor/skills/wangcai-ai/bin/wangcai-macos-arm64
```

配置好 `~/.wangcai/config.json` 后：

```bash
BIN=~/.cursor/skills/wangcai-ai/bin/wangcai
# 或直接用仓库内：skills/wangcai-ai/bin/wangcai

$BIN status
$BIN pull
$BIN accounts list
$BIN tx list --limit 20
$BIN tx add --amount 38.5 --account 支付宝 --category 餐饮 --note 午餐
$BIN stats --period month
```

命令 stdout 为 JSON：`{"ok":true,"data":...}`；失败写 stderr（如 `LOCK_BUSY`）。说明见 `skills/wangcai-ai/SKILL.md`。

### 快速自测

1. **CLI 冒烟**：`$BIN status` → `$BIN pull` → `$BIN accounts list`
2. **Skill 对话**：新开 Chat，说「用 wangcai-ai 查账本状态 / 记一笔…」，确认 Agent 调用的是 Skill 目录下的 `bin/wangcai`，而不是 `dart run` 或仓库源码
3. **锁（可选）**：远端若存在未过期的 `.lock` 且 owner 非本机，写入应返回 `LOCK_BUSY`

---

## 使用说明 (User Guide)

以下是“旺财”App 的核心使用指南，帮助您快速上手：

### 1. 记一笔 (添加账单)
*   **入口**: 在应用底部的导航栏中，点击中间醒目的 **“添加” (+号)** 按钮。
*   **操作**:
    *   在弹出的面板顶部选择类型：`支出`、`收入`、`转账`、`借出` 或 `借入`。
    *   输入金额。
    *   在下方的分类网格中选择对应的消费类别（如：餐饮、交通、购物等）。
    *   可选：修改日期和添加备注（例如：“和朋友聚餐”）。
    *   点击底部的 **“保存”**。

### 2. 查看资产与账户
*   **入口**: 底部导航栏点击 **“首页”**。
*   **操作**:
    *   **资产概览**: 页面顶部会显示您的【总资产】、【净资产】和【总负债】。
    *   **我的账户**: 向下滚动可以查看所有已绑定的账户列表（包含储蓄卡、信用卡、支付宝、微信等）。点击卡片可以查看详细余额或信用卡本期应还金额。
    *   **添加新账户**: 点击列表底部的 **“添加账户”** 按钮，输入初始余额、账户名称并选择类型即可新增账户。

### 3. 查看财务统计
*   **入口**: 底部导航栏点击 **“统计”**。
*   **操作**:
    *   **时间维度**: 顶部可切换【周】、【月】、【年】视图，对应统计范围会自动更新。
    *   **本期概览**: 顶部卡片展示本期的收入、支出与结余，并注明时间区间。
    *   **支出分布**: 环形图根据真实账单按分类聚合，展示各分类占比与金额。
    *   **支出趋势**: 柱状图按日 / 按月还原本期每一格的支出，当前格高亮；右上角显示与上一周期的同比变化。
    *   **财务洞察**: 基于真实账单自动计算，例如“相比上一周期节省 / 多花 ¥X”以及当前最多的支出分类。

### 4. 设置与数据安全 (云备份)
*   **入口**: 底部导航栏点击 **“设置”**。
*   **操作**:
    *   **个性化**: 调整应用主题（深色/浅色模式），管理分类等。
    *   **安全**: 开启面容ID/指纹保护。
    *   **云备份（WebDAV / S3）**:
        1. 在设置中点击 **“云备份 (WebDAV / S3)”**。
        2. 选择协议：`WebDAV` 或 `S3`（兼容 MinIO / R2 / OSS 等）。
        3. WebDAV：填写服务地址、用户名、密码与远端路径（例如坚果云 `https://dav.jianguoyun.com/dav` + `/wangcai/records.json`）。
        4. S3：填写 Endpoint、Region、Bucket、Object Key、Access Key / Secret；自托管建议开启 Path-style。
        5. 配置完成后可在状态页执行「立即备份」或「恢复覆盖本地」；日常记账在已配置时会自动加锁写穿云端。

---

## 功能特性

1.  **资产概览**: 全面掌握财务状况。
2.  **便捷记账**: 支出 / 收入 / 转账 / 借贷，支持云端写穿同步。
3.  **财务统计**: 周 / 月 / 年维度的支出分布、趋势与同比洞察。
4.  **账户与分类 / 预算 / 周期账单**: 本地管理，可与远端账本一并同步。
5.  **账单导入**: 支付宝 / 微信 CSV。
6.  **云备份 (WebDAV / S3)**: 加锁同步，多端互斥写入。
7.  **CLI + AI Skill**: 不依赖 App UI 亦可记账、查询与同步。

## 技术栈

*   **跨平台框架:** Flutter
*   **共享核心:** 纯 Dart 包 `wangcai_core`（无 Flutter 依赖）
*   **状态管理:** `provider`
*   **数据可视化:** `fl_chart`
*   **字体 / 图标:** `google_fonts`、`material_symbols_icons`
*   **对象存储:** WebDAV、S3 兼容（SigV4）

## 快速开始 (供开发者体验)

1.  安装并配置 Flutter SDK。
2.  克隆仓库：
    ```bash
    git clone https://github.com/atorber/wangcai.git
    cd wangcai
    ```
3.  获取依赖并运行 App：
    ```bash
    flutter pub get
    flutter run
    ```
4.  （可选）编译 CLI：
    ```bash
    cd packages/wangcai_cli && ./scripts/build.sh
    ```

## 下载与发布版本

直接下载已打包版本（如 APK / AAB）请前往 GitHub Release：

- [WangCai Releases](https://github.com/atorber/wangcai/releases)

发布建议使用 GitHub Actions 的 `Create Release (Auto Bump Patch)` 工作流。  
CLI 多平台二进制可使用 `Build Wangcai CLI` 工作流（macos-arm64 + windows-x64）。

## 项目阶段总结

截至当前阶段，旺财已完成从“可用原型”到“可日常使用 + 多端同步”的核心能力建设：

- **记账闭环已打通**：覆盖支出、收入、转账、借出、借入等主要交易类型。
- **资产视图已成体系**：账户与总览维度查看资产、负债与净值。
- **统计分析具备基础决策价值**：周 / 月 / 年维度分类占比、趋势与同比洞察。
- **数据主权路线已落地**：本地优先 + WebDAV / S3；`revision` + 文件锁支持 App / CLI / Skill 共用远端账本（含坚果云等忽略条件 PUT 头的兼容）。
- **开放调用面**：`wangcai_core` + 独立 CLI 二进制 + 可安装 Skill。

下一阶段重点：Windows CLI 产物常态化、冲突体验与核心流程回归。

## 下一步迭代路线

### P0（优先推进：稳定性与数据安全）

1. **数据可靠性增强** — 关键写入重试、冲突与回滚策略完善。
2. **备份可验证性** — 成功备份时间、校验与导出演练。
3. **基础质量保障** — 记账 / 账户 / 统计 / 同步最小回归集。
4. **CLI 多平台产物** — CI 产出 Windows 二进制并纳入 Skill `bin/`。

### P1（体验升级：效率与可读性）

1. **记账效率优化** — 常用分类置顶、快捷金额、焦点交互。
2. **统计与洞察增强** — 预算执行、异常波动提醒。
3. **信息架构打磨** — 列表 / 详情 / 设置页一致性。

### P2（能力扩展：长期可持续）

1. **多账本与场景化** — 个人 / 家庭 / 项目隔离。
2. **规则自动化** — 自动分类、周期与模板增强。
3. **生态与开放能力** — 更多自托管存储兼容。

---

欢迎通过 Issue 或 PR 参与共建。  
如果你也认同“财务数据应由自己掌控”，旺财会持续沿着“本地优先、可迁移、可验证”的路线长期迭代。
