class PaymentModel {
  Strip? strip;
  Paypal? paypal;
  Razorpay? razorpay;
  PayStack? payStack;
  MercadoPago? mercadoPago;
  PayFast? payFast;
  FlutterWave? flutterWave;
  Midtrans? midtrans;
  Xendit? xendit;

  PaymentModel({
    this.strip,
    this.paypal,
    this.razorpay,
    this.payStack,
    this.mercadoPago,
    this.midtrans,
    this.xendit,
  });

  PaymentModel.fromJson(Map<String, dynamic> json) {
    strip = json['strip'] != null ? Strip.fromJson(json['strip']) : null;
    paypal = json['paypal'] != null ? Paypal.fromJson(json['paypal']) : null;
    razorpay = json['razorpay'] != null ? Razorpay.fromJson(json['razorpay']) : null;
    payStack = json['payStack'] != null ? PayStack.fromJson(json['payStack']) : null;
    mercadoPago = json['mercadoPago'] != null ? MercadoPago.fromJson(json['mercadoPago']) : null;
    payFast = json['payFast'] != null ? PayFast.fromJson(json['payFast']) : null;
    flutterWave = json['flutterWave'] != null ? FlutterWave.fromJson(json['flutterWave']) : null;
    midtrans = json['midtrans'] != null ? Midtrans.fromJson(json['midtrans']) : null;
    xendit = json['xendit'] != null ? Xendit.fromJson(json['xendit']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (strip != null) {
      data['strip'] = strip!.toJson();
    }
    if (paypal != null) {
      data['paypal'] = paypal!.toJson();
    }
    if (razorpay != null) {
      data['razorpay'] = razorpay!.toJson();
    }
    if (payStack != null) {
      data['payStack'] = payStack!.toJson();
    }
    if (mercadoPago != null) {
      data['mercadoPago'] = mercadoPago!.toJson();
    }
    if (payFast != null) {
      data['payFast'] = payFast!.toJson();
    }
    if (flutterWave != null) {
      data['flutterWave'] = flutterWave!.toJson();
    }
    if (midtrans != null) {
      data['midtrans'] = midtrans!.toJson();
    }
    if (xendit != null) {
      data['xendit'] = xendit!.toJson();
    }
    return data;
  }
}

class Midtrans {
  bool? isActive;
  String? name;
  String? midtransClientKey;
  String? midtransSecretKey;
  String? midtransId;
  String? callbackUrl;
  bool? isSandbox;

  Midtrans({this.name, this.isActive, this.isSandbox, this.midtransClientKey, this.midtransSecretKey, this.midtransId, this.callbackUrl});

  Midtrans.fromJson(Map<String, dynamic> json) {
    isActive = json['isActive'];
    name = json['name'];
    midtransClientKey = json['midtransClientKey'];
    midtransSecretKey = json['midtransSecretKey'];
    midtransId = json['midtransId'];
    callbackUrl = json['callbackUrl'];
    isSandbox = json['isSandbox'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    data['isActive'] = isActive;
    data['name'] = name;
    data['isSandbox'] = isSandbox;
    data['midtransClientKey'] = midtransClientKey;
    data['midtransSecretKey'] = midtransSecretKey;
    data['midtransId'] = midtransId;
    data['callbackUrl'] = callbackUrl;
    return data;
  }
}

class Xendit {
  bool? isActive;
  String? name;
  String? xenditSecretKey;
  String? callbackUrl;
  bool? isSandbox;

  Xendit({this.name, this.isActive, this.isSandbox, this.xenditSecretKey, this.callbackUrl});

  Xendit.fromJson(Map<String, dynamic> json) {
    isActive = json['isActive'];
    name = json['name'];
    xenditSecretKey = json['xenditSecretKey'];
    callbackUrl = json['callbackUrl'];
    isSandbox = json['isSandbox'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    data['isActive'] = isActive;
    data['name'] = name;
    data['isSandbox'] = isSandbox;
    data['xenditSecretKey'] = xenditSecretKey;
    data['callbackUrl'] = callbackUrl;
    return data;
  }
}

class Razorpay {
  bool? isActive;
  String? name;
  String? razorpayKey;
  String? razorpaySecret;
  bool? isSandbox;
  String? callbackUrl;

  Razorpay({
    this.name,
    this.isActive,
    this.isSandbox,
    this.razorpayKey,
    this.razorpaySecret,
    this.callbackUrl,
  });

  Razorpay.fromJson(Map<String, dynamic> json) {
    isActive = json['isActive'];
    name = json['name'];
    razorpayKey = json['razorpayKey'];
    razorpaySecret = json['razorpaySecret'];
    isSandbox = json['isSandbox'];
    callbackUrl = json['callbackUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    data['isActive'] = isActive;
    data['name'] = name;
    data['isSandbox'] = isSandbox;
    data['razorpayKey'] = razorpayKey;
    data['razorpaySecret'] = razorpaySecret;
    data['callbackUrl'] = callbackUrl;
    return data;
  }
}

class Strip {
  String? clientPublishableKey;
  String? stripeSecret;
  bool? isActive;
  String? name;
  String? callbackUrl;
  bool? isSandbox;

  Strip({
    this.clientPublishableKey,
    this.stripeSecret,
    this.isActive,
    this.name,
    this.callbackUrl,
    this.isSandbox,
  });

