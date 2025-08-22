// lib/src/features/mail/utils/cid_resolver.dart

import 'dart:async';
import 'dart:convert';

import '../../domain/entities/attachment.dart';
import '../../domain/entities/mail_detail.dart';
import '../../domain/repositories/mail_repository.dart';

/// CID Resolver - e-posta gövdesindeki `cid:` referanslarını çözer ve
/// ilgili ekleri indirip data URL'e çevirerek HTML'i işler.
///
/// Kapsam (>%90 hedefi):
/// - <img src="cid:..."> ve tek/çift tırnak + boşluk/tire varyasyonları
/// - srcset="cid:a 1x, cid:b 2x" (çoklu çözünürlük)
/// - style="background-image:url(cid:...)" gibi inline CSS
/// - <style> ... url(cid:...) ... </style> blokları
///
/// Eşleştirme sezgileri (ek alanlar zorunlu değil):
/// 1) filename-based CID (cid 'image001.jpg@...' ile başlar → attachment.filename == image001.jpg)
/// 2) cid == filename veya filename'siz gövdeyi içerir (stem)
/// 3) cid == id (veya id'yi içerir) eşleşmesi
/// 4) inline + image/* ve cid 'img_' paterni
/// 5) tek bir inline image eklentisi varsa o (son çare)
///
/// Performans:
/// - Tüm benzersiz CID'ler tek seferde toplanır
/// - Eşleşen ekler sadece 1 kez indirilir (Future.wait)
/// - Aynı ek birden fazla CID ile işaretlenmişse aynı data URL kullanılır
class CidResolver {
  /// Büyük veri gövdelerini gömme sınırı (opsiyonel koruma).
  /// Çok büyük base64'ler iframe'leri şişirir; aşılırsa o CID atlanır.
  static const int kMaxEmbeddedBytes = 20 * 1024 * 1024; // 20MB

  /// Ana giriş: HTML içindeki `cid:` referanslarını çözer.
  static Future<String> resolveCidsInHtml(
    String htmlContent,
    MailDetail mailDetail,
    String userEmail,
    MailRepository repository,
  ) async {
    if (htmlContent.isEmpty || !(mailDetail.hasAttachments == true)) {
      return htmlContent;
    }

    final attachments = mailDetail.attachments;
    if (attachments.isEmpty) return htmlContent;

    print('🔧 CidResolver: start; attachments=${attachments.length}');

    // 1) HTML içinden tüm CID'leri topla (img/src, srcset, url() hem inline style hem <style> içinde)
    final allCids = _collectAllCidValues(htmlContent);
    if (allCids.isEmpty) {
      print('ℹ️ CidResolver: no cid: references found.');
      return htmlContent;
    }

    // 2) Eşleştirme: CID -> Attachment
    final resolver = _AttachmentResolver(attachments);
    final Map<String, MailAttachment> cidToAttachment = {};
    int matched = 0, unmatched = 0;

    for (final rawCid in allCids) {
      final a = resolver.findAttachmentForCid(rawCid, mailDetail);
      if (a != null) {
        cidToAttachment[rawCid] = a;
        matched++;
      } else {
        unmatched++;
        print('⚠️ CID not matched: "$rawCid"');
      }
    }

    print('🔎 CidResolver: total CIDs=${allCids.length}, matched=$matched, unmatched=$unmatched');

    if (cidToAttachment.isEmpty) {
      // hi̇çbiri eşleşmediyse html aynen döndür
      return htmlContent;
    }

    // 3) Benzersiz attachment'ları tek seferde indir → attachmentId -> dataUrl
    final Map<String, String> attachmentIdToDataUrl =
        await _downloadAttachmentsAsDataUrls(mailDetail, userEmail, repository, cidToAttachment.values.toSet());

    // 4) CID -> dataUrl haritası oluştur
    final Map<String, String> cidToDataUrl = {};
    cidToAttachment.forEach((cid, att) {
      final dataUrl = attachmentIdToDataUrl[att.id];
      if (dataUrl != null) {
        cidToDataUrl[cid] = dataUrl;
      }
    });

    if (cidToDataUrl.isEmpty) {
      print('⚠️ CidResolver: downloads produced no embeddable data. Returning original HTML.');
      return htmlContent;
    }

    // 5) HTML dönüşümü: tüm yerlerdeki cid:... → data:... dönüştür
    String resolved = htmlContent;

    // 5a) <img ... src="cid:..."> / src='cid:...' (tüm varyasyonlar)
    resolved = _replaceImgSrcCids(resolved, cidToDataUrl);

    // 5b) srcset="cid:... 1x, cid:... 2x"
    resolved = _replaceSrcsetCids(resolved, cidToDataUrl);

    // 5c) url(cid:...) hem inline style attr'larında hem de <style> bloklarında
    resolved = _replaceCssUrlCids(resolved, cidToDataUrl);

    final replacedCount = _countReplacements(htmlContent, resolved);
    print('✅ CidResolver: replaced occurrences ≈ $replacedCount; done.');
    return resolved;
  }

