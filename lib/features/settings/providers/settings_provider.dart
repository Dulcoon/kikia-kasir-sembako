import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/helpers/preferences_helper.dart';

class SettingsState {
  final String storeName;
  final String storeAddress;
  final String storePhone;
  final bool isLoading;

  SettingsState({
    this.storeName = 'Warung Sembako',
    this.storeAddress = 'Alamat Toko',
    this.storePhone = '-',
    this.isLoading = true,
  });

  SettingsState copyWith({
    String? storeName,
    String? storeAddress,
    String? storePhone,
    bool? isLoading,
  }) {
    return SettingsState(
      storeName: storeName ?? this.storeName,
      storeAddress: storeAddress ?? this.storeAddress,
      storePhone: storePhone ?? this.storePhone,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final name = await PreferencesHelper.getStoreName();
    final address = await PreferencesHelper.getStoreAddress();
    final phone = await PreferencesHelper.getStorePhone();

    state = state.copyWith(
      storeName: name,
      storeAddress: address,
      storePhone: phone,
      isLoading: false,
    );
  }

  Future<void> saveSettings({
    required String name,
    required String address,
    required String phone,
  }) async {
    await PreferencesHelper.setStoreName(name);
    await PreferencesHelper.setStoreAddress(address);
    await PreferencesHelper.setStorePhone(phone);

    state = state.copyWith(
      storeName: name,
      storeAddress: address,
      storePhone: phone,
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    return SettingsNotifier();
  },
);
