import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:wangcai_cli/cli_runtime.dart';
import 'package:wangcai_core/wangcai_core.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: '显示帮助')
    ..addOption('config', help: '配置文件路径，默认 ~/.wangcai/config.json')
    ..addOption('ledger', help: '本地工作副本路径，默认 ~/.wangcai/ledger.json');

  void common(ArgParser c) {
    c
      ..addOption('config', help: '覆盖全局 --config')
      ..addOption('ledger', help: '覆盖全局 --ledger');
  }

  common(parser.addCommand('status'));
  common(parser.addCommand('pull'));
  final push = parser.addCommand('push');
  common(push);
  push.addFlag('force', negatable: false, help: '强制覆盖远端更新版本');

  final tx = parser.addCommand('tx');
  final txAdd = tx.addCommand('add');
  common(txAdd);
  txAdd
    ..addOption(
      'type',
      defaultsTo: 'expense',
      allowed: TransactionType.values.map((e) => e.name).toList(),
    )
    ..addOption('amount', mandatory: true)
    ..addOption('account', help: '账户 id 或名称', mandatory: true)
    ..addOption('category', defaultsTo: '其他')
    ..addOption('note', defaultsTo: '')
    ..addOption('date', help: 'ISO-8601，默认现在')
    ..addOption('transfer-account')
    ..addOption('lender')
    ..addOption(
      'client',
      defaultsTo: 'agent',
      allowed: const ['app', 'agent', 'import', 'recurring', 'cli', 'skill'],
      help: '操作端：app|agent（默认 agent）|import|recurring',
    );
  final txList = tx.addCommand('list');
  common(txList);
  txList
    ..addOption('limit', defaultsTo: '20')
    ..addOption('offset', defaultsTo: '0')
    ..addOption('type')
    ..addOption('keyword');
  final txDelete = tx.addCommand('delete');
  common(txDelete);
  txDelete.addOption('id', mandatory: true);

  final accounts = parser.addCommand('accounts');
  common(accounts.addCommand('list'));
  final accountsAdd = accounts.addCommand('add');
  common(accountsAdd);
  accountsAdd
    ..addOption('name', mandatory: true)
    ..addOption(
      'type',
      defaultsTo: 'debitCard',
      allowed: AccountType.values.map((e) => e.name).toList(),
    )
    ..addOption('balance', defaultsTo: '0')
    ..addOption('credit-limit')
    ..addOption('billing-day')
    ..addOption('payment-day');
  final accountsUpdate = accounts.addCommand('update');
  common(accountsUpdate);
  accountsUpdate
    ..addOption('id', help: '账户 id 或名称')
    ..addOption('account', help: '账户 id 或名称（与 --id 二选一）')
    ..addOption('name', help: '新名称，默认保持不变')
    ..addOption('balance', help: '新余额', mandatory: true)
    ..addFlag(
      'record-diff',
      negatable: false,
      help: '将「新余额−原余额」补记为收入/支出',
    )
    ..addOption('credit-limit')
    ..addOption('billing-day')
    ..addOption('payment-day');
  final accountsDelete = accounts.addCommand('delete');
  common(accountsDelete);
  accountsDelete
    ..addOption('id', help: '账户 id 或名称')
    ..addOption('account', help: '账户 id 或名称（与 --id 二选一）');

  // 应收/应付 = Lender（不是 AccountType）
  final lenders = parser.addCommand('lenders');
  common(lenders.addCommand('list'));
  final lendersAdd = lenders.addCommand('add');
  common(lendersAdd);
  lendersAdd.addOption('name', mandatory: true, help: '对方名称');
  final lendersUpdate = lenders.addCommand('update');
  common(lendersUpdate);
  lendersUpdate
    ..addOption('id', help: '应收/应付 id 或名称')
    ..addOption('lender', help: '应收/应付 id 或名称（与 --id 二选一）')
    ..addOption('name', help: '新名称')
    ..addOption('balance', help: '新余额，默认保持不变');
  final lendersDelete = lenders.addCommand('delete');
  common(lendersDelete);
  lendersDelete
    ..addOption('id', help: '应收/应付 id 或名称')
    ..addOption('lender', help: '应收/应付 id 或名称（与 --id 二选一）');

  final categories = parser.addCommand('categories');
  common(categories.addCommand('list'));
  final catAdd = categories.addCommand('add');
  common(catAdd);
  catAdd
    ..addOption('label', mandatory: true)
    ..addOption('icon', defaultsTo: 'other');
  final catUpdate = categories.addCommand('update');
  common(catUpdate);
  catUpdate
    ..addOption('id', mandatory: true)
    ..addOption('label', mandatory: true)
    ..addOption('icon', defaultsTo: 'other');
  final catDelete = categories.addCommand('delete');
  common(catDelete);
  catDelete.addOption('id', mandatory: true);

  final budgets = parser.addCommand('budgets');
  common(budgets.addCommand('list'));
  final budgetUpsert = budgets.addCommand('upsert');
  common(budgetUpsert);
  budgetUpsert
    ..addOption('category-id', help: '分类 id')
    ..addOption('category', help: '分类 label（与 category-id 二选一）')
    ..addOption('limit', mandatory: true);
  final budgetDelete = budgets.addCommand('delete');
  common(budgetDelete);
  budgetDelete
    ..addOption('category-id')
    ..addOption('category');

  final recurring = parser.addCommand('recurring');
  common(recurring.addCommand('list'));
  final recUpsert = recurring.addCommand('upsert');
  common(recUpsert);
  recUpsert
    ..addOption('id', help: '更新时传入已有 id')
    ..addOption('title', mandatory: true)
    ..addOption(
      'type',
      defaultsTo: 'expense',
      allowed: ['expense', 'income'],
    )
    ..addOption('amount', mandatory: true)
    ..addOption('category', defaultsTo: '账单')
    ..addOption('account', mandatory: true)
    ..addOption(
      'frequency',
      defaultsTo: 'monthly',
      allowed: ['monthly', 'weekly'],
    )
    ..addOption('day-of-month', defaultsTo: '1')
    ..addOption('weekday', defaultsTo: '1', help: '1=周一 … 7=周日')
    ..addOption('note', defaultsTo: '')
    ..addFlag('disabled', negatable: false);
  final recDelete = recurring.addCommand('delete');
  common(recDelete);
  recDelete.addOption('id', mandatory: true);
  common(recurring.addCommand('run'));

  final importCmd = parser.addCommand('import');
  final importParse = importCmd.addCommand('parse');
  common(importParse);
  importParse.addOption('file', mandatory: true, help: '支付宝/微信 CSV 路径');
  final importCommit = importCmd.addCommand('commit');
  common(importCommit);
  importCommit
    ..addOption('file', mandatory: true)
    ..addOption('account', mandatory: true)
    ..addOption('indexes', help: '逗号分隔行下标，默认全部');

  final stats = parser.addCommand('stats');
  common(stats);
  stats.addOption(
    'period',
    allowed: ['week', 'month', 'year'],
    defaultsTo: 'month',
  );

  ArgResults result;
  try {
    result = parser.parse(arguments);
  } on FormatException catch (e) {
    _fail(e.message);
    return;
  }

  if (result['help'] == true || result.command == null) {
    stdout.writeln(_usage(parser));
    return;
  }

  final runtime = await CliRuntime.load(
    configPath: result['config'] as String?,
    ledgerPath: result['ledger'] as String?,
  );

  try {
    final command = result.command!;
    switch (command.name) {
      case 'status':
        await _cmdStatus(runtime);
        break;
      case 'pull':
        await _cmdPull(runtime);
        break;
      case 'push':
        await _cmdPush(runtime, force: command['force'] == true);
        break;
      case 'tx':
        await _cmdTx(runtime, command);
        break;
      case 'accounts':
        await _cmdAccounts(runtime, command);
        break;
      case 'lenders':
        await _cmdLenders(runtime, command);
        break;
      case 'categories':
        await _cmdCategories(runtime, command);
        break;
      case 'budgets':
        await _cmdBudgets(runtime, command);
        break;
      case 'recurring':
        await _cmdRecurring(runtime, command);
        break;
      case 'import':
        await _cmdImport(runtime, command);
        break;
      case 'stats':
        await _cmdStats(runtime, command);
        break;
      default:
        _fail('未知命令：${command.name}');
    }
  } on CloudSyncException catch (e) {
    _fail(e.message, code: e.code ?? 'SYNC_FAILED');
  } on LedgerException catch (e) {
    _fail(e.message, code: e.code);
  } catch (e) {
    _fail('$e');
  }
}

