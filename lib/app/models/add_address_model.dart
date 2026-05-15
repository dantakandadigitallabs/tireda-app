import 'package:eSellify/app/models/location_lat_lng.dart';

class AddAddressModel {
  bool? isDefault;
  String? address;
  String? name;
  String? addressAs;
  String? id;
  String? locality;
  String? landmark;
  LocationLatLng? location;

  AddAddressModel({
    this.isDefault,
    this.address,
    this.addressAs,
    this.id,
    this.locality,
    this.location,
    this.name,
    this.landmark,
  });

  String getFullAddress() {
    return '${address == null || address!.isEmpty ? "" : address} $locality ${landmark == null || landmark!.isEmpty ? "" : landmark.toString()}';
  }

  @override
  String toString() {
    return 'AddAddressModel{isDefault: $isDefault, address: $address, name: $name, addressAs: $addressAs, id: $id, locality: $locality, landmark: $landmark, location: $location}';
  }

  AddAddressModel.fromJson(Map<String, dynamic> json) {
    isDefault = json['isDefault'];
    address = json['address'] ?? "";
    name = json['name'] ?? "";
    addressAs = json['addressAs'];
    id = json['id'];
    locality = json['locality'] ?? "";
    landmark = json['landmark'] ?? "";
    location = json['location'] != null ? LocationLatLng.fromJson(json['location']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['isDefault'] = isDefault;
    data['address'] = address;
    data['name'] = name;
    data['addressAs'] = addressAs;
    data['id'] = id;
    data['locality'] = locality;
    data['landmark'] = landmark;
    if (location != null) {
      data['location'] = location!.toJson();
    }
    return data;
  }
}