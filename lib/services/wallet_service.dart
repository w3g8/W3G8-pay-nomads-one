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

  // Send money (payment invites)
  Future<Map<String, dynamic>> sendPaymentInvite({
    required int accountId,
    required double amount,
    required String currency,
    required String channel,
    required String address,
    String? name,
    String? message,
  }) async {
    return await ApiClient.post('/invites', {
      'account_id': accountId,
      'amount': amount,
      'currency': currency,
      'channel': channel,
      'address': address,
      if (name != null && name.isNotEmpty) 'name': name,
      if (message != null && message.isNotEmpty) 'message': message,
    });
  }

  Future<List<dynamic>> getPaymentInvites() async {
    return await ApiClient.get('/invites') as List<dynamic>;
  }

  // ═══════════════════════════════════════════════════════════════
  // Institution Accounts — Dual-entity model
  // One user → one master profile → two institution accounts
  // ═══════════════════════════════════════════════════════════════

  /// Get all institution accounts for the authenticated user.
  Future<Map<String, dynamic>> getInstitutionAccounts() async {
    return await ApiClient.get('/institutions/accounts');
  }

  /// Get onboarding status across all entities.
  Future<Map<String, dynamic>> getOnboardingStatus() async {
    return await ApiClient.get('/institutions/onboarding');
  }

  /// Start entity onboarding for a specific institution.
  Future<Map<String, dynamic>> startEntityOnboarding(String institutionType) async {
    return await ApiClient.post('/institutions/onboarding', {
      'institution_type': institutionType,
    });
  }

  /// Get required consents for an institution type.
  Future<Map<String, dynamic>> getEntityConsents(String institutionType) async {
    return await ApiClient.get('/institutions/consents/$institutionType');
  }

  /// Get entity-specific questions for an institution type.
  Future<Map<String, dynamic>> getEntityQuestions(String institutionType) async {
    return await ApiClient.get('/institutions/questions/$institutionType');
  }

  /// Submit entity consents.
  Future<Map<String, dynamic>> submitEntityConsents({
    required String onboardingId,
    required List<Map<String, dynamic>> consents,
  }) async {
    return await ApiClient.post('/institutions/onboarding/$onboardingId/consents', {
      'consents': consents,
    });
  }

  /// Submit entity-specific question answers.
  Future<Map<String, dynamic>> submitEntityQuestions({
    required String onboardingId,
    required Map<String, dynamic> answers,
  }) async {
    return await ApiClient.post('/institutions/onboarding/$onboardingId/questions', {
      'answers': answers,
    });
  }

  /// Get unified activity feed across all entities.
  Future<Map<String, dynamic>> getUnifiedActivity({int limit = 20}) async {
    return await ApiClient.get('/institutions/activity?limit=$limit');
  }

  /// Get the unified Nomads dashboard payload.
  Future<Map<String, dynamic>> getUnifiedDashboard() async {
    return await ApiClient.get('/dashboard/unified');
  }

  // ═══════════════════════════════════════════════════════════════
  // CASP Flow — CurrencyClear → Polish CASP/VASP wallet
  // ═══════════════════════════════════════════════════════════════

  /// Get a cost breakdown quote for a CASP flow transaction.
  Future<Map<String, dynamic>> getCASPQuote({
    required int fiatAmount,
    required String fiatCurrency,
    required String rail,
    String? cryptoAsset,
  }) async {
    final params = 'amount=$fiatAmount&currency=$fiatCurrency&rail=$rail'
        '${cryptoAsset != null ? '&asset=$cryptoAsset' : ''}';
    return await ApiClient.get('/casp/quote?$params');
  }

  /// Create a customer-authorized fiat send instruction.
  Future<Map<String, dynamic>> createCASPInstruction({
    required int fiatAmount,
    required String fiatCurrency,
    required String rail,
    String? cryptoAsset,
    String? gcRequisitionId,
    String? gcAccountId,
  }) async {
    return await ApiClient.post('/casp/instructions', {
      'fiat_amount': fiatAmount,
      'fiat_currency': fiatCurrency,
      'rail': rail,
      if (cryptoAsset != null) 'crypto_asset': cryptoAsset,
      if (gcRequisitionId != null) 'gc_requisition_id': gcRequisitionId,
      if (gcAccountId != null) 'gc_account_id': gcAccountId,
    });
  }

  /// Get a single CASP instruction by ID.
  Future<Map<String, dynamic>> getCASPInstruction(String id) async {
    return await ApiClient.get('/casp/instructions/$id');
  }

  /// List all CASP instructions for the authenticated user.
  Future<Map<String, dynamic>> listCASPInstructions({int limit = 20, int offset = 0}) async {
    return await ApiClient.get('/casp/instructions?limit=$limit&offset=$offset');
  }

  /// Create a customer-authorized fiat→stablecoin conversion.
  Future<Map<String, dynamic>> createCASPConversion({
    required String instructionId,
    required String cryptoAsset,
    required String walletAddress,
    double? expectedRate,
  }) async {
    return await ApiClient.post('/casp/instructions/$instructionId/convert', {
      'crypto_asset': cryptoAsset,
      'wallet_address': walletAddress,
      if (expectedRate != null) 'expected_rate': expectedRate,
    });
  }

  /// Get a conversion by ID.
  Future<Map<String, dynamic>> getCASPConversion(String id) async {
    return await ApiClient.get('/casp/conversions/$id');
  }

  /// Get the ledger event history for an instruction.
  Future<Map<String, dynamic>> getCASPEvents(String instructionId) async {
    return await ApiClient.get('/casp/instructions/$instructionId/events');
  }

  /// Get the exportable receipt for an instruction.
  Future<Map<String, dynamic>> getCASPReceipt(String instructionId) async {
    return await ApiClient.get('/casp/instructions/$instructionId/receipt');
  }

  /// Initiate card payment for a CASP instruction (CurrencyClear MCC 6012).
  Future<Map<String, dynamic>> initiateCASPCardPayment(String instructionId) async {
    return await ApiClient.post('/casp/instructions/$instructionId/pay/card', {});
  }

  /// Initiate Open Banking payment for a CASP instruction (CurrencyClear PIS).
  Future<Map<String, dynamic>> initiateCASPBankPayment({
    required String instructionId,
    required String institutionId,
    String? paymentScheme,
  }) async {
    return await ApiClient.post('/casp/instructions/$instructionId/pay/bank', {
      'institution_id': institutionId,
      if (paymentScheme != null) 'payment_scheme': paymentScheme,
    });
  }

  /// Get supported banks from CurrencyClear for Open Banking.
  Future<List<dynamic>> getCASPInstitutions(String country) async {
    final result = await ApiClient.get('/casp/institutions?country=$country');
    return result['institutions'] as List<dynamic>;
  }

  /// Get Nigerian banks for payout.
  Future<List<dynamic>> getNigerianBanks() async {
    final result = await ApiClient.get('/payout/banks/NG');
    return result['banks'] as List<dynamic>;
  }

  /// Create a Flutterwave payout to Nigerian bank.
  Future<Map<String, dynamic>> createNigerianPayout({
    required int sourceAccountId,
    required double amount,
    required String beneficiaryName,
    required String beneficiaryAccount,
    required String beneficiaryBank,
  }) async {
    return await ApiClient.post('/payout/flutterwave', {
      'source_account_id': sourceAccountId,
      'amount': amount,
      'currency': 'NGN',
      'beneficiary_name': beneficiaryName,
      'beneficiary_account': beneficiaryAccount,
      'beneficiary_bank': beneficiaryBank,
      'country_code': 'NG',
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // Merchant Checkout — Payment-led merchant acquisition
  // Guest → Claimed → Active merchant states
  // ═══════════════════════════════════════════════════════════════

  /// Create a provisional (guest) merchant — no auth required.
  /// Only needs: business_name, website_or_facebook, mobile (optional).
  Future<Map<String, dynamic>> createProvisionalMerchant({
    required String businessName,
    String? websiteOrFacebook,
    String? mobile,
    String? deviceFingerprint,
  }) async {
    return await ApiClient.post('/merchant/provisional', {
      'business_name': businessName,
      if (websiteOrFacebook != null) 'website_or_facebook': websiteOrFacebook,
      if (mobile != null) 'mobile': mobile,
      if (deviceFingerprint != null) 'device_fingerprint': deviceFingerprint,
    });
  }

  /// Create a checkout for a merchant — returns QR payload and checkout ID.
  Future<Map<String, dynamic>> createMerchantCheckout({
    required String provisionalMerchantId,
    required double amount,
    required String currency,
    String? note,
  }) async {
    return await ApiClient.post('/checkout/create', {
      'provisional_merchant_id': provisionalMerchantId,
      'amount': amount,
      'currency': currency,
      if (note != null) 'note': note,
    });
  }

  /// Get checkout status (pending/paid/expired).
  Future<Map<String, dynamic>> getMerchantCheckoutStatus(String checkoutId) async {
    return await ApiClient.get('/checkout/$checkoutId');
  }

  /// Tourist pays a merchant checkout from their wallet.
  Future<Map<String, dynamic>> payMerchantCheckout({
    required String checkoutId,
    required int sourceAccountId,
  }) async {
    return await ApiClient.post('/checkout/$checkoutId/pay', {
      'source_account_id': sourceAccountId,
    });
  }

  /// Merchant claims their provisional profile (phone OTP verification).
  Future<Map<String, dynamic>> claimMerchant({
    required String provisionalMerchantId,
    required String mobile,
    required String otpCode,
    String? email,
  }) async {
    return await ApiClient.post('/merchant/claim', {
      'provisional_merchant_id': provisionalMerchantId,
      'mobile': mobile,
      'otp_code': otpCode,
      if (email != null) 'email': email,
    });
  }

  /// Submit full merchant onboarding details (legal entity, owner ID, etc.).
  Future<Map<String, dynamic>> completeMerchantOnboarding({
    required String merchantId,
    required Map<String, dynamic> details,
  }) async {
    return await ApiClient.post('/merchant/complete', {
      'merchant_id': merchantId,
      ...details,
    });
  }

  /// Get merchant balance (pending + available).
  Future<Map<String, dynamic>> getMerchantBalance(String merchantId) async {
    return await ApiClient.get('/merchant/$merchantId/balance');
  }

  /// Get merchant transaction history.
  Future<List<dynamic>> getMerchantTransactions(String merchantId, {int limit = 20}) async {
    return await ApiClient.get('/merchant/$merchantId/transactions?limit=$limit') as List<dynamic>;
  }

  // Card top-up via checkout (CircoFlows/VisionFlow)
  Future<Map<String, dynamic>> createCheckoutSession({
    required int accountId,
    required double amount,
    required String currency,
  }) async {
    return await ApiClient.post('/checkout/card-topup', {
      'account_id': accountId,
      'amount': amount,
      'currency': currency,
      'return_url': 'https://pay.nomads.one/topup/complete',
    });
  }

  Future<Map<String, dynamic>> getCheckoutStatus(String sessionId) async {
    return await ApiClient.get('/checkout/status/$sessionId');
  }
}