String _usage(ArgParser parser) => '''
旺财 CLI（wangcai_core + WebDAV/S3 加锁同步）

同步: status | pull | push [--force]
账单: tx add|list|delete
账户: accounts list|add|update|delete
应收/应付: lenders list|add|update|delete
分类: categories list|add|update|delete
预算: budgets list|upsert|delete
周期: recurring list|upsert|delete|run
导入: import parse|commit --file xx.csv --account 支付宝
统计: stats --period month

配置默认 ~/.wangcai/config.json

${parser.usage}
''';

Future<void> _cmdStatus(CliRuntime runtime) async {
  await runtime.loadLocal();
  final localBefore = runtime.ledger.revision;
  final remoteRevision = await runtime.client.fetchRemoteRevision();
  await runtime.client.ensureFresh(runtime.ledger);
  await runtime.saveLocal();
  final localRevision = runtime.ledger.revision;
  final String alignment;
  if (remoteRevision == null) {
    alignment = 'no_remote';
  } else if (remoteRevision > localBefore) {
    alignment = 'pulled_remote';
  } else if (localBefore > remoteRevision) {
    alignment = 'local_ahead';
  } else {
    alignment = 'in_sync';
  }
  _ok({
    'protocol': runtime.config.protocol.name,
    'folderPath': runtime.config.folderPath,
    'ledgerPath': runtime.config.ledgerPath,
    'revisionPath': runtime.config.revisionPath,
    'lockPath': runtime.config.lockPath,
    'localRevision': localRevision,
    'remoteRevision': remoteRevision,
    'alignment': alignment,
    'totalAssets': runtime.ledger.totalAssets,
    'totalLiabilities': runtime.ledger.totalLiabilities,
    'netAssets': runtime.ledger.netAssets,
    'accountCount': runtime.ledger.accounts.length,
    'transactionCount': runtime.ledger.transactions.length,
    'categoryCount': runtime.ledger.categories.length,
    'budgetCount': runtime.ledger.budgets.length,
    'recurringCount': runtime.ledger.recurringRules.length,
  });
}

