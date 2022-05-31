int compare(num x, num y) {
  if (_isSpecial(x) || _isSpecial(y)) {
    return x.toDouble().compareTo(y.toDouble());
  } else {
    return x.compareTo(y);
  }
}

bool _isSpecial(num value) {
  return value is double && (value.isNaN || value.isInfinite);
}
