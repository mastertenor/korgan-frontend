// lib/common_widgets/mail/mail_item_showcase.dart
import 'package:flutter/material.dart';
import 'mail_item.dart';

void main() {
  runApp(MailItemShowcaseApp());
}

class MailItemShowcaseApp extends StatelessWidget {
  const MailItemShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Mail Item Showcase', home: MailItemShowcase());
  }
}

class MailItemShowcase extends StatefulWidget {
  const MailItemShowcase({super.key});

  @override
  State<MailItemShowcase> createState() => _MailItemShowcaseState();
}

class _MailItemShowcaseState extends State<MailItemShowcase> {
  List<MailData> mails = [
    MailData(
      senderName: 'Yapı Kredi',
      subject:
          'Akıllı Asistan-Gelen FAST Sayın ARGEN BULUT VE YAZILIM TEKNOLOJİ...',
      content:
          'Merhaba, hesabınıza FAST transfer gerçekleştirilmiştir. Detayları aşağıda bulabilirsiniz.',
      time: '27 Haz',
      isRead: false,
      isStarred: false,
    ),
    MailData(
      senderName: 'Penta Teknoloji',
      subject: 'Bu e-posta tarafınıza Penta Teknoloji Ürünleri...',
      content:
          'Yeni ürün lansmanımız hakkında bilgi almak için bu e-postayı incelemenizi rica ederiz.',
      time: '27 Haz',
      isRead: true,
      isStarred: false,
    ),
    MailData(
      senderName: 'Turkcell Fatura Servisi',
      subject:
          '5324658565 Turkcell E-Fatura Servisi Merhaba, Berk Göknil Ödenecek Tutar 836,40...',
      content:
          'Aylık faturanız hazır. Son ödeme tarihi: 15 Temmuz 2024. Online ödeme yapabilirsiniz.',
      time: '26 Haz',
      isRead: true,
      isStarred: true,
    ),
    MailData(
      senderName: 'İSTANBUL TİCARET ODASI',
      subject: 'AIDAT HATIRLATMA Sicil No : 118791-5 Ünvan : ARGEN BULUT VE...',
      content:
          'Sayın üyemiz, aidatınızın son ödeme tarihi yaklaşmaktadır. Detaylı bilgi için...',
      time: '25 Haz',
      isRead: false,
      isStarred: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mail Item Showcase'),
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: mails.length,
              itemBuilder: (context, index) {
                final mail = mails[index];
                return MailItem(
                  senderName: mail.senderName,
                  subject: mail.subject,
                  content: mail.content, // Yeni eklenen alan
                  time: mail.time,
                  isRead: mail.isRead,
                  isStarred: mail.isStarred,
                  onTap: () {
                    setState(() {
                      mail.isRead = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${mail.senderName} mail\'i açıldı'),
                      ),
                    );
                  },
                  onArchive: () {
                    setState(() {
                      mails.removeAt(index);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${mail.senderName} mail\'i arşivlendi'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  onDelete: () {
                    setState(() {
                      mails.removeAt(index);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${mail.senderName} mail\'i silindi'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                  onToggleStar: () {
                    setState(() {
                      mail.isStarred = !mail.isStarred;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          mail.isStarred
                              ? '${mail.senderName} yıldızlandı ⭐'
                              : '${mail.senderName} yıldızı kaldırıldı',
                        ),
                      ),
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
}

class MailData {
  final String senderName;
  final String subject;
  final String content; // Yeni eklenen alan
  final String time;
  bool isRead;
  bool isStarred;

  MailData({
    required this.senderName,
    required this.subject,
    required this.content, // Yeni eklenen alan
    required this.time,
    required this.isRead,
    required this.isStarred,
  });
}