Future<void> _cmdPull(CliRuntime runtime) async {
  final bundle = await runtime.client.pullReplace(runtime.ledger);
  await runtime.saveLocal();
  _ok({
    'revision': bundle.revision,
    'transactionCount': bundle.transactions.length,
    'accountCount': bundle.accounts.length,
  });
}

Future<void> _cmdPush(CliRuntime runtime, {required bool force}) async {
  await runtime.loadLocal();
  final bundle = await runtime.client.pushLocal(runtime.ledger, force: force);
  await runtime.saveLocal();
  _ok({
    'revision': bundle.revision,
    'exportedAt': bundle.exportedAt.toIso8601String(),
  });
}

Future<void> _cmdTx(CliRuntime runtime, ArgResults command) async {
  final sub = command.command;
  if (sub == null) {
    _fail('请使用 wangcai tx add|list|delete');
    return;
  }
  switch (sub.name) {
    case 'add':
      final type = transactionTypeFromName(sub['type'] as String? ?? 'expense');
      final amount = double.tryParse(sub['amount'] as String? ?? '');
      if (amount == null) {
        _fail('amount 无效', code: 'INVALID_PARAMS');
        return;
      }
      final accountKey = sub['account'] as String;
      final record = await runtime.client.writeTransaction(runtime.ledger, (
        ledger,
      ) async {
        final account = _resolveAccount(ledger, accountKey);
        String? transferId;
        final transferKey = sub['transfer-account'] as String?;
        if (transferKey != null && transferKey.isNotEmpty) {
          transferId = _resolveAccount(ledger, transferKey).id;
        }
        String? lenderId;
        final lenderKey = sub['lender'] as String?;
        if (lenderKey != null && lenderKey.isNotEmpty) {
          lenderId = _resolveLender(ledger, lenderKey).id;
        }
        final dateRaw = sub['date'] as String?;
        final date = dateRaw == null || dateRaw.isEmpty
            ? DateTime.now()
            : (DateTime.tryParse(dateRaw) ?? DateTime.now());
        return ledger.createTransaction(
          type: type,
          amount: amount,
          category: sub['category'] as String? ?? '其他',
          accountId: account.id,
          transferAccountId: transferId,
          lenderId: lenderId,
          date: date,
          note: sub['note'] as String? ?? '',
          client: transactionClientFromName(sub['client'] as String? ?? 'agent'),
        );
      });
      await runtime.saveLocal();
      _ok({'record': record.toJson(), 'revision': runtime.ledger.revision});
    case 'list':
      await runtime.ensureFreshRead();
      final typeName = sub['type'] as String?;
      final items = runtime.ledger.queryPage(
        offset: int.tryParse(sub['offset'] as String? ?? '0') ?? 0,
        limit: int.tryParse(sub['limit'] as String? ?? '20') ?? 20,
        filter: TransactionQueryFilter(
          type: typeName == null || typeName.isEmpty
              ? null
              : transactionTypeFromName(typeName),
          keyword: sub['keyword'] as String?,
        ),
      );
      _ok({
        'revision': runtime.ledger.revision,
        'items': items.map((e) => e.toJson()).toList(growable: false),
      });
    case 'delete':
      final id = sub['id'] as String;
      await runtime.client.writeTransaction(runtime.ledger, (ledger) async {
        ledger.deleteTransaction(id);
      });
      await runtime.saveLocal();
      _ok({'deletedId': id, 'revision': runtime.ledger.revision});
    default:
      _fail('未知子命令：${sub.name}');
  }
}

