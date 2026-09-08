# 设置与安全（技能可选）

对应：`AppSettingsProvider`、`SecurityProvider`、设置页「清空本地数据」。这些状态 **不进入** `AppBackupBundle`，多端不同步。

技能默认 **不必实现** 主题与生物识别；需要「重置演示账本」时可实现 `data.clear`。

---

## `settings.getTheme` / `settings.setTheme`

```json
{ "method": "settings.getTheme", "params": {} }
```

```json
{ "ok": true, "data": { "themeMode": "system", "label": "跟随系统" } }
```

`themeMode`：`system` | `light` | `dark`。

```json
{ "method": "settings.setTheme", "params": { "themeMode": "dark" } }
```

---

## `security.get` / `security.update`

```json
{ "method": "security.get", "params": {} }
```

```json
{
  "ok": true,
  "data": {
    "appLockEnabled": false,
    "biometricEnabled": true,
    "privacyModeEnabled": false
  }
}
```

```json
{
  "method": "security.update",
  "params": {
    "appLockEnabled": true,
    "biometricEnabled": true,
    "privacyModeEnabled": true
  }
}
```

App 约束：

- 开启应用锁前，系统必须已录入面容/指纹，否则拒绝
- 应用锁开启时不能关闭生物识别（提示「应用锁需要保留系统解锁」）
- 隐私模式仅影响 UI 金额打码（`¥****`），不改变存储值

技能无 UI，可忽略本接口。

---

## `data.clear`

对应设置页「清空本地数据」。不可恢复。

### 请求

```json
{
  "method": "data.clear",
  "params": { "confirm": true }
}
```

未确认 → `CONSTRAINT`。

### App 实际清空范围

| 集合 | 结果 |
|------|------|
| accounts / lenders | `[]` |
| categories | `[]`（注意：不是恢复默认分类，直到下次冷启动 `_loadFromLocal` 发现空存储才会写入默认分类） |
| budgets / recurring / transactions | `[]` |
| 应用锁 / 生物识别 / 隐私 | 全 false |
| 主题 | `system` |

**不清** WebDAV 配置与 `deviceId`。

### 响应

```json
{ "ok": true, "data": { "cleared": true } }
```

技能若操作的是远端账本，`data.clear` 应写成空 bundle 再 `sync.push`，否则只清工作副本、下次 pull 会恢复。