  /// Basit kontrol: HTML 'cid:' referansı içeriyor mu?
  static bool containsCidReferences(String htmlContent) {
    return htmlContent.toLowerCase().contains('cid:');
  }

  /// Tüm CID değerlerini döndürür (img/src, srcset, url(cid:...))
  static List<String> extractCidValues(String htmlContent) {
    return _collectAllCidValues(htmlContent).toList(growable: false);
  }

  /// Teşhis çıktısı
  static CidAnalysisResult analyzeCids(String htmlContent, MailDetail mailDetail) {
    final cids = _collectAllCidValues(htmlContent);
    if (cids.isEmpty) {
      return CidAnalysisResult(
        totalCids: 0,
        foundAttachments: 0,
        missingCids: const [],
        totalAttachments: mailDetail.attachments.length,
      );
    }

    final resolver = _AttachmentResolver(mailDetail.attachments);
    int found = 0;
    final missing = <String>[];
    for (final cid in cids) {
      final a = resolver.findAttachmentForCid(cid, mailDetail);
      if (a != null) {
        found++;
      } else {
        missing.add(cid);
      }
    }

    return CidAnalysisResult(
      totalCids: cids.length,
      foundAttachments: found,
      missingCids: missing,
      totalAttachments: mailDetail.attachments.length,
    );
  }

  // ======== İ N D İ R M E & E N K O D E ========

  static Future<Map<String, String>> _downloadAttachmentsAsDataUrls(
    MailDetail mailDetail,
    String userEmail,
    MailRepository repository,
    Set<MailAttachment> uniqueAttachments,
  ) async {
    final Map<String, String> out = {};

    // İndirmeleri paralel çalıştır
    final futures = <Future<void>>[];

    for (final att in uniqueAttachments) {
      futures.add(() async {
        try {
          // Sadece image/* tiplerini embed edelim (SVG dahil)
          if (!(att.mimeType.toLowerCase().startsWith('image/'))) {
            print('ℹ️ Skip non-image attachment: ${att.filename} (${att.mimeType})');
            return;
          }

          final res = await repository.downloadAttachment(
            messageId: mailDetail.id,
            attachmentId: att.id,
            filename: att.filename,
            email: userEmail,
            mimeType: att.mimeType,
          );

          final ok = res.when(
            success: (bytes) {
              if (bytes.isEmpty) {
                print('⚠️ Empty content for ${att.filename}');
                return false;
              }
              if (bytes.length > kMaxEmbeddedBytes) {
                print('⚠️ Too large to embed (${_formatFileSize(bytes.length)}): ${att.filename}');
                return false;
              }
              final b64 = base64Encode(bytes);
              final dataUrl = 'data:${att.mimeType};base64,$b64';
              out[att.id] = dataUrl;
              print('⬇️  downloaded ${att.filename} → ${_formatFileSize(bytes.length)}');
              return true;
            },
            failure: (error) {
              print('❌ Download failed for ${att.filename}: ${error.message}');
              return false;
            },
          );

          if (ok != true) {
            // no-op; loglandı
          }
        } catch (e) {
          print('❌ Exception while downloading ${att.filename}: $e');
        }
      }());
    }

    await Future.wait(futures);
    return out;
  }

// ======== H T M L   D Ö N Ü Ş T Ü R M E ========

  // <img ... src="cid:..."> (tek/çift tırnak, boşluklar, attribute sırası fark etmez)
  static final RegExp _imgSrcCid = RegExp(
    r"""<img\b([^>]*?)\bsrc\s*=\s*(['"])\s*cid:([^'"]+)\s*\2([^>]*)>""",
    caseSensitive: false,
    dotAll: true,
  );

  // srcset attr'ında cid:... geçen değerler
  static final RegExp _attrSrcset = RegExp(
    r"""\bsrcset\s*=\s*(['"])([^'"]*cid:[^'"]+[^'"]*)\1""",
    caseSensitive: false,
    dotAll: true,
  );

  // Herhangi bir string içinde cid:... yakalamak için (srcset alt-regex)
  static final RegExp _cidInside = RegExp(
    r"""cid:([^\s,'")]+)""",
    caseSensitive: false,
  );