Future<void> _cmdAccounts(CliRuntime runtime, ArgResults command) async {
  final sub = command.command;
  if (sub == null) {
    _fail('请使用 wangcai accounts list|add|update');
    return;
  }
  switch (sub.name) {
    case 'list':
      await runtime.ensureFreshRead();
      _ok({
        'revision': runtime.ledger.revision,
        'accounts': runtime.ledger.accounts
            .map((e) => e.toJson())
            .toList(growable: false),
        'lenders': runtime.ledger.lenders
            .map((e) => e.toJson())
            .toList(growable: false),
        'totalAssets': runtime.ledger.totalAssets,
        'netAssets': runtime.ledger.netAssets,
      });
    case 'add':
      final balance = double.tryParse(sub['balance'] as String? ?? '0') ?? 0;
      final creditLimit = double.tryParse(sub['credit-limit'] as String? ?? '');
      final billingDay = int.tryParse(sub['billing-day'] as String? ?? '');
      final paymentDay = int.tryParse(sub['payment-day'] as String? ?? '');
      final account = await runtime.client.writeTransaction(runtime.ledger, (
        ledger,
      ) async {
        return ledger.createAccount(
          name: sub['name'] as String,
          type: accountTypeFromName(sub['type'] as String? ?? 'debitCard'),
          balance: balance,
          creditLimit: creditLimit,
          billingDay: billingDay,
          paymentDay: paymentDay,
        );
      });
      await runtime.saveLocal();
      _ok({'account': account.toJson(), 'revision': runtime.ledger.revision});
    case 'update':
      final key = (sub['id'] as String?)?.trim().isNotEmpty == true
          ? sub['id'] as String
          : sub['account'] as String?;
      if (key == null || key.trim().isEmpty) {
        _fail('请提供 --id 或 --account');
        return;
      }
      final balance = double.tryParse(sub['balance'] as String? ?? '');
      if (balance == null) {
        _fail('请提供合法 --balance');
        return;
      }
      final recordDiff = sub['record-diff'] as bool? ?? false;
      final creditLimit = double.tryParse(sub['credit-limit'] as String? ?? '');
      final billingDay = int.tryParse(sub['billing-day'] as String? ?? '');
      final paymentDay = int.tryParse(sub['payment-day'] as String? ?? '');
      final account = await runtime.client.writeTransaction(runtime.ledger, (
        ledger,
      ) async {
        final current = _resolveAccount(ledger, key);
        return ledger.updateAccount(
          id: current.id,
          name: (sub['name'] as String?)?.trim().isNotEmpty == true
              ? sub['name'] as String
              : current.name,
          balance: balance,
          creditLimit: creditLimit ?? current.creditLimit,
          billingDay: billingDay ?? current.billingDay,
          paymentDay: paymentDay ?? current.paymentDay,
          recordBalanceDifference: recordDiff,
          client: TransactionClient.agent,
        );
      });
      await runtime.saveLocal();
      _ok({
        'account': account.toJson(),
        'recordDiff': recordDiff,
        'revision': runtime.ledger.revision,
      });
    case 'delete':
      final key = (sub['id'] as String?)?.trim().isNotEmpty == true
          ? sub['id'] as String
          : sub['account'] as String?;
      if (key == null || key.trim().isEmpty) {
        _fail('请提供 --id 或 --account');
        return;
      }
      final deletedId = await runtime.client.writeTransaction(runtime.ledger, (
        ledger,
      ) async {
        final current = _resolveAccount(ledger, key);
        ledger.deleteAccount(current.id);
        return current.id;
      });
      await runtime.saveLocal();
      _ok({'deletedId': deletedId, 'revision': runtime.ledger.revision});
    default:
      _fail('未知子命令：${sub.name}');
  }
}

