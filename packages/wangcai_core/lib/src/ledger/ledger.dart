import 'package:wangcai_core/src/ledger/ledger_errors.dart';
import 'package:wangcai_core/src/models/account.dart';
import 'package:wangcai_core/src/models/budget.dart';
import 'package:wangcai_core/src/models/ledger_bundle.dart';
import 'package:wangcai_core/src/models/lender.dart';
import 'package:wangcai_core/src/models/recurring_rule.dart';
import 'package:wangcai_core/src/models/transaction_category.dart';
import 'package:wangcai_core/src/models/transaction_record.dart';

class TransactionQueryFilter {
  const TransactionQueryFilter({
    this.type,
    this.types,
    this.startDate,
    this.endDate,
    this.keyword,
  });

  final TransactionType? type;
  final Set<TransactionType>? types;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? keyword;
}

class RecurringDueItem {
  const RecurringDueItem({
    required this.ruleId,
    required this.record,
    required this.nextRunDateAfter,
  });

  final String ruleId;
  final TransactionRecord record;
  final DateTime nextRunDateAfter;
}

/// 内存账本：与 App Provider 业务规则对齐，供 CLI / Skill 复用。
class Ledger {
  Ledger([LedgerBundle? bundle]) {
    replaceAll(bundle ?? LedgerBundle.empty());
  }

  final List<Account> _accounts = [];
  final List<Lender> _lenders = [];
  final List<TransactionCategory> _categories = [];
  final List<TransactionRecord> _transactions = [];
  final List<Budget> _budgets = [];
  final List<RecurringRule> _rules = [];
  final Map<String, int> _categoryLastUsedAt = {};

  int revision = 0;
  int schemaVersion = LedgerBundle.currentSchemaVersion;
  int version = 1;
  String? deviceId;
  DateTime exportedAt = DateTime.now();

  List<Account> get accounts => List.unmodifiable(_accounts);
  List<Lender> get lenders => List.unmodifiable(_lenders);
  List<Budget> get budgets => List.unmodifiable(_budgets);
  List<RecurringRule> get recurringRules => List.unmodifiable(_rules);

  List<TransactionCategory> get categories {
    final indexed = _categories.asMap().entries.toList(growable: false);
    indexed.sort((a, b) {
      final aUsedAt = _categoryLastUsedAt[a.value.id] ?? 0;
      final bUsedAt = _categoryLastUsedAt[b.value.id] ?? 0;
      if (aUsedAt != bUsedAt) {
        return bUsedAt.compareTo(aUsedAt);
      }
      return a.key.compareTo(b.key);
    });
    return List.unmodifiable(indexed.map((e) => e.value));
  }

  List<TransactionRecord> get transactions {
    final copied = List<TransactionRecord>.from(_transactions);
    copied.sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(copied);
  }

  double get totalAssets => _accounts.fold(
    0,
    (sum, account) => account.balance > 0 ? sum + account.balance : sum,
  );

  double get totalLiabilities => _accounts.fold(
    0,
    (sum, account) => account.balance < 0 ? sum + account.balance.abs() : sum,
  );

  double get netAssets => totalAssets - totalLiabilities;

  LedgerBundle toBundle() {
    return LedgerBundle(
      version: version,
      schemaVersion: schemaVersion,
      revision: revision,
      deviceId: deviceId,
      exportedAt: exportedAt,
      accounts: List.unmodifiable(_accounts),
      lenders: List.unmodifiable(_lenders),
      categories: List.unmodifiable(_categories),
      transactions: List.unmodifiable(_transactions),
      budgets: List.unmodifiable(_budgets),
      recurringRules: List.unmodifiable(_rules),
    );
  }

  void replaceAll(LedgerBundle bundle) {
    _accounts
      ..clear()
      ..addAll(bundle.accounts);
    _lenders
      ..clear()
      ..addAll(bundle.lenders);
    _categories
      ..clear()
      ..addAll(
        bundle.categories.isEmpty ? defaultCategories() : bundle.categories,
      );
    _transactions
      ..clear()
      ..addAll(bundle.transactions);
    _budgets
      ..clear()
      ..addAll(bundle.budgets);
    _rules
      ..clear()
      ..addAll(bundle.recurringRules);
    revision = bundle.revision;
    schemaVersion = bundle.schemaVersion < LedgerBundle.currentSchemaVersion
        ? LedgerBundle.currentSchemaVersion
        : bundle.schemaVersion;
    version = bundle.version;
    deviceId = bundle.deviceId;
    exportedAt = bundle.exportedAt;
  }

