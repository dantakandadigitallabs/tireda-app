class PaymentModel {
  PayStack? payStack;
  FlutterWave? flutterWave;

  PaymentModel({

    this.payStack,
    this.flutterWave,
  });

  PaymentModel.fromJson(Map<String, dynamic> json) {
    payStack = json['payStack'] != null ? PayStack.fromJson(json['payStack']) : null;
    flutterWave = json['flutterWave'] != null ? FlutterWave.fromJson(json['flutterWave']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (payStack != null) {
      data['payStack'] = payStack!.toJson();
    }
    if (flutterWave != null) {
      data['flutterWave'] = flutterWave!.toJson();
    }

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

