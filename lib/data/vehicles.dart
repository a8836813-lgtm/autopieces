enum VehicleType { car, truck }

class VehicleBrand {
  final String id;
  final String name;
  final VehicleType type;
  final List<String> models;

  const VehicleBrand(this.id, this.name, this.type, this.models);

  /// Put the official logo here: `assets/brands/<id>.png`
  /// If the file is missing, the app shows the brand initials instead.
  String get logoAsset => 'assets/brands/$id.png';

  String get initials {
    final parts = name.split(RegExp(r'[\s\-]+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters;
  }
}

/// Starter catalog. Extend or replace with data from the backend later.
const List<VehicleBrand> kCarBrands = [
  VehicleBrand('renault', 'Renault', VehicleType.car,
      ['Clio', 'Symbol', 'Megane', 'Captur', 'Kangoo', 'Talisman', 'Trafic']),
  VehicleBrand('peugeot', 'Peugeot', VehicleType.car,
      ['208', '301', '308', '2008', '3008', '508', 'Partner', 'Expert']),
  VehicleBrand('citroen', 'Citroën', VehicleType.car,
      ['C3', 'C4', 'C-Elysée', 'C5 Aircross', 'Berlingo', 'Jumpy']),
  VehicleBrand('dacia', 'Dacia', VehicleType.car,
      ['Logan', 'Sandero', 'Duster', 'Dokker', 'Lodgy']),
  VehicleBrand('volkswagen', 'Volkswagen', VehicleType.car,
      ['Golf 5', 'Golf 6', 'Golf 7', 'Golf 8', 'Polo', 'Passat', 'Tiguan', 'Caddy', 'Jetta']),
  VehicleBrand('hyundai', 'Hyundai', VehicleType.car,
      ['i10', 'i20', 'Accent', 'Elantra', 'Tucson', 'Santa Fe', 'Creta']),
  VehicleBrand('kia', 'Kia', VehicleType.car,
      ['Picanto', 'Rio', 'Cerato', 'Sportage', 'Sorento', 'Seltos']),
  VehicleBrand('toyota', 'Toyota', VehicleType.car,
      ['Yaris', 'Corolla', 'Auris', 'Camry', 'RAV4', 'Hilux', 'Land Cruiser']),
  VehicleBrand('fiat', 'Fiat', VehicleType.car,
      ['Panda', '500', 'Punto', 'Tipo', 'Doblo', 'Ducato']),
  VehicleBrand('skoda', 'Skoda', VehicleType.car,
      ['Fabia', 'Rapid', 'Octavia', 'Superb', 'Kodiaq']),
  VehicleBrand('seat', 'Seat', VehicleType.car,
      ['Ibiza', 'Leon', 'Arona', 'Ateca']),
  VehicleBrand('chery', 'Chery', VehicleType.car,
      ['QQ', 'Tiggo 2', 'Tiggo 4', 'Tiggo 7', 'Arrizo 5']),
  VehicleBrand('geely', 'Geely', VehicleType.car,
      ['Emgrand', 'Coolray', 'GX3 Pro']),
  VehicleBrand('suzuki', 'Suzuki', VehicleType.car,
      ['Swift', 'Celerio', 'Dzire', 'Vitara', 'Jimny']),
  VehicleBrand('nissan', 'Nissan', VehicleType.car,
      ['Micra', 'Sunny', 'Juke', 'Qashqai', 'X-Trail', 'Navara']),
  VehicleBrand('ford', 'Ford', VehicleType.car,
      ['Fiesta', 'Focus', 'Kuga', 'Transit', 'Ranger']),
  VehicleBrand('mercedes', 'Mercedes-Benz', VehicleType.car,
      ['A-Class', 'C-Class', 'E-Class', 'GLC', 'Vito', 'Sprinter']),
  VehicleBrand('bmw', 'BMW', VehicleType.car,
      ['Series 1', 'Series 3', 'Series 5', 'X1', 'X3', 'X5']),
  VehicleBrand('audi', 'Audi', VehicleType.car,
      ['A3', 'A4', 'A6', 'Q3', 'Q5', 'RS3']),
  VehicleBrand('opel', 'Opel', VehicleType.car,
      ['Corsa', 'Astra', 'Insignia', 'Mokka']),
  VehicleBrand('honda', 'Honda', VehicleType.car,
      ['Jazz', 'Civic', 'Accord', 'CR-V']),
  VehicleBrand('mazda', 'Mazda', VehicleType.car,
      ['Mazda2', 'Mazda3', 'CX-5', 'BT-50']),
  VehicleBrand('mitsubishi', 'Mitsubishi', VehicleType.car,
      ['Lancer', 'ASX', 'Pajero', 'L200']),
];

const List<VehicleBrand> kTruckBrands = [
  VehicleBrand('mercedes_trucks', 'Mercedes-Benz Trucks', VehicleType.truck,
      ['Actros', 'Arocs', 'Atego', 'Axor', 'Antos']),
  VehicleBrand('volvo_trucks', 'Volvo Trucks', VehicleType.truck,
      ['FH', 'FM', 'FMX', 'FL']),
  VehicleBrand('renault_trucks', 'Renault Trucks', VehicleType.truck,
      ['T', 'C', 'K', 'D', 'Midlum', 'Premium']),
  VehicleBrand('scania', 'Scania', VehicleType.truck,
      ['R series', 'S series', 'G series', 'P series']),
  VehicleBrand('man', 'MAN', VehicleType.truck,
      ['TGX', 'TGS', 'TGM', 'TGL']),
  VehicleBrand('iveco', 'Iveco', VehicleType.truck,
      ['Daily', 'Eurocargo', 'Stralis', 'Trakker']),
  VehicleBrand('daf', 'DAF', VehicleType.truck, ['XF', 'CF', 'LF']),
  VehicleBrand('isuzu', 'Isuzu', VehicleType.truck,
      ['NKR', 'NPR', 'NQR', 'FVR']),
  VehicleBrand('hyundai_trucks', 'Hyundai Trucks', VehicleType.truck,
      ['Porter', 'Mighty', 'HD65', 'HD78']),
  VehicleBrand('fuso', 'Mitsubishi Fuso', VehicleType.truck,
      ['Canter', 'Fighter']),
  VehicleBrand('hino', 'Hino', VehicleType.truck, ['300', '500', '700']),
  VehicleBrand('shacman', 'Shacman', VehicleType.truck,
      ['F3000', 'M3000', 'X3000']),
  VehicleBrand('faw', 'FAW', VehicleType.truck, ['J6', 'Tiger V']),
  VehicleBrand('foton', 'Foton', VehicleType.truck, ['Aumark', 'Auman']),
  VehicleBrand('jac', 'JAC', VehicleType.truck, ['N56', 'N75', 'X200']),
];

List<VehicleBrand> brandsFor(VehicleType type) =>
    type == VehicleType.car ? kCarBrands : kTruckBrands;
