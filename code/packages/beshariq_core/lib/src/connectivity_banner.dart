import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Butun ilova ustiga o'raladi (odatda `MaterialApp.builder`): tarmoq
/// yo'qligida tepada tor qizil banner ko'rsatadi, qayta ulanganda avtomatik
/// yashiradi. Faqat tarmoq INTERFEYSI holatini tekshiradi (haqiqiy internet
/// yetishga emas) — bu allaqachon eng aniq/tez-tez uchraydigan holat
/// (samolyot rejimi, wifi/mobil ma'lumot o'chirilgan); har bir alohida
/// so'rovning o'z xato-boshqaruvi (isNetworkError) qolgan holatlarni qamraydi.
class ConnectivityBanner extends StatefulWidget {
  final Widget child;
  final String message;

  const ConnectivityBanner({
    super.key,
    required this.child,
    required this.message,
  });

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  bool _offline = false;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  void initState() {
    super.initState();
    Connectivity().checkConnectivity().then(_apply).catchError((_) {});
    _sub = Connectivity()
        .onConnectivityChanged
        .listen(_apply, onError: (_) {});
  }

  void _apply(List<ConnectivityResult> results) {
    final offline =
        results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    if (mounted && offline != _offline) setState(() => _offline = offline);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              offset: _offline ? Offset.zero : const Offset(0, -1),
              child: SafeArea(
                bottom: false,
                child: Material(
                  color: const Color(0xFFC62828),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