Future<void> _cmdLenders(CliRuntime runtime, ArgResults command) async {
  final sub = command.command;
  if (sub == null) {
    _fail('请使用 wangcai lenders list|add|update');
    return;
  }
  switch (sub.name) {
    case 'list':
      await runtime.ensureFreshRead();
      _ok({
        'revision': runtime.ledger.revision,
        'lenders': runtime.ledger.lenders
            .map((e) => e.toJson())
            .toList(growable: false),
      });
    case 'add':
      final lender = await runtime.client.writeTransaction(runtime.ledger, (
        ledger,
      ) async {
        return ledger.createLender(sub['name'] as String);
      });
      await runtime.saveLocal();
      _ok({'lender': lender.toJson(), 'revision': runtime.ledger.revision});
    case 'update':
      final key = (sub['id'] as String?)?.trim().isNotEmpty == true
          ? sub['id'] as String
          : sub['lender'] as String?;
      if (key == null || key.trim().isEmpty) {
        _fail('请提供 --id 或 --lender');
        return;
      }
      final nameOpt = (sub['name'] as String?)?.trim();
      final balanceOpt = double.tryParse(sub['balance'] as String? ?? '');
      if ((nameOpt == null || nameOpt.isEmpty) && balanceOpt == null) {
        _fail('请提供 --name 和/或 --balance');
        return;
      }
      final lender = await runtime.client.writeTransaction(runtime.ledger, (
        ledger,
      ) async {
        final current = _resolveLender(ledger, key);
        return ledger.updateLender(
          id: current.id,
          name: (nameOpt == null || nameOpt.isEmpty) ? current.name : nameOpt,
          balance: balanceOpt ?? current.balance,
        );
      });
      await runtime.saveLocal();
      _ok({'lender': lender.toJson(), 'revision': runtime.ledger.revision});
    case 'delete':
      final key = (sub['id'] as String?)?.trim().isNotEmpty == true
          ? sub['id'] as String
          : sub['lender'] as String?;
      if (key == null || key.trim().isEmpty) {
        _fail('请提供 --id 或 --lender');
        return;
      }
      final deletedId = await runtime.client.writeTransaction(runtime.ledger, (
        ledger,
      ) async {
        final current = _resolveLender(ledger, key);
        ledger.deleteLender(current.id);
        return current.id;
      });
      await runtime.saveLocal();
      _ok({'deletedId': deletedId, 'revision': runtime.ledger.revision});
    default:
      _fail('未知子命令：${sub.name}');
  }
}

