import 'package:flutter_riverpod/flutter_riverpod.dart';

final joyButtonStateProvider =
    StateNotifierProvider<JoystickController<bool>, List<bool>>((ref) => JoystickController([]));

final joyAxisStateProvider =
    StateNotifierProvider<JoystickController<double>, List<double>>((ref) => JoystickController([]));

class JoystickController<T> extends StateNotifier<List<T>> {
  JoystickController(List<T> state) : super(state);

  updateState(List<T> t) {
    // print("[JoystickController][updateState] ${t.toString()}");
    state = [...t];
  }
}