  // url(cid:...) (hem inline style="..." hem <style> bloklarında)
  static final RegExp _cssUrlCid = RegExp(
    r"""url\(\s*cid:([^)'"\s]+)\s*\)""",
    caseSensitive: false,
  );

  static String _replaceImgSrcCids(String html, Map<String, String> cidToDataUrl) {
    return html.replaceAllMapped(_imgSrcCid, (m) {
      final before = m.group(1) ?? '';
      final quote = m.group(2) ?? '"';
      final rawCid = m.group(3) ?? '';
      final after = m.group(4) ?? '';
      final norm = _normCid(rawCid);
      final dataUrl = cidToDataUrl[norm] ?? cidToDataUrl[rawCid] ?? '';

      if (dataUrl.isEmpty) {
        // Eşleşmeyen cid için orijinali bırak
        return m.group(0)!;
      }
      return '<img${before}src=$quote$dataUrl$quote$after>';
    });
  }

  static String _replaceSrcsetCids(String html, Map<String, String> cidToDataUrl) {
    return html.replaceAllMapped(_attrSrcset, (m) {
      final quote = m.group(1) ?? '"';
      final val = m.group(2) ?? '';
      final replaced = val.replaceAllMapped(_cidInside, (mm) {
        final rawCid = mm.group(1) ?? '';
        final norm = _normCid(rawCid);
        final dataUrl = cidToDataUrl[norm] ?? cidToDataUrl[rawCid];
        return dataUrl != null ? dataUrl : 'cid:$rawCid';
      });
      return 'srcset=$quote$replaced$quote';
    });
  }

  static String _replaceCssUrlCids(String html, Map<String, String> cidToDataUrl) {
    return html.replaceAllMapped(_cssUrlCid, (m) {
      final rawCid = m.group(1) ?? '';
      final norm = _normCid(rawCid);
      final dataUrl = cidToDataUrl[norm] ?? cidToDataUrl[rawCid];
      if (dataUrl == null) return m.group(0)!;
      return 'url($dataUrl)';
    });
  }

  static int _countReplacements(String before, String after) {
    // kaba tahmin: kaç tane "data:" görsel eklendi
    final b = 'data:';
    final c1 = _countOccurrences(before, b);
    final c2 = _countOccurrences(after, b);
    return (c2 - c1).clamp(0, 1 << 30);
  }

  static int _countOccurrences(String s, String needle) {
    int count = 0, index = 0;
    while (true) {
      index = s.indexOf(needle, index);
      if (index == -1) break;
      count++;
      index += needle.length;
    }
    return count;
  }

  // ======== C I D   T O P L A M A ========

  static Set<String> _collectAllCidValues(String html) {
    final out = <String>{};

    // <img src="cid:...">
    for (final m in _imgSrcCid.allMatches(html)) {
      final v = (m.group(3) ?? '').trim();
      if (v.isNotEmpty) out.add(_normCid(v));
    }

    // srcset="... cid:... , cid:... ..."
    for (final m in _attrSrcset.allMatches(html)) {
      final val = m.group(2) ?? '';
      for (final mm in _cidInside.allMatches(val)) {
        final v = (mm.group(1) ?? '').trim();
        if (v.isNotEmpty) out.add(_normCid(v));
      }
    }

    // url(cid:...)
    for (final m in _cssUrlCid.allMatches(html)) {
      final v = (m.group(1) ?? '').trim();
      if (v.isNotEmpty) out.add(_normCid(v));
    }

    return out;
  }

  // ======== U T İ L ========

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  static String _normCid(String cid) {
    // <cid> , 'cid' , "cid" varyasyonları; trim + lowercase
    var s = cid.trim();
    if (s.startsWith('<') && s.endsWith('>')) {
      s = s.substring(1, s.length - 1);
    }
    if ((s.startsWith('"') && s.endsWith('"')) || (s.startsWith("'") && s.endsWith("'"))) {
      s = s.substring(1, s.length - 1);
    }
    return s.toLowerCase();
  }

  static String _norm(String s) => s.trim().toLowerCase();

  static String _filenameStem(String filename) {
    final i = filename.lastIndexOf('.');
    return i > 0 ? filename.substring(0, i) : filename;
  }
}

/// Eşleştirme sezgilerini kapsayan yardımcı sınıf.
/// NOT: MailAttachment'ta contentId/contentLocation yoksa, filename/ID tabanlı
/// yollarla %90+ kapsama hedeflenir.
class _AttachmentResolver {
  final List<MailAttachment> attachments;

  _AttachmentResolver(this.attachments);