  Strip.fromJson(Map<String, dynamic> json) {
    clientPublishableKey = json['clientpublishableKey'];
    stripeSecret = json['stripeSecret'];
    isActive = json['isActive'];
    name = json['name'];
    callbackUrl = json['callbackUrl'];
    isSandbox = json['isSandbox'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['clientpublishableKey'] = clientPublishableKey;
    data['stripeSecret'] = stripeSecret;
    data['isActive'] = isActive;
    data['name'] = name;
    data['callbackUrl'] = callbackUrl;
    data['isSandbox'] = isSandbox;
    return data;
  }
}

class PayStack {
  String? payStackSecret;
  String? callBackUrl;
  bool? isActive;
  String? name;

  @override
  String toString() {
    return 'PayStack{payStackSecret: $payStackSecret, isActive: $isActive, name: $name,}';
  }

  PayStack({this.payStackSecret, this.isActive, this.name, this.callBackUrl});

  PayStack.fromJson(Map<String, dynamic> json) {
    payStackSecret = json['payStackSecret'];
    isActive = json['isActive'];
    name = json['name'];
    callBackUrl = json['callBackUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['payStackSecret'] = payStackSecret;
    data['isActive'] = isActive;
    data['name'] = name;
    data['callBackUrl'] = callBackUrl;
    return data;
  }
}

class MercadoPago {
  bool? isActive;
  String? name;
  String? mercadoPagoAccessToken;
  String? callBackUrl;

  MercadoPago({this.name, this.isActive, this.mercadoPagoAccessToken, this.callBackUrl});

  @override
  String toString() {
    return 'MercadoPago{isActive: $isActive, name: $name, mercadoPagoAccessToken: $mercadoPagoAccessToken,}';
  }

  MercadoPago.fromJson(Map<String, dynamic> json) {
    isActive = json['isActive'];
    name = json['name'];
    mercadoPagoAccessToken = json['mercadoPagoAccessToken'];
    callBackUrl = json['callBackUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    data['isActive'] = isActive;
    data['name'] = name;
    data['mercadoPagoAccessToken'] = mercadoPagoAccessToken;
    data['callBackUrl'] = callBackUrl;
    return data;
  }
}

class PayFast {
  String? merchantId;
  bool? isActive;
  String? name;
  String? returnUrl;
  String? notifyUrl;
  bool? isSandbox;
  String? cancelUrl;
  String? merchantKey;
  String? callBackUrl;

  PayFast({this.merchantId, this.isActive, this.name, this.returnUrl, this.notifyUrl, this.isSandbox, this.cancelUrl, this.merchantKey, this.callBackUrl});

  PayFast.fromJson(Map<String, dynamic> json) {
    merchantId = json['merchantId'];
    isActive = json['isActive'];
    name = json['name'];
    returnUrl = json['return_url'];
    notifyUrl = json['notify_url'];
    isSandbox = json['isSandbox'];
    cancelUrl = json['cancel_url'];
    merchantKey = json['merchantKey'];
    callBackUrl = json['callBackUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['merchantId'] = merchantId;
    data['isActive'] = isActive;
    data['name'] = name;
    data['return_url'] = returnUrl;
    data['notify_url'] = notifyUrl;
    data['isSandbox'] = isSandbox;
    data['cancel_url'] = cancelUrl;
    data['merchantKey'] = merchantKey;
    data['callBackUrl'] = callBackUrl;
    return data;
  }
}

class FlutterWave {
  bool? isActive;
  String? name;
  String? publicKey;
  String? secretKey;
  String? callBackUrl;
  bool? isSandBox;

  FlutterWave({this.name, this.isActive, this.publicKey, this.secretKey, this.isSandBox, this.callBackUrl});

  @override
  String toString() {
    return 'FlutterWave{isActive: $isActive, name: $name, publicKey: $publicKey, secretKey: $secretKey, isSandBox: $isSandBox}';
  }

  FlutterWave.fromJson(Map<String, dynamic> json) {
    isActive = json['isActive'];
    name = json['name'];
    publicKey = json['publicKey'];
    secretKey = json['secretKey'];
    isSandBox = json['isSandBox'];
    callBackUrl = json['callBackUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    data['isActive'] = isActive;
    data['name'] = name;
    data['publicKey'] = publicKey;
    data['secretKey'] = secretKey;
    data['isSandBox'] = isSandBox;
    data['callBackUrl'] = callBackUrl;
    return data;
  }
}

class Paypal {
  bool? isActive;
  String? name;
  String? paypalSecret;
  String? paypalClient;
  String? callbackUrl;
  bool? isSandbox;

  Paypal({
    this.name,
    this.isActive,
    this.paypalSecret,
    this.isSandbox,
    this.paypalClient,
    this.callbackUrl,
  });

  @override
  String toString() {
    return 'Paypal{isActive: $isActive, name: $name, paypalSecret: $paypalSecret, paypalClient: $paypalClient, isSandbox: $isSandbox,callbackUrl: $callbackUrl}';
  }

  Paypal.fromJson(Map<String, dynamic> json) {
    isActive = json['isActive'];
    name = json['name'];
    paypalSecret = json['paypalSecret'];
    paypalClient = json['paypalClient'];
    callbackUrl = json['callbackUrl'];
    isSandbox = json['isSandbox'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    data['isActive'] = isActive;
    data['name'] = name;
    data['paypalSecret'] = paypalSecret;
    data['isSandbox'] = isSandbox;
    data['paypalClient'] = paypalClient;
    data['callbackUrl'] = callbackUrl;
    return data;
  }
}
