-- Demo data for AutoPièces. Import AFTER schema.sql (phpMyAdmin > autopieces > Import).
-- Demo accounts (password for all three: demo1234):
--   client@demo.dz   (client)     mechanic@demo.dz (mechanic: Garage El Amel)     shop@demo.dz (shop: Pièces Auto Demo)
USE autopieces;

INSERT INTO users (id, role, name, email, phone, password_hash, profile_json) VALUES
  (1, 'client',   'Demo Client',   'client@demo.dz',   '0550000001', '$2y$10$TdktTcJUvs35Q7SATCZFzeb/RyarrRqgZ..p1gos62DMgJCTbe8fe', '{"wilaya":"Jijel"}'),
  (2, 'mechanic', 'Demo Mechanic', 'mechanic@demo.dz', '0660000002', '$2y$10$TdktTcJUvs35Q7SATCZFzeb/RyarrRqgZ..p1gos62DMgJCTbe8fe', '{"garage":"Garage El Amel","specialty":"General mechanics","wilaya":"Jijel","experience":"8"}'),
  (3, 'shop',     'Demo Owner',    'shop@demo.dz',     '0770000003', '$2y$10$TdktTcJUvs35Q7SATCZFzeb/RyarrRqgZ..p1gos62DMgJCTbe8fe', '{"shopName":"Pièces Auto Demo","shopType":"Retail shop","address":"Centre ville, Jijel","wilaya":"Jijel"}');

INSERT INTO shops (id, owner_id, name, type, address, phone, hours, about, open_now, lat, lng) VALUES
  (1, 3,    'Pièces Auto Demo', 'Retail shop', 'Centre ville, Jijel', '0770000003', 'Open until 19:00', 'Brake parts, filters and batteries for most cars.', 1, 36.8200, 5.7667),
  (2, NULL, 'Auto Parts Kaous', 'Retail shop', 'Kaous, Jijel',        '0771111111', 'Open until 18:00', 'Spare parts for French and Korean cars.',       1, 36.8030, 5.8050),
  (3, NULL, 'Casse Auto El Milia', 'Used parts', 'El Milia',          '0772222222', 'Open until 17:00', 'Used and refurbished parts.',                    0, 36.7510, 6.2630);

UPDATE shops SET payments = 'Cash, CIB card' WHERE id = 1;

INSERT INTO parts (id, name, oem, category, fits, alt_serials) VALUES
  (1, 'Front brake pads',  '04465-02220', 'Brakes',  'Toyota, Renault Clio',      'GDB1330,FDB1573'),
  (2, 'Oil filter',        '90915-YZZE1', 'Filters', 'Most petrol cars',          'W712/75,OC196'),
  (3, 'Car battery 60Ah',  'BAT-60-L2',   'Battery', 'Universal',                 ''),
  (4, 'Air filter',        '17801-0D020', 'Filters', 'Toyota Yaris, Corolla',     'A1234'),
  (5, 'Spark plug set',    'NGK-BKR6E',   'Engine',  'Petrol 4 cylinders',        '');

INSERT INTO stock (shop_id, part_id, price, quantity, part_condition) VALUES
  (1, 1, 6500, 6, 'New'), (1, 2, 1200, 14, 'New'), (1, 3, 14500, 3, 'New'), (1, 4, 1800, 0, 'New'),
  (2, 1, 6900, 4, 'New'), (2, 2, 1100, 9, 'New'),  (2, 5, 2400, 12, 'New'),
  (3, 1, 3500, 2, 'Used'), (3, 3, 8000, 1, 'Used');

INSERT INTO mechanics (id, owner_id, name, specialties, years_experience, address, phone, hours, about, response_time, mobile_service, premium, verified, available, lat, lng) VALUES
  (1, 2,    'Garage El Amel',   'General mechanics, Brakes, Diagnostics', 8,  'Rue de la gare, Jijel', '0660000002', 'Sat-Thu 8:00-18:00', 'Family garage, honest quotes, all makes.', 'Replies within an hour', 1, 0, 1, 1, 36.8190, 5.7640),
  (2, NULL, 'Atelier Rachid',   'Electrical, Air conditioning',           12, 'Kaous, Jijel',          '0661111111', 'Sat-Thu 9:00-17:00', 'Car electrics and A/C specialist.',       'Replies within a day',  0, 1, 1, 1, 36.8040, 5.8040),
  (3, NULL, 'Garage Les Amis',  'Engine, Gearbox',                         5,  'El Aouana',             '0662222222', 'Sat-Wed 8:00-17:00', 'Engine overhaul and gearbox repair.',     'Replies within a day',  0, 0, 0, 1, 36.7800, 5.6900);

INSERT INTO mechanic_services (mechanic_id, name, price_from) VALUES
  (1, 'Oil change', 2500), (1, 'Brake pads replacement', 4000), (1, 'Full diagnostic', 3000),
  (2, 'A/C recharge', 5000), (2, 'Alternator repair', 7000),
  (3, 'Timing belt replacement', 12000), (3, 'Clutch replacement', 18000);

INSERT INTO mechanic_reports (mechanic_id, car, category, title, problem, diagnosis, work_done, parts_text, cost, labour_cost, parts_cost, duration_hours, warranty_months, created_at) VALUES
  (1, 'Renault Clio 4 (2017)', 'Brakes', 'Squealing brakes and soft pedal',
      'High-pitched noise when braking, pedal goes low.', 'Front pads worn to the metal, discs scored.',
      'Replaced pads and both front discs, bled the brake fluid.', 'Front brake pads, front discs', 14500, 4000, 10500, 2.5, 6, '2026-11-10 10:00:00'),
  (2, 'Dacia Logan (2015)', 'Electrical', 'Car will not start on cold mornings',
      'Slow crank, dashboard lights dim.', 'Weak battery and loose earth cable.', 'New battery and cleaned the earth connection.', 'Battery 60Ah', 16000, 1500, 14500, 1, 12, '2026-11-12 14:00:00');

INSERT INTO reviews (target_kind, target_id, author_id, author_name, stars, comment, created_at) VALUES
  ('shop', 1, 1, 'Demo Client', 5, 'Had the pads in stock, fair price.', '2026-11-05 12:00:00');
