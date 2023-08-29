import 'dart:collection';

import 'package:nitrite/nitrite.dart';

/// @nodoc
class Stack<T> {
  final ListQueue<T> _list = ListQueue();

  final int noLimit = -1;

  /// the maximum number of entries allowed on the stack. -1 = no limit.
  int _sizeMax = 0;

  Stack() {
    _sizeMax = noLimit;
  }

  /// check if the stack is empty.
  bool get isEmpty => _list.isEmpty;

  /// check if the stack is not empty.
  bool get isNotEmpty => _list.isNotEmpty;

  /// push element in top of the stack.
  void push(T e) {
    if (_sizeMax == noLimit || _list.length < _sizeMax) {
      _list.addLast(e);
    } else {
      throw InvalidOperationException("Stack is full");
    }
  }

  /// get the top of the stack and delete it.
  T pop() {
    if (isEmpty) {
      throw InvalidOperationException("Stack is empty");
    }
    T res = _list.last;
    _list.removeLast();
    return res;
  }

  /// get the top of the stack without deleting it.
  T top() {
    if (isEmpty) {
      throw InvalidOperationException("Stack is empty");
    }
    return _list.last;
  }

  /// get the size of the stack.
  int size() {
    return _list.length;
  }

  /// get the length of the stack.
  int get length => size();

  /// returns true if element is found in the stack
  bool contains(T x) {
    return _list.contains(x);
  }
}