  MailAttachment? findAttachmentForCid(String rawCid, MailDetail mailDetail) {
    final cid = CidResolver._normCid(rawCid);

    // İndeksler
    final filenameIndex = <String, MailAttachment>{}; // filename lower -> att
    final stemIndex = <String, MailAttachment>{};     // stem lower -> att
    final idIndex = <String, MailAttachment>{};       // id lower -> att
    final imageAttachments = <MailAttachment>[];
    final inlineImageAttachments = <MailAttachment>[];

    for (final a in attachments) {
      final fnLower = CidResolver._norm(a.filename);
      filenameIndex[fnLower] = a;
      stemIndex[CidResolver._norm(CidResolver._filenameStem(a.filename))] = a;
      idIndex[CidResolver._norm(a.id)] = a;

      final isImage = a.mimeType.toLowerCase().startsWith('image/');
      if (isImage) {
        imageAttachments.add(a);
        if (a.isInline == true) inlineImageAttachments.add(a);
      }
    }

    // 0) ID tam eşleşmesi
    final byId = idIndex[cid];
    if (byId != null) return byId;

    // 1) filename-based CID (image001.jpg@...)
    for (final entry in filenameIndex.entries) {
      final fn = entry.key; // lower
      if (cid.startsWith(fn)) {
        final tail = cid.substring(fn.length);
        if (tail.isEmpty || tail.startsWith('@')) return entry.value;
      }
    }

    // 2) cid == filename veya cid içinde filename/stem
    final byFull = filenameIndex[cid];
    if (byFull != null) return byFull;

    for (final entry in filenameIndex.entries) {
      if (cid.contains(entry.key)) return entry.value;
    }
    for (final entry in stemIndex.entries) {
      if (cid.contains(entry.key)) return entry.value;
    }

    // 3) Froala / Mailtrap paternleri
    //    Örn: img_1755851537092_0  → çoğunlukla tek görsel ekine karşılık gelir.
    final isFroalaImg = RegExp(r'^img_\d+_\d+$').hasMatch(cid);
    if (isFroalaImg) {
      // 3a) Önce inline image varsa ilkini al
      if (inlineImageAttachments.isNotEmpty) {
        return inlineImageAttachments.first;
      }
      // 3b) Tek görsel eki varsa onu al
      if (imageAttachments.length == 1) {
        return imageAttachments.first;
      }
      // 3c) PNG/JPEG uyumu arayalım (Froala genelde png üretir)
      MailAttachment? png;
      if (imageAttachments.isNotEmpty) {
        png = imageAttachments.firstWhere(
          (a) => a.mimeType.toLowerCase().contains('png'),
          orElse: () => imageAttachments.first,
        );
      }
      if (png != null) return png;
    }

    // 4) Heuristik: 'img_' içeriyorsa (inline flag gelmese bile)
    if (cid.contains('img_')) {
      if (inlineImageAttachments.isNotEmpty) return inlineImageAttachments.first;
      if (imageAttachments.length == 1) return imageAttachments.first;
      // 'image_\d+' dosya adı eşleşmesi varsa yakala
        MailAttachment? imgName;
        if (imageAttachments.isNotEmpty) {
          imgName = imageAttachments.firstWhere(
            (a) => RegExp(r'^image[_-]?\d+', caseSensitive: false).hasMatch(a.filename),
            orElse: () => imageAttachments.first,
          );
        }
        if (imgName != null) return imgName;
    }

    // 5) Son çareler:
    // 5a) Tek inline image varsa
    if (inlineImageAttachments.length == 1) return inlineImageAttachments.first;

    // 5b) Tek görsel eki varsa (inline olmasa da)
    if (imageAttachments.length == 1) return imageAttachments.first;

    // 5c) Hiçbiri olmadıysa ve toplam ek 1 ise onu dön (güvenli değil ama pratik)
    if (attachments.length == 1) return attachments.first;

    // Yok
    return null;
  }
}

/// CID teşhis çıktısı
class CidAnalysisResult {
  final int totalCids;
  final int foundAttachments;
  final List<String> missingCids;
  final int totalAttachments;

  const CidAnalysisResult({
    required this.totalCids,
    required this.foundAttachments,
    required this.missingCids,
    required this.totalAttachments,
  });

  bool get hasMissingCids => missingCids.isNotEmpty;
  bool get allFound => totalCids > 0 && foundAttachments == totalCids;

  @override
  String toString() {
    return 'CidAnalysisResult('
        'total: $totalCids, '
        'found: $foundAttachments, '
        'missing: ${missingCids.length}, '
        'attachments: $totalAttachments'
        ')';
  }
}
