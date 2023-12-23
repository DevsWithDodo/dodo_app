import 'dart:collection';

class DataStack<T> {
  final _stack = Queue<T>();

  int get length => _stack.length;
  T get lastElement => _stack.last;

  void push(T element) {
    _stack.addLast(element);
  }

  T pop() {
    T lastElement = _stack.last;
    _stack.removeLast();
    return lastElement;
  }
}