  void bumpRevision({String? deviceId, DateTime? now}) {
    revision += 1;
    exportedAt = now ?? DateTime.now();
    if (deviceId != null && deviceId.isNotEmpty) {
      this.deviceId = deviceId;
    }
    schemaVersion = LedgerBundle.currentSchemaVersion;
  }

  String _newId() => '${DateTime.now().microsecondsSinceEpoch}';

  Account? findAccount(String id) {
    for (final item in _accounts) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  Account? findAccountByName(String name) {
    final trimmed = name.trim();
    for (final item in _accounts) {
      if (item.name == trimmed) {
        return item;
      }
    }
    return null;
  }

  Lender? findLender(String id) {
    for (final item in _lenders) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  // --- transactions ---

  List<TransactionRecord> queryPage({
    required int offset,
    required int limit,
    TransactionQueryFilter filter = const TransactionQueryFilter(),
  }) {
    final sorted = transactions;
    final keyword = filter.keyword?.trim().toLowerCase() ?? '';
    final hasKeyword = keyword.isNotEmpty;
    var skipped = 0;
    final result = <TransactionRecord>[];
    for (final item in sorted) {
      if (!_matchesFilter(item, filter, keyword, hasKeyword)) {
        continue;
      }
      if (skipped < offset) {
        skipped++;
        continue;
      }
      result.add(item);
      if (result.length >= limit) {
        break;
      }
    }
    return result;
  }

  int countByFilter(TransactionQueryFilter filter) {
    final keyword = filter.keyword?.trim().toLowerCase() ?? '';
    final hasKeyword = keyword.isNotEmpty;
    var count = 0;
    for (final item in transactions) {
      if (_matchesFilter(item, filter, keyword, hasKeyword)) {
        count++;
      }
    }
    return count;
  }

  bool _matchesFilter(
    TransactionRecord item,
    TransactionQueryFilter filter,
    String keyword,
    bool hasKeyword,
  ) {
    if (filter.type != null && item.type != filter.type) {
      return false;
    }
    if (filter.types != null && !filter.types!.contains(item.type)) {
      return false;
    }
    if (filter.startDate != null && item.date.isBefore(filter.startDate!)) {
      return false;
    }
    if (filter.endDate != null && item.date.isAfter(filter.endDate!)) {
      return false;
    }
    if (hasKeyword && !_matchesKeyword(item, keyword)) {
      return false;
    }
    return true;
  }

  bool _matchesKeyword(TransactionRecord item, String keyword) {
    return item.category.toLowerCase().contains(keyword) ||
        item.accountName.toLowerCase().contains(keyword) ||
        (item.transferAccountName?.toLowerCase().contains(keyword) ?? false) ||
        (item.lenderName?.toLowerCase().contains(keyword) ?? false) ||
        item.note.toLowerCase().contains(keyword);
  }

  TransactionRecord createTransaction({
    required TransactionType type,
    required double amount,
    required String category,
    required String accountId,
    String? transferAccountId,
    String? lenderId,
    required DateTime date,
    String note = '',
    String? id,
    TransactionClient client = TransactionClient.unknown,
  }) {
    if (amount <= 0) {
      throw const LedgerException('INVALID_PARAMS', '请输入合法金额');
    }
    final account = findAccount(accountId);
    if (account == null) {
      throw const LedgerException('NOT_FOUND', '账户不存在');
    }
    String? transferName;
    if (type == TransactionType.transfer) {
      if (transferAccountId == null || transferAccountId.isEmpty) {
        throw const LedgerException('INVALID_PARAMS', '请选择转入账户');
      }
      if (transferAccountId == accountId) {
        throw const LedgerException('CONSTRAINT', '转入账户不能与转出账户相同');
      }
      final transfer = findAccount(transferAccountId);
      if (transfer == null) {
        throw const LedgerException('NOT_FOUND', '转入账户不存在');
      }
      transferName = transfer.name;
    }
    String? lenderName;
    if (type == TransactionType.lend || type == TransactionType.borrow) {
      if (lenderId == null || lenderId.isEmpty) {
        throw const LedgerException('INVALID_PARAMS', '请选择应收/应付对方');
      }
      final lender = findLender(lenderId);
      if (lender == null) {
        throw const LedgerException('NOT_FOUND', '应收/应付不存在');
      }
      lenderName = lender.name;
    }

    final record = TransactionRecord(
      id: id ?? _newId(),
      type: type,
      amount: amount,
      category: category,
      accountId: account.id,
      accountName: account.name,
      transferAccountId: transferAccountId,
      transferAccountName: transferName,
      lenderId: lenderId,
      lenderName: lenderName,
      date: date,
      note: note,
      client: client,
    );
    _transactions.insert(0, record);
    _applyDelta(record, isRevert: false);
    markCategoryUsed(category);
    return record;
  }

  TransactionRecord? addIfAbsent(TransactionRecord record) {
    if (_transactions.any((item) => item.id == record.id)) {
      return null;
    }
    _transactions.insert(0, record);
    _applyDelta(record, isRevert: false);
    return record;
  }

  TransactionRecord updateTransaction(TransactionRecord updated) {
    final index = _transactions.indexWhere((item) => item.id == updated.id);
    if (index == -1) {
      throw const LedgerException('NOT_FOUND', '账单不存在');
    }
    final old = _transactions[index];
    _applyDelta(old, isRevert: true);
    _applyDelta(updated, isRevert: false);
    _transactions[index] = updated;
    markCategoryUsed(updated.category);
    return updated;
  }

  void deleteTransaction(String id) {
    final index = _transactions.indexWhere((item) => item.id == id);
    if (index == -1) {
      return;
    }
    final record = _transactions.removeAt(index);
    _applyDelta(record, isRevert: true);
  }

  void replaceCategoryLabel({required String from, required String to}) {
    for (var i = 0; i < _transactions.length; i++) {
      final item = _transactions[i];
      if (item.category != from) {
        continue;
      }
      _transactions[i] = TransactionRecord(
        id: item.id,
        type: item.type,
        amount: item.amount,
        category: to,
        accountId: item.accountId,
        accountName: item.accountName,
        transferAccountId: item.transferAccountId,
        transferAccountName: item.transferAccountName,
        lenderId: item.lenderId,
        lenderName: item.lenderName,
        date: item.date,
        note: item.note,
        client: item.client,
      );
    }
    for (var i = 0; i < _rules.length; i++) {
      final rule = _rules[i];
      if (rule.category == from) {
        _rules[i] = rule.copyWith(category: to);
      }
    }
  }

  void _applyDelta(TransactionRecord record, {required bool isRevert}) {
    final sign = isRevert ? -1.0 : 1.0;
    switch (record.type) {
      case TransactionType.expense:
        _adjustAccount(record.accountId, -record.amount * sign);
        break;
      case TransactionType.income:
        _adjustAccount(record.accountId, record.amount * sign);
        break;
      case TransactionType.transfer:
        _adjustAccount(record.accountId, -record.amount * sign);
        if (record.transferAccountId != null &&
            record.transferAccountId!.isNotEmpty) {
          _adjustAccount(record.transferAccountId!, record.amount * sign);
        }
        break;
      case TransactionType.lend:
        _adjustAccount(record.accountId, -record.amount * sign);
        if (record.lenderId != null && record.lenderId!.isNotEmpty) {
          _adjustLender(record.lenderId!, record.amount * sign);
        }
        break;
      case TransactionType.borrow:
        _adjustAccount(record.accountId, record.amount * sign);
        if (record.lenderId != null && record.lenderId!.isNotEmpty) {
          _adjustLender(record.lenderId!, -record.amount * sign);
        }
        break;
    }
  }

  void _adjustAccount(String id, double delta) {
    final index = _accounts.indexWhere((item) => item.id == id);
    if (index == -1) {
      return;
    }
    final account = _accounts[index];
    _accounts[index] = account.copyWith(balance: account.balance + delta);
  }

  void _adjustLender(String id, double delta) {
    final index = _lenders.indexWhere((item) => item.id == id);
    if (index == -1) {
      return;
    }
    final lender = _lenders[index];
    _lenders[index] = lender.copyWith(balance: lender.balance + delta);
  }

  // --- accounts / lenders ---

  Account createAccount({
    required String name,
    required AccountType type,
    required double balance,
    double? creditLimit,
    int? billingDay,
    int? paymentDay,
  }) {
    final account = Account(
      id: _newId(),
      name: name.trim(),
      type: type,
      balance: balance,
      creditLimit: type == AccountType.creditCard ? creditLimit : null,
      billingDay: type == AccountType.creditCard ? billingDay : null,
      paymentDay: type == AccountType.creditCard ? paymentDay : null,
    );
    _accounts.add(account);
    return account;
  }

  Account updateAccount({
    required String id,
    required String name,
    required double balance,
    double? creditLimit,
    int? billingDay,
    int? paymentDay,
    bool recordBalanceDifference = false,
    String adjustmentCategory = '余额调整',
    String adjustmentNote = '编辑账户余额补记',
    DateTime? adjustmentDate,
    TransactionClient client = TransactionClient.unknown,
  }) {
    final index = _accounts.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw const LedgerException('NOT_FOUND', '账户不存在');
    }
    final current = _accounts[index];
    final previousBalance = current.balance;
    final updated = current.copyWith(
      name: name,
      balance: recordBalanceDifference ? previousBalance : balance,
      creditLimit: current.isCreditCard ? creditLimit : null,
      billingDay: current.isCreditCard ? billingDay : null,
      paymentDay: current.isCreditCard ? paymentDay : null,
      clearCreditLimit: !current.isCreditCard || creditLimit == null,
      clearBillingDay: !current.isCreditCard || billingDay == null,
      clearPaymentDay: !current.isCreditCard || paymentDay == null,
    );
    _accounts[index] = updated;

    if (recordBalanceDifference) {
      final delta = balance - previousBalance;
      if (delta != 0) {
        createTransaction(
          type: delta > 0 ? TransactionType.income : TransactionType.expense,
          amount: delta.abs(),
          category: adjustmentCategory,
          accountId: id,
          date: adjustmentDate ?? DateTime.now(),
          note: adjustmentNote,
          client: client,
        );
      }
    }
    return findAccount(id)!;
  }

  void deleteAccount(String id) {
    final linked = _transactions.any(
      (item) => item.accountId == id || item.transferAccountId == id,
    );
    if (linked) {
      throw const LedgerException('CONSTRAINT', '该账户已有关联账单，无法删除');
    }
    _accounts.removeWhere((item) => item.id == id);
  }

  Lender createLender(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const LedgerException('INVALID_PARAMS', '应收/应付名称不能为空');
    }
    for (final item in _lenders) {
      if (item.name == trimmed) {
        throw const LedgerException('CONFLICT', '应收/应付已存在');
      }
    }
    final lender = Lender(id: _newId(), name: trimmed);
    _lenders.add(lender);
    return lender;
  }

