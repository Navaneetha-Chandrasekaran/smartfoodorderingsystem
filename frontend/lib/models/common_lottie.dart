import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CommonLottie {
  static bool _isDebug = false;

  static void setDebug(bool value) {
    _isDebug = value;
  }

  static Widget _buildLottie({
    required String asset,
    required double size,
    bool repeat = true,
  }) {
    return Lottie.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      repeat: repeat,
      animate: true,
      frameRate: FrameRate.max,
      options: LottieOptions(
        enableMergePaths: true,
      ),
      delegates: LottieDelegates(
        values: [
          ValueDelegate.color(
            const ['**'],
            value: Colors.green,
          ),
        ],
      ),
      onLoaded: (composition) {
        if (_isDebug) {
          print('✅ Lottie loaded: $asset');
        }
      },
    );
  }

  static Widget loading({double size = 200}) {
    return _buildLottie(
      asset: 'assets/lottie/loader.json',
      size: size,
    );
  }

  static Widget noOrders({double size = 250}) {
    return _buildLottie(
      asset: 'assets/lottie/no-order.json',
      size: size,
    );
  }

  static Widget emptyCart({double size = 200}) {
    return _buildLottie(
      asset: 'assets/lottie/cart-empty.json',
      size: size,
    );
  }

  static Widget orderPlaced({double size = 200}) {
    return _buildLottie(
      asset: 'assets/lottie/order-placed.json',
      size: size,
    );
  }

  static Widget error({double size = 200}) {
    return _buildLottie(
      asset: 'assets/lottie/error.json',
      size: size,
    );
  }
} 