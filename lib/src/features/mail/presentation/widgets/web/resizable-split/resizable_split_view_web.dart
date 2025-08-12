// ignore_for_file: avoid_web_libraries_in_flutter

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';

// Web-specific imports for DOM manipulation
import 'package:web/web.dart' as web;

// Import the interface
import 'resizable_split_view_interface.dart';

/// Web-specific implementation of ResizableSplitView
/// Supports full resizable functionality with DOM manipulation for iframe handling
class ResizableSplitView extends ResizableSplitViewInterface {
  const ResizableSplitView({
    super.key,
    required super.leftChild,
    required super.rightChild,
    super.isVertical = true,
    super.initialRatio = 0.5,
    super.onRatioChanged,
    super.minRatio = 0.1,
    super.maxRatio = 0.9,
    super.splitterThickness = 8.0,
    super.splitterColor,
    super.splitterHoverColor,
  }) : assert(initialRatio >= 0.0 && initialRatio <= 1.0),
       assert(minRatio >= 0.0 && minRatio <= 1.0),
       assert(maxRatio >= 0.0 && maxRatio <= 1.0),
       assert(minRatio < maxRatio);

  @override
  State<ResizableSplitView> createState() => _ResizableSplitViewWebState();
}

class _ResizableSplitViewWebState extends State<ResizableSplitView> {
  late double _ratio;
  bool _dragging = false;
  bool _hovering = false;

  // Build sırasında gelen son boyut; drag hesapları için gerekir
  Size _lastSize = Size.zero;

  // Kare başına tek setState ve tek onRatioChanged için throttle
  bool _frameScheduled = false;
  double? _pendingCallbackRatio;

  @override
  void initState() {
    super.initState();
    _ratio = widget.initialRatio.clamp(widget.minRatio, widget.maxRatio);
  }

