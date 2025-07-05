// lib/src/features/mail/presentation/widgets/mail_item/mail_item_showcase.dart

import 'package:flutter/material.dart';
import 'package:korgan/src/features/mail/domain/entities/mail.dart';
import 'package:korgan/src/utils/platform_helper.dart';
import 'mail_item.dart';

void main() {
  runApp(MailItemShowcaseApp());
}

/// Showcase app for demonstrating mail item widget across platforms
///
/// This app automatically adapts to the current platform and demonstrates
/// the platform-specific features and interactions of the MailItem widget.
class MailItemShowcaseApp extends StatelessWidget {
  const MailItemShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mail Item Showcase - ${PlatformHelper.platformName}',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        // Gmail benzeri checkbox renk teması
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF1A73E8); // Gmail mavi rengi
            }
            return Colors.transparent;
          }),
          checkColor: WidgetStateProperty.all(Colors.white),
        ),
      ),
      home: MailItemShowcase(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Main showcase widget demonstrating the adaptive mail item
class MailItemShowcase extends StatefulWidget {
  const MailItemShowcase({super.key});

  @override
  State<MailItemShowcase> createState() => _MailItemShowcaseState();
}

class _MailItemShowcaseState extends State<MailItemShowcase> {
  List<Mail> mails = [
    Mail(
      id: 'mail_001',
      senderName: 'Yapı Kredi',
      subject:
          'Akıllı Asistan-Gelen FAST Sayın ARGEN BULUT VE YAZILIM TEKNOLOJİ...',
      content:
          'Merhaba, hesabınıza FAST transfer gerçekleştirilmiştir. Detayları aşağıda bulabilirsiniz.Yeni ürün lansmanımız hakkında bilgi almak için bu e-postayı incelemenizi rica ederiz.',
      time: '27 Haz',
      isRead: false,
      isStarred: false,
    ),
    Mail(
      id: 'mail_002',
      senderName: 'Penta Teknoloji',
      subject: 'Bu e-posta tarafınıza Penta Teknoloji Ürünleri...',
      content:
          'Yeni ürün lansmanımız hakkında bilgi almak için bu e-postayı incelemenizi rica ederiz.',
      time: '27 Haz',
      isRead: true,
      isStarred: false,
    ),
    Mail(
      id: 'mail_003',
      senderName: 'Turkcell Fatura Servisi',
      subject:
          '5324658565 Turkcell E-Fatura Servisi Merhaba, Berk Göknil Ödenecek Tutar 836,40...',
      content:
          'Aylık faturanız hazır. Son ödeme tarihi: 15 Temmuz 2024. Online ödeme yapabilirsiniz.',
      time: '26 Haz',
      isRead: true,
      isStarred: true,
    ),
    Mail(
      id: 'mail_004',
      senderName: 'İSTANBUL TİCARET ODASI',
      subject: 'AIDAT HATIRLATMA Sicil No : 118791-5 Ünvan : ARGEN BULUT VE...',
      content:
          'Sayın üyemiz, aidatınızın son ödeme tarihi yaklaşmaktadır. Detaylı bilgi için...',
      time: '25 Haz',
      isRead: false,
      isStarred: true,
    ),
    Mail(
      id: 'mail_005',
      senderName: 'Netflix',
      subject: 'Your monthly bill is ready',
      content:
          'Hi there! Your Netflix bill for this month is ready. You can view and download it here.',
      time: '24 Haz',
      isRead: true,
      isStarred: false,
    ),
    Mail(
      id: 'mail_006',
      senderName: 'GitHub',
      subject: '[GitHub] Security alert: new sign-in from unknown device',
      content:
          'We detected a new sign-in to your GitHub account from a device we don\'t recognize.',
      time: '23 Haz',
      isRead: false,
      isStarred: false,
    ),
  ];

  // Mail seçim durumlarını takip eden set
  Set<int> selectedMailIndices = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mail Item Showcase'),
            Text(
              'Experience: ${PlatformHelper.recommendedExperience.toUpperCase()} (${PlatformHelper.platformName})',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          if (selectedMailIndices.isNotEmpty) ...[
            // Seçili mail sayısını göster
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${selectedMailIndices.length} seçili',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Toplu işlem butonları
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: () => _selectAllMails(),
              tooltip: 'Tümünü Seç',
            ),
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => _clearSelection(),
              tooltip: 'Seçimi Temizle',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteSelectedMails(),
              tooltip: 'Seçilenleri Sil',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Seçim bilgi paneli
          if (selectedMailIndices.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF1A73E8).withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: const Color(0xFF1A73E8),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${selectedMailIndices.length} mail seçildi',
                    style: TextStyle(
                      color: const Color(0xFF1A73E8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _clearSelection,
                    child: const Text('Temizle'),
                  ),
                ],
              ),
            ),

          // Mail list
          Expanded(
            child: ListView.separated(
              itemCount: mails.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final mail = mails[index];
                final isSelected = selectedMailIndices.contains(index);

                return MailItem(
                  mail: mail,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      mail.isRead = true;
                    });
                    _showSnackBar(context, '${mail.senderName} mail\'i açıldı');
                  },
                  onToggleSelection: () {
                    setState(() {
                      if (isSelected) {
                        selectedMailIndices.remove(index);
                      } else {
                        selectedMailIndices.add(index);
                      }
                    });
                  },
                  onArchive: () {
                    setState(() {
                      mails.removeAt(index);
                      // Index değiştiği için seçimi güncelle
                      _updateSelectionAfterRemoval(index);
                    });
                    _showSnackBar(
                      context,
                      '${mail.senderName} mail\'i arşivlendi',
                      color: Colors.green,
                    );
                  },
                  onDelete: () {
                    setState(() {
                      mails.removeAt(index);
                      // Index değiştiği için seçimi güncelle
                      _updateSelectionAfterRemoval(index);
                    });
                    _showSnackBar(
                      context,
                      '${mail.senderName} mail\'i silindi',
                      color: Colors.red,
                    );
                  },
                  onToggleStar: () {
                    setState(() {
                      mail.isStarred = !mail.isStarred;
                    });
                    _showSnackBar(
                      context,
                      mail.isStarred
                          ? '${mail.senderName} yıldızlandı ⭐'
                          : '${mail.senderName} yıldızı kaldırıldı',
                    );
                  },
                  onToggleRead: () {
                    setState(() {
                      mail.isRead = !mail.isRead;
                    });
                    _showSnackBar(
                      context,
                      mail.isRead
                          ? '${mail.senderName} okundu olarak işaretlendi'
                          : '${mail.senderName} okunmadı olarak işaretlendi',
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _selectAllMails() {
    setState(() {
      selectedMailIndices = Set.from(
        List.generate(mails.length, (index) => index),
      );
    });
    _showSnackBar(context, 'Tüm mailler seçildi');
  }

  void _clearSelection() {
    setState(() {
      selectedMailIndices.clear();
    });
    _showSnackBar(context, 'Seçim temizlendi');
  }

  void _deleteSelectedMails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seçili Mailleri Sil'),
        content: Text(
          '${selectedMailIndices.length} mail\'i silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performBulkDelete();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _performBulkDelete() {
    final selectedCount = selectedMailIndices.length;
    // Büyükten küçüğe sırala ki index karışıklığı olmasın
    final sortedIndices = selectedMailIndices.toList()
      ..sort((a, b) => b.compareTo(a));

    setState(() {
      for (final index in sortedIndices) {
        mails.removeAt(index);
      }
      selectedMailIndices.clear();
    });

    _showSnackBar(context, '$selectedCount mail silindi', color: Colors.red);
  }

  void _updateSelectionAfterRemoval(int removedIndex) {
    // Silinen index'ten sonraki tüm seçili index'leri 1 azalt
    final newSelection = <int>{};
    for (final selectedIndex in selectedMailIndices) {
      if (selectedIndex < removedIndex) {
        newSelection.add(selectedIndex);
      } else if (selectedIndex > removedIndex) {
        newSelection.add(selectedIndex - 1);
      }
      // selectedIndex == removedIndex ise ekleme (silinen item)
    }
    selectedMailIndices = newSelection;
  }

  void _showSnackBar(BuildContext context, String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
