import 'package:eSellify/app/models/ad_model.dart';

class PriceFormatter {
  static String format(AdModel ad) {
    if (ad.isPriceOptional == true || ad.price == null) return "Negotiable";

    final c = ad.currency;
    final s = c?.symbol ?? '';
    final d = c?.decimalDigits ?? 0;

    // Convert to standard fixed string
    String p = ad.price!.toStringAsFixed(d);

    // Split into integer and decimal parts
    List<String> parts = p.split('.');

    // Add commas to the integer part using Regex
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    parts[0] = parts[0].replaceAllMapped(reg, (Match match) => '${match[1]},');

    // Rejoin the string
    p = parts.join('.');

    return c?.symbolAtRight == true ? "$p $s".trim() : "$s$p".trim();
  }
}