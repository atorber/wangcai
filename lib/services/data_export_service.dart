import 'dart:convert';
import 'dart:io';

import 'package:finance_app/models/app_backup_bundle.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum ExportFormat { json, csv }

class DataExportService {
  const DataExportService._();

  static Future<void> export({
    required AppBackupBundle bundle,
    required ExportFormat format,
  }) async {
    final file = await _writeToTempFile(bundle: bundle, format: format);
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: format == ExportFormat.json ? '旺财数据备份（JSON）' : '旺财数据导出（CSV）',
      ),
    );
    if (result.status == ShareResultStatus.unavailable) {
      throw Exception('当前设备暂不支持系统分享');
    }
  }

  static Future<File> _writeToTempFile({
    required AppBackupBundle bundle,
    required ExportFormat format,
  }) async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('-', '')
        .replaceAll('.', '');
    final fileName = format == ExportFormat.json
        ? 'wangcai_export_$timestamp.json'
        : 'wangcai_export_$timestamp.csv';
    final file = File('${directory.path}/$fileName');
    final content = format == ExportFormat.json
        ? _buildJson(bundle)
        : _buildCsv(bundle);
    return file.writeAsString(content, flush: true);
  }

  static String _buildJson(AppBackupBundle bundle) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(bundle.toJson());
  }

  static String _buildCsv(AppBackupBundle bundle) {
    final lines = <String>[];

    lines.add('section,key,value');
    lines.add('meta,version,${bundle.version}');
    lines.add(
      'meta,exportedAt,${_escapeCsv(bundle.exportedAt.toIso8601String())}',
    );
    lines.add('');

    lines.add('accounts,id,name,type,balance,subtitle');
    for (final account in bundle.accounts) {
      lines.add(
        [
          'accounts',
          account.id,
          account.name,
          account.type.name,
          account.balance.toString(),
          account.subtitle,
        ].map(_escapeCsv).join(','),
      );
    }
    lines.add('');

    lines.add('lenders,id,name,balance');
    for (final lender in bundle.lenders) {
      lines.add(
        [
          'lenders',
          lender.id,
          lender.name,
          lender.balance.toString(),
        ].map(_escapeCsv).join(','),
      );
    }
    lines.add('');

    lines.add('categories,id,label,iconKey');
    for (final category in bundle.categories) {
      lines.add(
        [
          'categories',
          category.id,
          category.label,
          category.iconKey,
        ].map(_escapeCsv).join(','),
      );
    }
    lines.add('');

    lines.add(
      'transactions,id,type,amount,category,accountId,accountName,transferAccountId,transferAccountName,lenderId,lenderName,date,note',
    );
    for (final transaction in bundle.transactions) {
      lines.add(
        [
          'transactions',
          transaction.id,
          transaction.type.name,
          transaction.amount.toString(),
          transaction.category,
          transaction.accountId,
          transaction.accountName,
          transaction.transferAccountId ?? '',
          transaction.transferAccountName ?? '',
          transaction.lenderId ?? '',
          transaction.lenderName ?? '',
          transaction.date.toIso8601String(),
          transaction.note,
        ].map(_escapeCsv).join(','),
      );
    }

    return lines.join('\n');
  }

  static String _escapeCsv(String value) {
    final needsQuote =
        value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    final escaped = value.replaceAll('"', '""');
    return needsQuote ? '"$escaped"' : escaped;
  }
}