Future<void> _cmdCategories(CliRuntime runtime, ArgResults command) async {
  final sub = command.command;
  if (sub == null) {
    _fail('请使用 wangcai categories list|add|update|delete');
    return;
  }
  switch (sub.name) {
    case 'list':
      await runtime.ensureFreshRead();
      _ok({
        'revision': runtime.ledger.revision,
        'categories': runtime.ledger.categories
            .map((e) => e.toJson())
            .toList(growable: false),
      });
    case 'add':
      final category = await runtime.client.writeTransaction(runtime.ledger, (
        ledger,
      ) async {
        return ledger.createCategory(
          label: sub['label'] as String,
          iconKey: sub['icon'] as String? ?? 'other',
        );
      });
      await runtime.saveLocal();
      _ok({'category': category.toJson(), 'revision': runtime.ledger.revision});
    case 'update':
      final category = await runtime.client.writeTransaction(runtime.ledger, (
        ledger,
      ) async {
        return ledger.updateCategory(
          id: sub['id'] as String,
          label: sub['label'] as String,
          iconKey: sub['icon'] as String? ?? 'other',
        );
      });
      await runtime.saveLocal();
      _ok({'category': category.toJson(), 'revision': runtime.ledger.revision});
    case 'delete':
      final id = sub['id'] as String;
      await runtime.client.writeTransaction(runtime.ledger, (ledger) async {
        ledger.deleteCategory(id);
      });
      await runtime.saveLocal();
      _ok({'deletedId': id, 'revision': runtime.ledger.revision});
    default:
      _fail('未知子命令：${sub.name}');
  }
}

Future<void> _cmdBudgets(CliRuntime runtime, ArgResults command) async {
  final sub = command.command;
  if (sub == null) {
    _fail('请使用 wangcai budgets list|upsert|delete');
    return;
  }
  switch (sub.name) {
    case 'list':
      await runtime.ensureFreshRead();
      _ok({
        'revision': runtime.ledger.revision,
        'budgets': runtime.ledger.budgets
            .map((e) => e.toJson())
            .toList(growable: false),
      });
    case 'upsert':
      final limit = double.tryParse(sub['limit'] as String? ?? '');
      if (limit == null) {
        _fail('limit 无效', code: 'INVALID_PARAMS');
        return;
      }
      final budget = await runtime.client.writeTransaction(runtime.ledger, (
        ledger,
      ) async {
        final categoryId = _resolveCategoryId(
          ledger,
          categoryId: sub['category-id'] as String?,
          categoryLabel: sub['category'] as String?,
        );
        return ledger.upsertBudget(
          categoryId: categoryId,
          monthlyLimit: limit,
        );
      });
      await runtime.saveLocal();
      _ok({'budget': budget.toJson(), 'revision': runtime.ledger.revision});
    case 'delete':
      await runtime.client.writeTransaction(runtime.ledger, (ledger) async {
        final categoryId = _resolveCategoryId(
          ledger,
          categoryId: sub['category-id'] as String?,
          categoryLabel: sub['category'] as String?,
        );
        ledger.deleteBudget(categoryId);
      });
      await runtime.saveLocal();
      _ok({'revision': runtime.ledger.revision});
    default:
      _fail('未知子命令：${sub.name}');
  }
}