  Lender updateLender({
    required String id,
    required String name,
    required double balance,
  }) {
    final index = _lenders.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw const LedgerException('NOT_FOUND', '应收/应付不存在');
    }
    final updated = _lenders[index].copyWith(
      name: name.trim().isEmpty ? _lenders[index].name : name.trim(),
      balance: balance,
    );
    _lenders[index] = updated;
    return updated;
  }

  void deleteLender(String id) {
    final linked = _transactions.any((item) => item.lenderId == id);
    if (linked) {
      throw const LedgerException('CONSTRAINT', '该应收/应付已有关联账单，无法删除');
    }
    _lenders.removeWhere((item) => item.id == id);
  }

  // --- categories / budgets / recurring ---

  TransactionCategory createCategory({
    required String label,
    required String iconKey,
  }) {
    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      throw const LedgerException('INVALID_PARAMS', '分类名称不能为空');
    }
    if (_categories.any((item) => item.label == trimmed)) {
      throw const LedgerException('CONFLICT', '分类已存在');
    }
    final category = TransactionCategory(
      id: _newId(),
      label: trimmed,
      iconKey: iconKey,
    );
    _categories.add(category);
    return category;
  }

  TransactionCategory updateCategory({
    required String id,
    required String label,
    required String iconKey,
  }) {
    final index = _categories.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw const LedgerException('NOT_FOUND', '分类不存在');
    }
    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      throw const LedgerException('INVALID_PARAMS', '分类名称不能为空');
    }
    final old = _categories[index];
    _categories[index] = TransactionCategory(
      id: old.id,
      label: trimmed,
      iconKey: iconKey,
    );
    if (old.label != trimmed) {
      replaceCategoryLabel(from: old.label, to: trimmed);
    }
    return _categories[index];
  }

  void deleteCategory(String id) {
    final index = _categories.indexWhere((item) => item.id == id);
    if (index == -1) {
      return;
    }
    final label = _categories[index].label;
    final linked = _transactions.any((item) => item.category == label);
    if (linked) {
      throw const LedgerException('CONSTRAINT', '该分类已有关联账单，无法删除');
    }
    _categories.removeAt(index);
    _categoryLastUsedAt.remove(id);
    _budgets.removeWhere((item) => item.categoryId == id);
  }

  void markCategoryUsed(String label) {
    final index = _categories.indexWhere((item) => item.label == label);
    if (index == -1) {
      return;
    }
    _categoryLastUsedAt[_categories[index].id] =
        DateTime.now().millisecondsSinceEpoch;
  }

  Budget upsertBudget({
    required String categoryId,
    required double monthlyLimit,
  }) {
    final normalized = monthlyLimit < 0 ? 0.0 : monthlyLimit;
    final index = _budgets.indexWhere((item) => item.categoryId == categoryId);
    final budget = Budget(categoryId: categoryId, monthlyLimit: normalized);
    if (index >= 0) {
      _budgets[index] = budget;
    } else {
      _budgets.add(budget);
    }
    return budget;
  }

  void deleteBudget(String categoryId) {
    _budgets.removeWhere((item) => item.categoryId == categoryId);
  }

  RecurringRule upsertRecurring(RecurringRule rule) {
    final index = _rules.indexWhere((item) => item.id == rule.id);
    if (index >= 0) {
      _rules[index] = rule;
    } else {
      _rules.add(rule);
    }
    return rule;
  }

  void deleteRecurring(String id) {
    _rules.removeWhere((item) => item.id == id);
  }

  List<RecurringDueItem> peekDueTransactions({DateTime? until}) {
    final now = until ?? DateTime.now();
    final cutoff = _dateOnly(now);
    final due = <RecurringDueItem>[];
    for (final rule in _rules) {
      if (!rule.enabled || rule.amount <= 0) {
        continue;
      }
      if (rule.type != TransactionType.expense &&
          rule.type != TransactionType.income) {
        continue;
      }
      var next = _dateOnly(rule.nextRunDate);
      var guard = 0;
      while (!next.isAfter(cutoff) && guard < 36) {
        guard++;
        if (rule.endDate != null && next.isAfter(_dateOnly(rule.endDate!))) {
          break;
        }
        final after = _nextOccurrenceAfter(rule, next);
        due.add(
          RecurringDueItem(
            ruleId: rule.id,
            nextRunDateAfter: after,
            record: TransactionRecord(
              id: 'recurring_${rule.id}_${next.millisecondsSinceEpoch}',
              type: rule.type,
              amount: rule.amount,
              category: rule.category,
              accountId: rule.accountId,
              accountName: rule.accountName,
              date: next,
              note: rule.note.isEmpty ? '周期：${rule.title}' : rule.note,
              client: TransactionClient.recurring,
            ),
          ),
        );
        next = after;
      }
    }
    return due;
  }

  void advanceRecurring({
    required String ruleId,
    required DateTime nextRunDateAfter,
  }) {
    final index = _rules.indexWhere((item) => item.id == ruleId);
    if (index == -1) {
      return;
    }
    final current = _rules[index];
    final currentNext = _dateOnly(current.nextRunDate);
    final target = _dateOnly(nextRunDateAfter);
    if (target.isBefore(currentNext) || target.isAtSameMomentAs(currentNext)) {
      return;
    }
    _rules[index] = current.copyWith(nextRunDate: target);
  }

  int runDueRecurring({DateTime? until}) {
    final dueItems = peekDueTransactions(until: until);
    var created = 0;
    for (final item in dueItems) {
      final added = addIfAbsent(item.record);
      if (added != null) {
        created++;
      }
      advanceRecurring(
        ruleId: item.ruleId,
        nextRunDateAfter: item.nextRunDateAfter,
      );
    }
    return created;
  }

  DateTime computeInitialNextRun({
    required RecurringFrequency frequency,
    required DateTime startDate,
    required int dayOfMonth,
    required int weekday,
  }) {
    final start = _dateOnly(startDate);
    switch (frequency) {
      case RecurringFrequency.monthly:
        final candidate = DateTime(
          start.year,
          start.month,
          dayOfMonth.clamp(1, 28),
        );
        if (!candidate.isBefore(start)) {
          return candidate;
        }
        return DateTime(start.year, start.month + 1, dayOfMonth.clamp(1, 28));
      case RecurringFrequency.weekly:
        var candidate = start;
        while (candidate.weekday != weekday) {
          candidate = candidate.add(const Duration(days: 1));
        }
        return candidate;
    }
  }

  DateTime _nextOccurrenceAfter(RecurringRule rule, DateTime current) {
    final day = _dateOnly(current);
    switch (rule.frequency) {
      case RecurringFrequency.monthly:
        return DateTime(day.year, day.month + 1, rule.dayOfMonth.clamp(1, 28));
      case RecurringFrequency.weekly:
        return day.add(const Duration(days: 7));
    }
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
