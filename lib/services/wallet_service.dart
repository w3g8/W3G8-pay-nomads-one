import 'api_client.dart';

class WalletService {
  // Accounts
  Future<List<dynamic>> getAccounts() async {
    return await ApiClient.get('/accounts') as List<dynamic>;
  }

  Future<Map<String, dynamic>> getAccountBalance(int id) async {
    return await ApiClient.get('/accounts/$id/balance');
  }

  Future<List<dynamic>> getTransactions(int accountId, {int limit = 20}) async {
    return await ApiClient.get('/accounts/$accountId/transactions?limit=$limit');
  }

  // Dashboard
  Future<Map<String, dynamic>> getDashboard() async {
    return await ApiClient.get('/dashboard');
  }

  Future<Map<String, dynamic>> getQuickStats() async {
    return await ApiClient.get('/dashboard/quick-stats');
  }

  // Exchange rates
  Future<List<dynamic>> getFXRates() async {
    return await ApiClient.get('/exchange-rates/all') as List<dynamic>;
  }

  Future<Map<String, dynamic>> getFXQuote({
    required String from,
    required String to,
    required double amount,
  }) async {
    return await ApiClient.post('/fx/quote', {
      'from_currency': from,
      'to_currency': to,
      'amount': amount,
    });
  }

  Future<Map<String, dynamic>> executeFX({
    required String from,
    required String to,
    required double amount,
    required int sourceAccountId,
    required int targetAccountId,
  }) async {
    return await ApiClient.post('/fx/execute', {
      'from_currency': from,
      'to_currency': to,
      'amount': amount,
      'source_account_id': sourceAccountId,
      'target_account_id': targetAccountId,
    });
  }

  // QR Payments
  Future<Map<String, dynamic>> createQRPayment({
    required int sourceAccountId,
    required String merchantName,
    required String merchantCity,
    required String merchantId,
    required String acquirerBic,
    required String mcc,
    required double amount,
    required String currency,
    required String paymentType,
    required String qrRawData,
  }) async {
    return await ApiClient.post('/qr-payments', {
      'source_account_id': sourceAccountId,
      'merchant_name': merchantName,
      'merchant_city': merchantCity,
      'merchant_id': merchantId,
      'acquirer_bic': acquirerBic,
      'mcc': mcc,
      'amount': amount,
      'currency': currency,
      'payment_type': paymentType,
      'qr_raw_data': qrRawData,
    });
  }

  Future<List<dynamic>> getQRPayments() async {
    return await ApiClient.get('/qr-payments');
  }

  // Transfers
  Future<Map<String, dynamic>> createTransfer({
    required int fromAccountId,
    required double amount,
    required String currency,
    String? reference,
    int? beneficiaryId,
  }) async {
    return await ApiClient.post('/remittance', {
      'from_account_id': fromAccountId,
      'amount': amount,
      'currency': currency,
      if (reference != null) 'reference': reference,
      if (beneficiaryId != null) 'beneficiary_id': beneficiaryId,
    });
  }

  Future<List<dynamic>> getTransferTypes() async {
    return await ApiClient.get('/transfers/types') as List<dynamic>;
  }

  // Beneficiaries
  Future<List<dynamic>> getBeneficiaries() async {
    return await ApiClient.get('/beneficiaries') as List<dynamic>;
  }

  Future<Map<String, dynamic>> createBeneficiary(Map<String, dynamic> data) async {
    return await ApiClient.post('/beneficiaries', data);
  }

  // Cards
  Future<List<dynamic>> getCards() async {
    return await ApiClient.get('/cards') as List<dynamic>;
  }

  // Profile
  Future<Map<String, dynamic>> getProfile() async {
    return await ApiClient.get('/profile');
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    return await ApiClient.put('/profile', data);
  }

  // Messages / Notifications
  Future<List<dynamic>> getMessages() async {
    return await ApiClient.get('/messages') as List<dynamic>;
  }

  Future<Map<String, dynamic>> getUnreadCount() async {
    return await ApiClient.get('/notifications/count');
  }

  // Bills — uses QR payments for PH bill QR, and transfers for biller payments
  Future<List<dynamic>> getBillers({String? category}) async {
    // Bill payments go through the transfer system
    final query = category != null ? '?category=$category' : '';
    try {
      return await ApiClient.get('/billers$query') as List<dynamic>;
    } catch (_) {
      return []; // fallback to local billers in bills_screen
    }
  }

  Future<List<dynamic>> getBillPayments({int limit = 10}) async {
    try {
      return await ApiClient.get('/bill-payments?limit=$limit') as List<dynamic>;
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> payBill({
    required int sourceAccountId,
    required String billerCode,
    required String billerName,
    required String accountNumber,
    required double amount,
    required String category,
  }) async {
    return await ApiClient.post('/bill-payments', {
      'source_account_id': sourceAccountId,
      'biller_code': billerCode,
      'biller_name': billerName,
      'account_number': accountNumber,
      'amount': amount,
      'category': category,
    });
  }

  // Nomad services
  Future<List<dynamic>> getPassportServices() async {
    return await ApiClient.get('/passport-services') as List<dynamic>;
  }

  Future<Map<String, dynamic>> submitPassportRenewal(Map<String, dynamic> data) async {
    return await ApiClient.post('/passport-renewal', data);
  }

  Future<List<dynamic>> getVisaPrograms(String nationality) async {
    return await ApiClient.get('/visa-programs?nationality=$nationality') as List<dynamic>;
  }

  Future<Map<String, dynamic>> submitVisaApplication(Map<String, dynamic> data) async {
    return await ApiClient.post('/visa-application', data);
  }

  Future<Map<String, dynamic>> getServiceStatus(String id) async {
    return await ApiClient.get('/service-status/$id');
  }

  // Rate alerts
  Future<List<dynamic>> getRateAlerts() async {
    return await ApiClient.get('/rate-alerts') as List<dynamic>;
  }

  Future<Map<String, dynamic>> createRateAlert(Map<String, dynamic> data) async {
    return await ApiClient.post('/rate-alerts', data);
  }

  // KYC
  Future<Map<String, dynamic>> getKYCStatus() async {
    return await ApiClient.get('/kyc/status');
  }

  // GoCardless Open Banking
  Future<List<dynamic>> getInstitutions(String country) async {
    return await ApiClient.get('/open-banking/institutions?country=$country') as List<dynamic>;
  }

  Future<Map<String, dynamic>> initiateOpenBankingTopUp({
    required int accountId,
    required double amount,
    required String currency,
    required String institutionId,
  }) async {
    return await ApiClient.post('/open-banking/topup', {
      'account_id': accountId,
      'amount': amount,
      'currency': currency,
      'institution_id': institutionId,
    });
  }

  Future<Map<String, dynamic>> getOpenBankingStatus(String requisitionId) async {
    return await ApiClient.get('/open-banking/status/$requisitionId');
  }

  Future<List<dynamic>> getLinkedBankAccounts() async {
    return await ApiClient.get('/open-banking/linked-accounts') as List<dynamic>;
  }
}