Future<void> _cmdRecurring(CliRuntime runtime, ArgResults command) async {
  final sub = command.command;
  if (sub == null) {
    _fail('请使用 wangcai recurring list|upsert|delete|run');
    return;
  }
  switch (sub.name) {
    case 'list':
      await runtime.ensureFreshRead();
      _ok({
        'revision': runtime.ledger.revision,
        'rules': runtime.ledger.recurringRules
            .map((e) => e.toJson())
            .toList(growable: false),
      });
    case 'upsert':
      final amount = double.tryParse(sub['amount'] as String? ?? '');
      if (amount == null) {
        _fail('amount 无效', code: 'INVALID_PARAMS');
        return;
      }
      final rule = await runtime.client.writeTransaction(runtime.ledger, (
        ledger,
      ) async {
        final account = _resolveAccount(ledger, sub['account'] as String);
        final frequency = recurringFrequencyFromName(
          sub['frequency'] as String? ?? 'monthly',
        );
        final dayOfMonth =
            int.tryParse(sub['day-of-month'] as String? ?? '1') ?? 1;
        final weekday = int.tryParse(sub['weekday'] as String? ?? '1') ?? 1;
        final existingId = sub['id'] as String?;
        final start = DateTime.now();
        final next = ledger.computeInitialNextRun(
          frequency: frequency,
          startDate: start,
          dayOfMonth: dayOfMonth,
          weekday: weekday,
        );
        return ledger.upsertRecurring(
          RecurringRule(
            id: (existingId == null || existingId.isEmpty)
                ? '${DateTime.now().microsecondsSinceEpoch}'
                : existingId,
            title: sub['title'] as String,
            type: transactionTypeFromName(sub['type'] as String? ?? 'expense'),
            amount: amount,
            category: sub['category'] as String? ?? '账单',
            accountId: account.id,
            accountName: account.name,
            frequency: frequency,
            dayOfMonth: dayOfMonth,
            weekday: weekday,
            startDate: start,
            nextRunDate: next,
            enabled: sub['disabled'] != true,
            note: sub['note'] as String? ?? '',
          ),
        );
      });
      await runtime.saveLocal();
      _ok({'rule': rule.toJson(), 'revision': runtime.ledger.revision});
    case 'delete':
      final id = sub['id'] as String;
      await runtime.client.writeTransaction(runtime.ledger, (ledger) async {
        ledger.deleteRecurring(id);
      });
      await runtime.saveLocal();
      _ok({'deletedId': id, 'revision': runtime.ledger.revision});
    case 'run':
      final created = await runtime.client.writeTransaction(runtime.ledger, (
        ledger,
      ) async {
        return ledger.runDueRecurring();
      });
      await runtime.saveLocal();
      _ok({'createdCount': created, 'revision': runtime.ledger.revision});
    default:
      _fail('未知子命令：${sub.name}');
  }
}

Future<void> _cmdImport(CliRuntime runtime, ArgResults command) async {
  final sub = command.command;
  if (sub == null) {
    _fail('请使用 wangcai import parse|commit');
    return;
  }
  final filePath = sub['file'] as String;
  final text = await File(filePath).readAsString();
  final parsed = BillImportService.parseCsv(text);
  if (parsed.hasError) {
    _fail(parsed.errorMessage ?? '解析失败', code: 'PARSE_FAILED');
    return;
  }
  switch (sub.name) {
    case 'parse':
      _ok({
        'source': parsed.source.name,
        'rows': parsed.rows
            .asMap()
            .entries
            .map(
              (e) => {
                'index': e.key,
                'date': e.value.date.toIso8601String(),
                'amount': e.value.amount,
                'type': e.value.type.name,
                'rawCategory': e.value.rawCategory,
                'counterparty': e.value.counterparty,
                'note': e.value.note,
                'suggestedCategory': e.value.suggestedCategory,
              },
            )
            .toList(growable: false),
      });
    case 'commit':
      final accountKey = sub['account'] as String;
      final indexesRaw = sub['indexes'] as String?;
      final selected = <int>{};
      if (indexesRaw == null || indexesRaw.trim().isEmpty) {
        for (var i = 0; i < parsed.rows.length; i++) {
          selected.add(i);
        }
      } else {
        for (final part in indexesRaw.split(',')) {
          final index = int.tryParse(part.trim());
          if (index != null) {
            selected.add(index);
          }
        }
      }
      final imported = await runtime.client.writeTransaction(runtime.ledger, (
        ledger,
      ) async {
        final account = _resolveAccount(ledger, accountKey);
        var count = 0;
        final sorted = selected.toList()..sort();
        for (final index in sorted) {
          if (index < 0 || index >= parsed.rows.length) {
            continue;
          }
          final row = parsed.rows[index];
          ledger.createTransaction(
            type: row.type,
            amount: row.amount,
            category: row.suggestedCategory,
            accountId: account.id,
            date: row.date,
            note: row.note,
            client: TransactionClient.csvImport,
          );
          count++;
        }
        return count;
      });
      await runtime.saveLocal();
      _ok({
        'importedCount': imported,
        'source': parsed.source.name,
        'revision': runtime.ledger.revision,
      });
    default:
      _fail('未知子命令：${sub.name}');
  }
}

