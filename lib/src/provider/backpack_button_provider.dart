import 'package:flutter_riverpod/flutter_riverpod.dart';

final backpackButtonProvider = StateProvider<List<bool>>((ref) => [true, true, true, true]);
