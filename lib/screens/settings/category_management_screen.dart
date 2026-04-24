import 'package:flutter/material.dart';
import 'package:finance_app/models/transaction_category.dart';
import 'package:finance_app/providers/category_provider.dart';
import 'package:finance_app/providers/transaction_provider.dart';
import 'package:finance_app/theme/app_colors.dart';
import 'package:provider/provider.dart';

class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest.withValues(alpha: 0.9),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          '分类管理',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryEditor(context),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        child: const Icon(Icons.add),
      ),
      body: Consumer2<CategoryProvider, TransactionProvider>(
        builder: (context, categoryProvider, transactionProvider, _) {
          final categories = categoryProvider.categories;
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final category = categories[index];
              final usageCount = transactionProvider.transactions
                  .where((item) => item.category == category.label)
                  .length;
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.surfaceContainer,
                    child: Icon(category.icon, color: AppColors.primary),
                  ),
                  title: Text(category.label),
                  subtitle: Text('关联账单 $usageCount 条'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showCategoryEditor(
                          context,
                          category: category,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteCategory(
                          context,
                          category: category,
                          usageCount: usageCount,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _deleteCategory(
    BuildContext context, {
    required TransactionCategory category,
    required int usageCount,
  }) async {
    if (usageCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('该分类已有关联账单，无法删除')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除分类'),
        content: Text('确认删除「${category.label}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<CategoryProvider>().removeCategory(category.id);
    }
  }

  Future<void> _showCategoryEditor(
    BuildContext context, {
    TransactionCategory? category,
  }) async {
    final labelController = TextEditingController(text: category?.label ?? '');
    String selectedIconKey = category?.iconKey ?? 'other';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(category == null ? '新增分类' : '编辑分类'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: const InputDecoration(labelText: '分类名称'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedIconKey,
                decoration: const InputDecoration(labelText: '图标'),
                items: const [
                  DropdownMenuItem(value: 'food', child: Text('餐饮')),
                  DropdownMenuItem(value: 'transport', child: Text('交通')),
                  DropdownMenuItem(value: 'shopping', child: Text('购物')),
                  DropdownMenuItem(value: 'movie', child: Text('电影')),
                  DropdownMenuItem(value: 'medical', child: Text('医疗')),
                  DropdownMenuItem(value: 'grocery', child: Text('杂货')),
                  DropdownMenuItem(value: 'bill', child: Text('账单')),
                  DropdownMenuItem(value: 'other', child: Text('其他')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      selectedIconKey = value;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) {
      labelController.dispose();
      return;
    }

    final label = labelController.text.trim();
    labelController.dispose();
    if (label.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('分类名称不能为空')),
      );
      return;
    }

    final categoryProvider = context.read<CategoryProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    if (category == null) {
      await categoryProvider.addCategory(
        label: label,
        iconKey: selectedIconKey,
      );
      return;
    }

    final oldLabel = category.label;
    await categoryProvider.updateCategory(
      id: category.id,
      label: label,
      iconKey: selectedIconKey,
    );
    if (oldLabel != label) {
      await transactionProvider.replaceCategoryLabel(
        from: oldLabel,
        to: label,
      );
    }
  }
}
