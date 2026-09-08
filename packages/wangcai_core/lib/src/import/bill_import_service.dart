import 'package:wangcai_core/src/models/transaction_record.dart';

enum BillImportSource { alipay, wechat, unknown }

class BillImportRow {
  const BillImportRow({
    required this.date,
    required this.amount,
    required this.type,
    required this.rawCategory,
    required this.counterparty,
    required this.note,
    required this.suggestedCategory,
  });

  final DateTime date;
  final double amount;
  final TransactionType type;
  final String rawCategory;
  final String counterparty;
  final String note;
  final String suggestedCategory;
}

class BillImportResult {
  const BillImportResult({
    required this.source,
    required this.rows,
    this.errorMessage,
  });

  final BillImportSource source;
  final List<BillImportRow> rows;
  final String? errorMessage;

  bool get hasError => errorMessage != null;
}

class BillImportService {
  static BillImportResult parseCsv(String rawText) {
    final text = rawText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = text
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      return const BillImportResult(
        source: BillImportSource.unknown,
        rows: [],
        errorMessage: '文件为空',
      );
    }

    final headerIndex = _findHeaderIndex(lines);
    if (headerIndex < 0) {
      return const BillImportResult(
        source: BillImportSource.unknown,
        rows: [],
        errorMessage: '未识别到支付宝/微信账单表头，请导出 CSV 后再试',
      );
    }

    final header = _splitCsvLine(lines[headerIndex]);
    final source = _detectSource(header);
    final column = _resolveColumns(header, source);
    if (column.dateIndex < 0 || column.amountIndex < 0) {
      return BillImportResult(
        source: source,
        rows: const [],
        errorMessage: '缺少必要列（时间/金额）',
      );
    }

    final rows = <BillImportRow>[];
    for (var i = headerIndex + 1; i < lines.length; i++) {
      final cells = _splitCsvLine(lines[i]);
      if (cells.length <= column.amountIndex ||
          cells.length <= column.dateIndex) {
        continue;
      }
      final date = _parseDate(cells[column.dateIndex]);
      final amount = _parseAmount(cells[column.amountIndex]);
      if (date == null || amount == null || amount <= 0) {
        continue;
      }

      final direction =
          column.directionIndex >= 0 && column.directionIndex < cells.length
          ? cells[column.directionIndex]
          : '';
      final type = _resolveType(
        direction,
        source: source,
        amountSigned: cells[column.amountIndex],
      );
      final rawCategory =
          column.categoryIndex >= 0 && column.categoryIndex < cells.length
          ? cells[column.categoryIndex].trim()
          : '';
      final counterparty =
          column.counterpartyIndex >= 0 &&
              column.counterpartyIndex < cells.length
          ? cells[column.counterpartyIndex].trim()
          : '';
      final note = column.noteIndex >= 0 && column.noteIndex < cells.length
          ? cells[column.noteIndex].trim()
          : '';
      final suggested = suggestCategory(
        rawCategory: rawCategory,
        counterparty: counterparty,
        note: note,
      );
      rows.add(
        BillImportRow(
          date: date,
          amount: amount.abs(),
          type: type,
          rawCategory: rawCategory,
          counterparty: counterparty,
          note: note.isEmpty ? counterparty : note,
          suggestedCategory: suggested,
        ),
      );
    }

