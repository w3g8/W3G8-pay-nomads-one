/// EMVCo QR Ph TLV parser for merchant-presented QR codes.

class QRPhData {
  final String formatIndicator;
  final String initiationMethod; // 'static' or 'dynamic'
  final String acquirerBIC;
  final String merchantId;
  final String? terminalId;
  final String mcc;
  final String mccDescription;
  final String currency;
  final String currencyCode;
  final double? amount;
  final String countryCode;
  final String merchantName;
  final String merchantCity;
  final String? referenceLabel;
  final bool crcValid;
  final String rawData;

  QRPhData({
    required this.formatIndicator,
    required this.initiationMethod,
    required this.acquirerBIC,
    required this.merchantId,
    this.terminalId,
    required this.mcc,
    required this.mccDescription,
    required this.currency,
    required this.currencyCode,
    this.amount,
    required this.countryCode,
    required this.merchantName,
    required this.merchantCity,
    this.referenceLabel,
    required this.crcValid,
    required this.rawData,
  });
}

const mccMap = {
  '4121': 'Taxi & Rideshare',
  '5311': 'Department Store',
  '5411': 'Grocery Store',
  '5499': 'Convenience Store',
  '5541': 'Gas Station',
  '5812': 'Restaurant',
  '5813': 'Bar & Nightclub',
  '5814': 'Fast Food',
  '5912': 'Pharmacy',
  '5999': 'General Retail',
  '7011': 'Hotel & Lodging',
  '7230': 'Barber & Beauty',
  '7297': 'Massage & Spa',
  '8999': 'Professional Services',
};

const currencyMap = {
  '608': 'PHP',
  '840': 'USD',
  '826': 'GBP',
  '978': 'EUR',
};

const bicMap = {
  'BNORPHMMXXX': 'BDO',
  'BPABORSMR': 'BPI',
  'RCBCPHMMXXX': 'RCBC',
  'UBPHPHMM': 'UnionBank',
  'PNBMPHMM': 'PNB',
  'GCASHPHM': 'GCash',
  'MAYAPHM0': 'Maya',
  'EWBCPHMM': 'EastWest',
  'CHBKPHMM': 'China Bank',
  'SETCPHMM': 'Security Bank',
};

String bicLabel(String bic) => bicMap[bic] ?? bic;

Map<String, String> parseTLV(String data) {
  final result = <String, String>{};
  var pos = 0;
  while (pos < data.length - 3) {
    final tag = data.substring(pos, pos + 2);
    final lenStr = data.substring(pos + 2, pos + 4);
    final len = int.tryParse(lenStr);
    if (len == null || pos + 4 + len > data.length) break;
    result[tag] = data.substring(pos + 4, pos + 4 + len);
    pos += 4 + len;
  }
  return result;
}

int crc16ccitt(String data) {
  var crc = 0xFFFF;
  for (var i = 0; i < data.length; i++) {
    crc ^= data.codeUnitAt(i) << 8;
    for (var j = 0; j < 8; j++) {
      if (crc & 0x8000 != 0) {
        crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
      } else {
        crc = (crc << 1) & 0xFFFF;
      }
    }
  }
  return crc;
}

bool verifyCRC(String raw) {
  if (raw.length < 8) return false;
  final crcTag = raw.substring(raw.length - 4);
  final dataWithoutCRC = raw.substring(0, raw.length - 4);
  final computed = crc16ccitt(dataWithoutCRC).toRadixString(16).toUpperCase().padLeft(4, '0');
  return computed == crcTag.toUpperCase();
}

Map<String, String>? findMerchantInfo(Map<String, String> tlv) {
  for (var tag = 26; tag <= 51; tag++) {
    final tagStr = tag.toString().padLeft(2, '0');
    final value = tlv[tagStr];
    if (value != null) {
      final sub = parseTLV(value);
      final guid = sub['00'];
      if (guid != null && guid.contains('ph.ppmi')) {
        return sub;
      }
    }
  }
  return null;
}

QRPhData? parseQRPh(String raw) {
  final trimmed = raw.trim();
  final tlv = parseTLV(trimmed);

  if (tlv['00'] != '01') return null;

  final merchantInfo = findMerchantInfo(tlv);
  if (merchantInfo == null) return null;

  final mcc = tlv['52'] ?? '';
  final currencyCode = tlv['53'] ?? '608';
  final amountStr = tlv['54'];

  String? refLabel;
  final addl = tlv['62'];
  if (addl != null) {
    final sub = parseTLV(addl);
    refLabel = sub['05'] ?? sub['07'];
  }

  return QRPhData(
    formatIndicator: '01',
    initiationMethod: tlv['01'] == '12' ? 'dynamic' : 'static',
    acquirerBIC: merchantInfo['01'] ?? '',
    merchantId: merchantInfo['03'] ?? merchantInfo['02'] ?? '',
    terminalId: merchantInfo['05'] ?? merchantInfo['07'],
    mcc: mcc,
    mccDescription: mccMap[mcc] ?? 'Merchant',
    currency: currencyMap[currencyCode] ?? currencyCode,
    currencyCode: currencyCode,
    amount: amountStr != null ? double.tryParse(amountStr) : null,
    countryCode: tlv['58'] ?? 'PH',
    merchantName: tlv['59'] ?? 'Unknown Merchant',
    merchantCity: tlv['60'] ?? '',
    referenceLabel: refLabel,
    crcValid: verifyCRC(trimmed),
    rawData: trimmed,
  );
}

String generateQRPh({
  required String merchantName,
  required String merchantCity,
  required String merchantId,
  required String acquirerBIC,
  required String mcc,
  double? amount,
}) {
  String tlv(String tag, String value) =>
      '$tag${value.length.toString().padLeft(2, '0')}$value';

  var mai = '${tlv('00', 'ph.ppmi.p2m')}${tlv('01', acquirerBIC)}${tlv('03', merchantId)}';

  var qr = '';
  qr += tlv('00', '01');
  qr += tlv('01', amount != null ? '12' : '11');
  qr += tlv('28', mai);
  qr += tlv('52', mcc);
  qr += tlv('53', '608');
  if (amount != null) {
    qr += tlv('54', amount.toStringAsFixed(2));
  }
  qr += tlv('58', 'PH');
  qr += tlv('59', merchantName.length > 25 ? merchantName.substring(0, 25) : merchantName);
  qr += tlv('60', merchantCity.length > 15 ? merchantCity.substring(0, 15) : merchantCity);
  qr += '6304';

  final crc = crc16ccitt(qr).toRadixString(16).toUpperCase().padLeft(4, '0');
  return '$qr$crc';
}
