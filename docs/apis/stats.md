# 统计接口 `stats.build`

对应：`StatsService.build`、`FinancialStatsScreen`。纯计算，不写账本。

## 请求

```json
{
  "method": "stats.build",
  "params": {
    "period": "month",
    "now": "2026-09-08T12:00:00.000"
  }
}
```

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `period` | `week` \| `month` \| `year` | 是 | |
| `now` | string | 否 | 缺省为当前时间；测试/回溯时可注入 |

输入账单来自当前账本全部 `transactions`，由实现内部读取。

## 区间（左闭右开）

以 `now` 的日期部分为基准。

| period | 本期 | 上期 |
|--------|------|------|
| week | 本周一 00:00 → 下周一 00:00 | 再往前 7 天 |
| month | 本月 1 日 → 下月 1 日 | 上月 1 日 → 本月 1 日 |
| year | 本年 1 月 1 日 → 下年 1 月 1 日 | 上年 1 月 1 日 → 本年 1 月 1 日 |

过滤：`!date.isBefore(start) && date.isBefore(end)`。

## 响应

```json
{
  "ok": true,
  "data": {
    "period": "month",
    "rangeStart": "2026-09-01T00:00:00.000",
    "rangeEnd": "2026-10-01T00:00:00.000",
    "totalIncome": 12000.0,
    "totalExpense": 2840.0,
    "balance": 9160.0,
    "avgDailyExpense": 94.67,
    "expenseDeltaRatio": -0.12,
    "previousTotalExpense": 3227.0,
    "categoryBreakdown": [
      { "category": "餐饮", "amount": 1136.0, "ratio": 0.4 }
    ],
    "trendPoints": [
      {
        "label": "1",
        "date": "2026-09-01T00:00:00.000",
        "amount": 120.0,
        "isPeak": false,
        "isCurrent": false
      }
    ],
    "budgetProgress": [
      {
        "categoryId": "c_food",
        "label": "餐饮",
        "monthlyLimit": 2000.0,
        "used": 1136.0,
        "ratio": 0.568,
        "overAmount": 0
      }
    ]
  }
}
```

| 字段 | 说明 |
|------|------|
| `totalIncome` | 本期 `type=income` 金额之和 |
| `totalExpense` | 本期 `type=expense` 金额之和 |
| `balance` | `totalIncome - totalExpense`（App 展示「结余」） |
| `avgDailyExpense` | `totalExpense / 区间天数`；周=7，月=当月天数，年=365 或 366（按 `end-start` 的 `inDays`） |
| `expenseDeltaRatio` | `(本期支出 - 上期支出) / 上期支出`；上期支出为 0 时为 `null` |
| `previousTotalExpense` | 上期支出 |
| `categoryBreakdown` | 仅支出，按金额降序；`ratio = amount / totalExpense`；无支出则为 `[]` |
| `trendPoints` | 见下 |
| `budgetProgress` | App 统计页额外展示；`StatsService` 本身不含此项，由 UI 用本月支出 + `budgets` 拼出。技能应一并返回 |

转账、借出、借入 **不计入** 收入/支出统计。

## 趋势桶

| period | 桶 | label |
|--------|----|-------|
| week | 7 天 | 一…日 |
| month | 当月每一天 | `"1"` … `"30"` |
| year | 12 个月 | `"1月"` … `"12月"` |

- `isPeak`：该桶金额等于本期最大支出（最大值为 0 则全 false）
- `isCurrent`：桶下标等于 `now` 所在桶

## 洞察文案（App 展示逻辑，技能可复用）

- 上期有数据且 `expenseDeltaRatio < 0`：`相比上一周期节省 ¥X`
- `expenseDeltaRatio > 0`：`相比上一周期多花 ¥X`
- 分类占比第一：`当前最多支出分类：{category}`
