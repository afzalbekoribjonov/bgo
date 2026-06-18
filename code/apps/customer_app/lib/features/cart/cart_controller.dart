import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Savatdagi bitta qator.
class CartLine {
  final String menuItemId;
  final String name;
  final int price;
  final int qty;

  const CartLine({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.qty,
  });

  int get lineTotal => price * qty;

  CartLine copyWith({int? qty}) => CartLine(
        menuItemId: menuItemId,
        name: name,
        price: price,
        qty: qty ?? this.qty,
      );
}

/// Savat holati. Bir vaqtda faqat BITTA oshxonadan buyurtma (soddalik uchun).
class CartState {
  final String? restaurantId;
  final String? restaurantName;
  final List<CartLine> lines;

  const CartState({this.restaurantId, this.restaurantName, this.lines = const []});

  bool get isEmpty => lines.isEmpty;
  int get itemCount => lines.fold(0, (sum, l) => sum + l.qty);
  int get subtotal => lines.fold(0, (sum, l) => sum + l.lineTotal);
}

class CartController extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  /// Taom qo'shadi. Boshqa oshxonadan bo'lsa savatni almashtiradi (true qaytaradi).
  bool addItem({
    required String restaurantId,
    required String restaurantName,
    required String menuItemId,
    required String name,
    required int price,
  }) {
    final replaced = state.restaurantId != null &&
        state.restaurantId != restaurantId &&
        state.lines.isNotEmpty;

    final lines = replaced ? <CartLine>[] : [...state.lines];
    final index = lines.indexWhere((l) => l.menuItemId == menuItemId);
    if (index >= 0) {
      lines[index] = lines[index].copyWith(qty: lines[index].qty + 1);
    } else {
      lines.add(CartLine(
        menuItemId: menuItemId,
        name: name,
        price: price,
        qty: 1,
      ));
    }

    state = CartState(
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      lines: lines,
    );
    return replaced;
  }

  void increment(String menuItemId) {
    final lines = [
      for (final l in state.lines)
        if (l.menuItemId == menuItemId) l.copyWith(qty: l.qty + 1) else l,
    ];
    state = _withLines(lines);
  }

  void decrement(String menuItemId) {
    final lines = <CartLine>[];
    for (final l in state.lines) {
      if (l.menuItemId == menuItemId) {
        if (l.qty > 1) lines.add(l.copyWith(qty: l.qty - 1));
      } else {
        lines.add(l);
      }
    }
    state = _withLines(lines);
  }

  void clear() => state = const CartState();

  CartState _withLines(List<CartLine> lines) {
    if (lines.isEmpty) return const CartState();
    return CartState(
      restaurantId: state.restaurantId,
      restaurantName: state.restaurantName,
      lines: lines,
    );
  }
}

final cartProvider =
    NotifierProvider<CartController, CartState>(CartController.new);