Future<void> _cmdStats(CliRuntime runtime, ArgResults command) async {
  await runtime.ensureFreshRead();
  final periodName = command['period'] as String? ?? 'month';
  final period = StatsPeriod.values.firstWhere(
    (item) => item.name == periodName,
    orElse: () => StatsPeriod.month,
  );
  final snapshot = StatsService.build(
    transactions: runtime.ledger.transactions,
    period: period,
  );
  _ok({
    'revision': runtime.ledger.revision,
    'period': snapshot.period.name,
    'rangeStart': snapshot.rangeStart.toIso8601String(),
    'rangeEnd': snapshot.rangeEnd.toIso8601String(),
    'totalIncome': snapshot.totalIncome,
    'totalExpense': snapshot.totalExpense,
    'balance': snapshot.totalIncome - snapshot.totalExpense,
    'avgDailyExpense': snapshot.avgDailyExpense,
    'expenseDeltaRatio': snapshot.expenseDeltaRatio,
    'categoryBreakdown': snapshot.categoryBreakdown
        .map(
          (e) => {
            'category': e.category,
            'amount': e.amount,
            'ratio': e.ratio,
          },
        )
        .toList(growable: false),
  });
}

Account _resolveAccount(Ledger ledger, String key) {
  final account = ledger.findAccount(key) ?? ledger.findAccountByName(key);
  if (account == null) {
    throw const LedgerException('NOT_FOUND', '账户不存在');
  }
  return account;
}

Lender _resolveLender(Ledger ledger, String key) {
  for (final item in ledger.lenders) {
    if (item.id == key || item.name == key) {
      return item;
    }
  }
  throw const LedgerException('NOT_FOUND', '应收/应付不存在');
}

String _resolveCategoryId(
  Ledger ledger, {
  String? categoryId,
  String? categoryLabel,
}) {
  if (categoryId != null && categoryId.trim().isNotEmpty) {
    final exists = ledger.categories.any((item) => item.id == categoryId);
    if (!exists) {
      throw const LedgerException('NOT_FOUND', '分类不存在');
    }
    return categoryId.trim();
  }
  final label = categoryLabel?.trim() ?? '';
  if (label.isEmpty) {
    throw const LedgerException('INVALID_PARAMS', '请提供 category-id 或 category');
  }
  for (final item in ledger.categories) {
    if (item.label == label) {
      return item.id;
    }
  }
  throw const LedgerException('NOT_FOUND', '分类不存在');
}

void _ok(Map<String, dynamic> data) {
  stdout.writeln(jsonEncode({'ok': true, 'data': data}));
}

void _fail(String message, {String code = 'ERROR'}) {
  stderr.writeln(
    jsonEncode({
      'ok': false,
      'error': {'code': code, 'message': message},
    }),
  );
  exitCode = 1;
}