    if (rows.isEmpty) {
      return BillImportResult(
        source: source,
        rows: const [],
        errorMessage: '未解析到有效账单行',
      );
    }
    return BillImportResult(source: source, rows: rows);
  }

  static String suggestCategory({
    required String rawCategory,
    required String counterparty,
    required String note,
  }) {
    final text = '$rawCategory $counterparty $note'.toLowerCase();
    if (_containsAny(text, ['餐', '外卖', '美团', '饿了么', '咖啡', '奶茶', '食堂'])) {
      return '餐饮';
    }
    if (_containsAny(text, [
      '地铁',
      '公交',
      '打车',
      '滴滴',
      '高德',
      '加油',
      '停车',
      '火车',
      '机票',
    ])) {
      return '交通';
    }
    if (_containsAny(text, ['淘宝', '京东', '拼多多', '超市', '便利店', '购物'])) {
      return '购物';
    }
    if (_containsAny(text, ['电影', '影院', '会员', '游戏', '娱乐'])) {
      return '电影';
    }
    if (_containsAny(text, ['医院', '药店', '医保', '诊所'])) {
      return '医疗';
    }
    if (_containsAny(text, ['水电', '煤气', '物业', '话费', '宽带', '电费', '水费'])) {
      return '账单';
    }
    if (_containsAny(text, ['菜', '生鲜', '水果', '蔬菜'])) {
      return '杂货';
    }
    if (rawCategory.isNotEmpty) {
      return rawCategory;
    }
    return '其他';
  }

  static int _findHeaderIndex(List<String> lines) {
    for (var i = 0; i < lines.length && i < 40; i++) {
      final line = lines[i];
      if (line.contains('交易时间') ||
          line.contains('交易创建时间') ||
          (line.contains('时间') && line.contains('金额'))) {
        return i;
      }
    }
    return -1;
  }

  static BillImportSource _detectSource(List<String> header) {
    final joined = header.join(',');
    if (joined.contains('交易对方') || joined.contains('收/支')) {
      if (joined.contains('交易单号') && joined.contains('商户单号')) {
        return BillImportSource.wechat;
      }
      return BillImportSource.alipay;
    }
    if (joined.contains('交易类型') && joined.contains('金额(元)')) {
      return BillImportSource.wechat;
    }
    return BillImportSource.unknown;
  }

  static _ColumnMap _resolveColumns(
    List<String> header,
    BillImportSource source,
  ) {
    int indexOfAny(List<String> candidates) {
      for (var i = 0; i < header.length; i++) {
        final cell = header[i].trim();
        for (final candidate in candidates) {
          if (cell.contains(candidate)) {
            return i;
          }
        }
      }
      return -1;
    }

    return _ColumnMap(
      dateIndex: indexOfAny(['交易时间', '交易创建时间', '时间']),
      amountIndex: indexOfAny(['金额(元)', '金额（元）', '金额']),
      directionIndex: indexOfAny(['收/支', '收／支', '类型']),
      categoryIndex: indexOfAny(['交易分类', '交易类型', '分类']),
      counterpartyIndex: indexOfAny(['交易对方', '对方', '商户']),
      noteIndex: indexOfAny(['商品说明', '商品', '备注', '说明']),
    );
  }

  static TransactionType _resolveType(
    String direction, {
    required BillImportSource source,
    required String amountSigned,
  }) {
    final text = direction.trim();
    if (text.contains('收') || text.contains('收入') || text.contains('入账')) {
      return TransactionType.income;
    }
    if (text.contains('支') || text.contains('支出')) {
      return TransactionType.expense;
    }
    if (amountSigned.trim().startsWith('+')) {
      return TransactionType.income;
    }
    return TransactionType.expense;
  }

  static DateTime? _parseDate(String raw) {
    final text = raw.trim().replaceAll('/', '-');
    return DateTime.tryParse(text) ??
        DateTime.tryParse(text.replaceFirst(' ', 'T'));
  }

  static double? _parseAmount(String raw) {
    final cleaned = raw
        .trim()
        .replaceAll(',', '')
        .replaceAll('¥', '')
        .replaceAll('￥', '');
    return double.tryParse(cleaned);
  }

  static List<String> _splitCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
        continue;
      }
      if (char == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
        continue;
      }
      buffer.write(char);
    }
    result.add(buffer.toString());
    return result;
  }

  static bool _containsAny(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (text.contains(keyword.toLowerCase())) {
        return true;
      }
    }
    return false;
  }
}

class _ColumnMap {
  const _ColumnMap({
    required this.dateIndex,
    required this.amountIndex,
    required this.directionIndex,
    required this.categoryIndex,
    required this.counterpartyIndex,
    required this.noteIndex,
  });

  final int dateIndex;
  final int amountIndex;
  final int directionIndex;
  final int categoryIndex;
  final int counterpartyIndex;
  final int noteIndex;
}
