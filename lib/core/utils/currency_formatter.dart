/// Indian Rupee currency formatting utilities.
class CurrencyFormatter {
  static String formatINR(double amount) {
    // Basic Indian numbering format representation
    if (amount >= 10000000) {
      double cr = amount / 10000000;
      return '₹${cr.toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      double lk = amount / 100000;
      return '₹${lk.toStringAsFixed(2)} Lakh';
    } else if (amount >= 1000) {
      double k = amount / 1000;
      return '₹${k.toStringAsFixed(1)} K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }
}
