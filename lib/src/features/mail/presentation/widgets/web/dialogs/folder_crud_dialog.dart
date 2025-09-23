// lib/src/features/mail/presentation/widgets/web/dialogs/folder_crud_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../utils/app_logger.dart';
import '../../../providers/mail_tree_provider.dart';
import '../../../../domain/entities/tree_node.dart';

/// Show create folder dialog
Future<void> showCreateFolderDialog(BuildContext context, WidgetRef ref) async {
  AppLogger.info('📂 Opening create folder dialog');

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return const CreateFolderDialog();
    },
  );
}

/// Show rename folder dialog
Future<void> showRenameFolderDialog(
  BuildContext context,
  WidgetRef ref,
  TreeNode node,
) async {
  AppLogger.info('✏️ Opening rename folder dialog for: ${node.title}');

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return RenameFolderDialog(node: node);
    },
  );
}

/// Show delete folder confirmation dialog
Future<void> showDeleteFolderDialog(
  BuildContext context,
  WidgetRef ref,
  TreeNode node,
) async {
  AppLogger.info('🗑️ Opening delete folder dialog for: ${node.title}');

  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return DeleteFolderDialog(node: node);
    },
  );
}

// ========== CREATE FOLDER DIALOG ==========

class CreateFolderDialog extends ConsumerStatefulWidget {
  const CreateFolderDialog({super.key});

  @override
  ConsumerState<CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends ConsumerState<CreateFolderDialog> {
  final TextEditingController _titleController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.create_new_folder, color: Colors.blue[600]),
          const SizedBox(width: 8),
          const Text('Yeni Klasör'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Parent folder info
              _buildParentInfo(),

              const SizedBox(height: 16),

              // Folder name input
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Klasör Adı',
                  hintText: 'Örn: Önemli Mailler',
                  prefixIcon: const Icon(Icons.folder),
                  border: const OutlineInputBorder(),
                  errorText: _errorMessage,
                ),
                validator: _validateTitle,
                onChanged: (_) => _clearError(),
                autofocus: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleCreate(),
              ),

              const SizedBox(height: 8),

              // Helper text
              Text(
                'Klasör adı otomatik olarak URL-friendly hale dönüştürülecek',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleCreate,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Oluştur'),
        ),
      ],
    );
  }

  Widget _buildParentInfo() {
    final selectedNode = ref.read(selectedTreeNodeProvider);

    // Root seviyesinde (MAILS) klasör oluşturmaya izin verme
    if (selectedNode == null || selectedNode.slug == 'mails') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          border: Border.all(color: Colors.red[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, size: 16, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Lütfen klasör oluşturmak için bir alt klasör seçin',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border.all(color: Colors.green[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.folder, size: 16, color: Colors.green[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Alt klasör oluşturulacak: ${selectedNode.title}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String? _validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Klasör adı gerekli';
    }

    if (value.trim().length < 2) {
      return 'Klasör adı en az 2 karakter olmalı';
    }

    if (value.trim().length > 50) {
      return 'Klasör adı 50 karakterden uzun olamaz';
    }

    // Basic character validation
    if (!RegExp(r'^[a-zA-ZğüşıöçĞÜŞİÖÇ0-9\s\-_]+$').hasMatch(value.trim())) {
      return 'Geçersiz karakter kullanıldı';
    }

    return null;
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final selectedNode = ref.read(selectedTreeNodeProvider);


    final title = _titleController.text.trim();
    final parentSlug = selectedNode?.slug;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      AppLogger.info('📂 Creating folder: $title, parent: $parentSlug');

      final result = await ref
          .read(treeOperationsProvider)
          .createNode(title: title, parentSlug: parentSlug);

      if (result.success) {
        AppLogger.info('✅ Folder created successfully: $title');

        if (mounted) {
          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'Klasör başarıyla oluşturuldu'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception(result.message ?? 'Bilinmeyen hata');
      }
    } catch (e) {
      AppLogger.error('❌ Failed to create folder: $e');

      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }
}

// ========== RENAME FOLDER DIALOG ==========

class RenameFolderDialog extends ConsumerStatefulWidget {
  final TreeNode node;

  const RenameFolderDialog({super.key, required this.node});

  @override
  ConsumerState<RenameFolderDialog> createState() => _RenameFolderDialogState();
}

class _RenameFolderDialogState extends ConsumerState<RenameFolderDialog> {
  final TextEditingController _titleController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.node.title;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.edit, color: Colors.orange[600]),
          const SizedBox(width: 8),
          const Text('Klasörü Yeniden Adlandır'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current folder info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.folder, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mevcut ad: ${widget.node.title}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // New name input
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Yeni Klasör Adı',
                  prefixIcon: const Icon(Icons.folder),
                  border: const OutlineInputBorder(),
                  errorText: _errorMessage,
                ),
                validator: _validateTitle,
                onChanged: (_) => _clearError(),
                autofocus: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleRename(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleRename,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[600],
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Yeniden Adlandır'),
        ),
      ],
    );
  }

  String? _validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Klasör adı gerekli';
    }

    if (value.trim().length < 2) {
      return 'Klasör adı en az 2 karakter olmalı';
    }

    if (value.trim().length > 50) {
      return 'Klasör adı 50 karakterden uzun olamaz';
    }

    if (value.trim() == widget.node.title) {
      return 'Yeni ad mevcut adla aynı olamaz';
    }

    return null;
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  Future<void> _handleRename() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final newTitle = _titleController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      AppLogger.info('✏️ Renaming folder: ${widget.node.title} → $newTitle');

      final result = await ref
          .read(treeOperationsProvider)
          .updateNode(nodeId: widget.node.id, title: newTitle);

      if (result.success) {
        AppLogger.info('✅ Folder renamed successfully');

        if (mounted) {
          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.message ?? 'Klasör başarıyla yeniden adlandırıldı',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception(result.message ?? 'Bilinmeyen hata');
      }
    } catch (e) {
      AppLogger.error('❌ Failed to rename folder: $e');

      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }
}