  @override
  void didUpdateWidget(covariant ResizableSplitView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialRatio != oldWidget.initialRatio) {
      _ratio = widget.initialRatio.clamp(widget.minRatio, widget.maxRatio);
      _scheduleFrame();
      _scheduleOnChanged(_ratio);
    }
  }

  void _scheduleFrame() {
    if (_frameScheduled) return;
    _frameScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      if (mounted) setState(() {});
      _frameScheduled = false;

      // onRatioChanged'i kare sonunda, tek seferde gönder
      final r = _pendingCallbackRatio;
      if (r != null) {
        _pendingCallbackRatio = null;
        widget.onRatioChanged?.call(r);
      }
    });
  }

  void _scheduleOnChanged(double r) {
    _pendingCallbackRatio = r;
    _scheduleFrame();
  }

  /// DOM seviyesinde iframe pointer events kontrolü
  void _setPreviewIframesHitTestDisabled(bool disable) {
    if (!kIsWeb) return;
    try {
      final list = web.document.querySelectorAll('iframe.korgan-preview-iframe');
      // NodeList'i manuel olarak iterate edelim
      for (int i = 0; i < list.length; i++) {
        final el = list.item(i);
        if (el != null) {
          (el as web.HTMLIFrameElement).style.pointerEvents = disable ? 'none' : 'auto';
        }
      }
    } catch (_) {
      // sessizce geç
    }
  }

  @override
  void dispose() {
    _setPreviewIframesHitTestDisabled(false);
    super.dispose();
  }

  // Mutlak konumdan oran hesapla (delta değil)
  void _updateFromLocalPosition(Offset local, Size size) {
    final total = widget.isVertical ? size.width : size.height;
    if (total <= 0) return;

    double raw = widget.isVertical ? (local.dx / total) : (local.dy / total);
    final clamped = raw.clamp(widget.minRatio, widget.maxRatio);

    // Küçük sapmalarda gereksiz yeniden çizimi önle
    if ((clamped - _ratio).abs() > 0.0005) {
      _ratio = clamped;
      _scheduleFrame();
      _scheduleOnChanged(_ratio);
    }
  }

  Rect _splitterRect(Size size, double primaryPx) {
    if (widget.isVertical) {
      return Rect.fromLTWH(primaryPx, 0, widget.splitterThickness, size.height);
    } else {
      return Rect.fromLTWH(0, primaryPx, size.width, widget.splitterThickness);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        _lastSize = size;

        final total = widget.isVertical ? size.width : size.height;
        final primaryPx = (total * _ratio).clamp(0.0, total);
        final rect = _splitterRect(size, primaryPx);

        final splitterColor = () {
          if (_dragging) {
            return (widget.splitterColor ??
                    theme.colorScheme.onSurface.withOpacity(0.08))
                .withOpacity(0.12);
          }
          if (_hovering) {
            return widget.splitterHoverColor ??
                theme.colorScheme.onSurface.withOpacity(0.08);
          }
          return widget.splitterColor ??
              theme.colorScheme.onSurface.withOpacity(0.05);
        }();

        // Görsel splitter (8px) + geniş hitbox (inflate)
        final hitbox = rect.inflate(12); // 24px toplam etkileşim alanı

        return Listener(
          onPointerDown: (e) {
            if (hitbox.contains(e.localPosition)) {
              _dragging = true;
              _setPreviewIframesHitTestDisabled(true);
              HapticFeedback.selectionClick();
              _updateFromLocalPosition(e.localPosition, size);
            }
          },
          onPointerMove: (e) {
            if (!_dragging) return;
            _updateFromLocalPosition(e.localPosition, size);
          },
          onPointerUp: (_) {
            if (_dragging) {
              _dragging = false;
              _setPreviewIframesHitTestDisabled(false);
              HapticFeedback.selectionClick();
              _scheduleFrame();
            }
          },
          onPointerCancel: (_) {
            if (_dragging) {
              _dragging = false;
              _setPreviewIframesHitTestDisabled(false);
              _scheduleFrame();
            }
          },
          child: Stack(
            children: [
              // Primary (left/top)
              Positioned(
                left: 0,
                top: 0,
                width: widget.isVertical ? primaryPx : size.width,
                height: widget.isVertical ? size.height : primaryPx,
                child: const RepaintBoundary(child: _Slot(which: _SlotWhich.primary)),
              ),

              // Secondary (right/bottom)
              Positioned(
                left: widget.isVertical ? (primaryPx + widget.splitterThickness) : 0,
                top: widget.isVertical ? 0 : (primaryPx + widget.splitterThickness),
                width: widget.isVertical
                    ? (size.width - primaryPx - widget.splitterThickness)
                    : size.width,
                height: widget.isVertical
                    ? size.height
                    : (size.height - primaryPx - widget.splitterThickness),
                child: const RepaintBoundary(child: _Slot(which: _SlotWhich.secondary)),
              ),

              // Splitter görseli
              Positioned.fromRect(
                rect: rect,
                child: MouseRegion(
                  cursor: widget.isVertical
                      ? SystemMouseCursors.resizeColumn
                      : SystemMouseCursors.resizeRow,
                  onEnter: (_) => setState(() => _hovering = true),
                  onExit: (_) => setState(() => _hovering = false),
                  child: Container(
                    color: splitterColor,
                    alignment: Alignment.center,
                    child: _SplitterHandle(isVertical: widget.isVertical, active: _dragging),
                  ),
                ),
              ),

              // Geniş etkileşim alanı (görünmez), pan jestleri ve cursor burada
              Positioned.fromRect(
                rect: hitbox,
                child: MouseRegion(
                  cursor: widget.isVertical
                      ? SystemMouseCursors.resizeColumn
                      : SystemMouseCursors.resizeRow,
                  onEnter: (_) => setState(() => _hovering = true),
                  onExit: (_) => setState(() => _hovering = false),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (d) {
                      _dragging = true;
                      _setPreviewIframesHitTestDisabled(true);
                      HapticFeedback.selectionClick();
                      final box = context.findRenderObject() as RenderBox?;
                      if (box != null) {
                        final local = box.globalToLocal(d.globalPosition);
                        _updateFromLocalPosition(local, _lastSize);
                      }
                    },
                    onPanUpdate: (d) {
                      if (!_dragging) return;
                      final box = context.findRenderObject() as RenderBox?;
                      if (box == null) return;
                      final local = box.globalToLocal(d.globalPosition);
                      _updateFromLocalPosition(local, _lastSize);
                    },
                    onPanEnd: (_) {
                      if (_dragging) {
                        _dragging = false;
                        _setPreviewIframesHitTestDisabled(false);
                        HapticFeedback.selectionClick();
                        _scheduleFrame();
                      }
                    },
                    onDoubleTap: () {
                      _ratio = widget.initialRatio.clamp(widget.minRatio, widget.maxRatio);
                      _scheduleFrame();
                      _scheduleOnChanged(_ratio);
                    },
                  ),
                ),
              ),

              // Çocukları yerleştir (gerçek child'lar)
              // Primary
              Positioned(
                left: 0,
                top: 0,
                width: widget.isVertical ? primaryPx : size.width,
                height: widget.isVertical ? size.height : primaryPx,
                child: _ChildProxy(child: widget.leftChild),
              ),
              // Secondary
              Positioned(
                left: widget.isVertical ? (primaryPx + widget.splitterThickness) : 0,
                top: widget.isVertical ? 0 : (primaryPx + widget.splitterThickness),
                width: widget.isVertical
                    ? (size.width - primaryPx - widget.splitterThickness)
                    : size.width,
                height: widget.isVertical
                    ? size.height
                    : (size.height - primaryPx - widget.splitterThickness),
                child: _ChildProxy(child: widget.rightChild),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Görsel splitter sapı
class _SplitterHandle extends StatelessWidget {
  final bool isVertical;
  final bool active;
  const _SplitterHandle({required this.isVertical, required this.active});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final handleColor = active
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withOpacity(0.4);

    return Container(
      width: isVertical ? 2 : 20,
      height: isVertical ? 20 : 2,
      decoration: BoxDecoration(
        color: handleColor,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

/// İçerikleri boyamadan önce iskeleti yerleştirmek için boş slotlar.
enum _SlotWhich { primary, secondary }

class _Slot extends StatelessWidget {
  final _SlotWhich which;
  const _Slot({required this.which});

  @override
  Widget build(BuildContext context) {
    // Boş bir placeholder; asıl içerik _ChildProxy ile ayrıca yerleştiriliyor.
    return const SizedBox.expand();
  }
}

/// Çocukları Stack içinde doğru pozisyona yerleştirmek için proxy.
/// RepaintBoundary üstünde gerçek child'ı taşıyoruz.
class _ChildProxy extends StatelessWidget {
  final Widget child;
  const _ChildProxy({required this.child});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(child: child);
  }
}