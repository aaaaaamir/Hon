import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// آخرین پیام خطا که باید به کاربر نشون داده بشه — چه از build یه ویجت،
/// چه از FlutterError.onError، چه از خطاهای async ناگهانی.
final ValueNotifier<String?> globalErrorMessage = ValueNotifier<String?>(null);

void reportGlobalError(String message) {
  globalErrorMessage.value = message;
}

/// دور کل اپ می‌پیچه؛ هر وقت خطایی ثبت بشه، یه بنر قرمز بالای صفحه
/// با متن کامل خطا و دکمه‌ی کپی نشون می‌ده — حتی تو build ریلیز.
class ErrorBannerOverlay extends StatelessWidget {
  final Widget child;
  const ErrorBannerOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        ValueListenableBuilder<String?>(
          valueListenable: globalErrorMessage,
          builder: (context, message, _) {
            if (message == null) return const SizedBox.shrink();
            return Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB3261E),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 6)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text('خطا رخ داد',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                              onPressed: () => globalErrorMessage.value = null,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 160),
                          child: SingleChildScrollView(
                            child: SelectableText(
                              message,
                              style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: message));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('متن خطا کپی شد'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white),
                            label: const Text('کپی خطا', style: TextStyle(color: Colors.white)),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white24,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