// ========== DELETE FOLDER DIALOG ==========

class DeleteFolderDialog extends ConsumerStatefulWidget {
  final TreeNode node;

  const DeleteFolderDialog({super.key, required this.node});

  @override
  ConsumerState<DeleteFolderDialog> createState() => _DeleteFolderDialogState();
}

class _DeleteFolderDialogState extends ConsumerState<DeleteFolderDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.red[600]),
          const SizedBox(width: 8),
          const Text('Klasörü Sil'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bu klasörü silmek istediğinizden emin misiniz?',
            style: TextStyle(fontSize: 16, color: Colors.grey[800]),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              border: Border.all(color: Colors.red[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.folder, size: 16, color: Colors.red[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.node.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Bu işlem geri alınamaz. Klasör ve içindeki tüm alt klasörler silinecektir.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleDelete,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Sil'),
        ),
      ],
    );
  }

  Future<void> _handleDelete() async {
    setState(() {
      _isLoading = true;
    });

    // Selection state'i delete başlamadan önce kaydet
    final selectedNode = ref.read(selectedTreeNodeProvider);
    final shouldClearSelection = selectedNode?.id == widget.node.id;

    try {
      AppLogger.info('🗑️ Deleting folder: ${widget.node.title}');

      final result = await ref
          .read(treeOperationsProvider)
          .deleteNode(widget.node.id);

      if (result.success) {
        AppLogger.info('✅ Folder deleted successfully');

        // Selection temizleme işlemini mounted check içinde yap
        if (mounted) {
          // Silinen node seçiliyse selection'ı temizle
          if (shouldClearSelection) {
            ref.read(treeSelectionProvider).clearSelection();
            AppLogger.info(
              '🗑️ Cleared selection for deleted node: ${widget.node.title}',
            );
          }

          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'Klasör başarıyla silindi'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception(result.message ?? 'Bilinmeyen hata');
      }
    } catch (e) {
      AppLogger.error('❌ Failed to delete folder: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silme işlemi başarısız: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
