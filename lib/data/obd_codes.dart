/// A few common OBD-II trouble codes for the diagnostic helper.
///
/// This is a small rule-based demo list, not a real scan tool: a code only
/// points to likely causes, the mechanic still has to confirm on the car.
class ObdCode {
  final String code;
  final String title;

  /// 'Low', 'Medium' or 'High'.
  final String severity;
  final List<String> causes;
  final String firstCheck;

  const ObdCode({
    required this.code,
    required this.title,
    required this.severity,
    required this.causes,
    required this.firstCheck,
  });
}

const List<ObdCode> kObdCodes = [
  ObdCode(
    code: 'P0016',
    title: 'Crankshaft and camshaft position do not match',
    severity: 'High',
    causes: [
      'Stretched timing chain or belt jumped a tooth',
      'Faulty camshaft or crankshaft sensor',
      'Oil control valve or low oil pressure',
    ],
    firstCheck: 'Check engine oil level, then inspect timing chain or belt.',
  ),
  ObdCode(
    code: 'P0087',
    title: 'Fuel rail pressure too low',
    severity: 'High',
    causes: [
      'Clogged fuel filter',
      'Weak high-pressure fuel pump',
      'Leaking injector or pressure regulator',
    ],
    firstCheck: 'Replace the fuel filter and measure rail pressure.',
  ),
  ObdCode(
    code: 'P0101',
    title: 'Air flow sensor reading out of range',
    severity: 'Medium',
    causes: [
      'Dirty mass air flow sensor',
      'Air leak after the sensor',
      'Clogged air filter',
    ],
    firstCheck: 'Clean the air flow sensor and check the intake hoses.',
  ),
  ObdCode(
    code: 'P0113',
    title: 'Intake air temperature sensor, high input',
    severity: 'Low',
    causes: ['Faulty sensor', 'Open circuit or loose connector'],
    firstCheck: 'Check the sensor connector and wiring.',
  ),
  ObdCode(
    code: 'P0116',
    title: 'Coolant temperature reading not plausible',
    severity: 'Medium',
    causes: [
      'Thermostat stuck open',
      'Faulty coolant temperature sensor',
      'Low coolant',
    ],
    firstCheck: 'Check coolant level and thermostat opening temperature.',
  ),
  ObdCode(
    code: 'P0171',
    title: 'Fuel mixture too lean (bank 1)',
    severity: 'Medium',
    causes: [
      'Vacuum or intake air leak',
      'Dirty air flow sensor',
      'Weak fuel pump or clogged injectors',
    ],
    firstCheck: 'Smoke-test the intake for leaks, then check fuel pressure.',
  ),
  ObdCode(
    code: 'P0172',
    title: 'Fuel mixture too rich (bank 1)',
    severity: 'Medium',
    causes: [
      'Leaking injector',
      'Faulty oxygen sensor',
      'Dirty air filter or air flow sensor',
    ],
    firstCheck: 'Check the air filter and oxygen sensor readings.',
  ),
  ObdCode(
    code: 'P0217',
    title: 'Engine over-temperature',
    severity: 'High',
    causes: [
      'Low coolant or leak',
      'Faulty water pump or thermostat',
      'Cooling fan not working',
    ],
    firstCheck: 'Stop driving. Check coolant, fan and thermostat when cold.',
  ),
  ObdCode(
    code: 'P0299',
    title: 'Turbocharger underboost',
    severity: 'High',
    causes: [
      'Boost leak at a hose or intercooler',
      'Stuck wastegate or variable geometry actuator',
      'Worn turbo',
    ],
    firstCheck: 'Pressure-test the boost pipes and check the actuator.',
  ),
  ObdCode(
    code: 'P0300',
    title: 'Random misfire detected',
    severity: 'High',
    causes: [
      'Worn spark plugs or ignition coils',
      'Vacuum leak',
      'Low fuel pressure',
    ],
    firstCheck: 'Inspect spark plugs and coils, then check for air leaks.',
  ),
  ObdCode(
    code: 'P0301',
    title: 'Cylinder 1 misfire (P0302 to P0304 are cylinders 2 to 4)',
    severity: 'High',
    causes: [
      'Bad spark plug or coil on that cylinder',
      'Clogged or leaking injector',
      'Low compression',
    ],
    firstCheck: 'Swap the coil with another cylinder and see if the code follows.',
  ),
  ObdCode(
    code: 'P0335',
    title: 'Crankshaft position sensor circuit',
    severity: 'High',
    causes: [
      'Faulty crankshaft sensor',
      'Damaged wiring or connector',
      'Damaged reluctor ring',
    ],
    firstCheck: 'Check the sensor wiring and air gap. No-start is common.',
  ),
  ObdCode(
    code: 'P0340',
    title: 'Camshaft position sensor circuit',
    severity: 'Medium',
    causes: ['Faulty camshaft sensor', 'Wiring problem', 'Timing issue'],
    firstCheck: 'Check the sensor connector and its signal with a scope.',
  ),
  ObdCode(
    code: 'P0401',
    title: 'EGR flow insufficient',
    severity: 'Medium',
    causes: [
      'Clogged EGR valve or passages',
      'Faulty EGR valve',
      'Vacuum line problem',
    ],
    firstCheck: 'Remove and clean the EGR valve, check its movement.',
  ),
  ObdCode(
    code: 'P0420',
    title: 'Catalytic converter efficiency below threshold',
    severity: 'Medium',
    causes: [
      'Worn catalytic converter',
      'Faulty downstream oxygen sensor',
      'Exhaust leak before the sensor',
    ],
    firstCheck: 'Check for exhaust leaks and compare both oxygen sensors.',
  ),
  ObdCode(
    code: 'P0442',
    title: 'Small evaporative emission leak',
    severity: 'Low',
    causes: ['Loose or worn fuel cap', 'Cracked EVAP hose', 'Purge valve'],
    firstCheck: 'Tighten or replace the fuel cap, then recheck.',
  ),
  ObdCode(
    code: 'P0500',
    title: 'Vehicle speed sensor fault',
    severity: 'Medium',
    causes: ['Faulty speed sensor', 'Wiring problem', 'ABS ring damage'],
    firstCheck: 'Check the sensor wiring and compare with the ABS speed.',
  ),
  ObdCode(
    code: 'P0562',
    title: 'System voltage low',
    severity: 'Medium',
    causes: ['Weak battery', 'Failing alternator', 'Corroded terminals'],
    firstCheck: 'Test battery and charging voltage (about 13.8 to 14.4 V).',
  ),
  ObdCode(
    code: 'P0700',
    title: 'Transmission control system fault',
    severity: 'High',
    causes: [
      'A gearbox code is stored in the transmission module',
      'Low or burnt transmission fluid',
      'Faulty solenoid or sensor',
    ],
    firstCheck: 'Read the transmission module for its own code.',
  ),
  ObdCode(
    code: 'P2002',
    title: 'Diesel particulate filter efficiency below threshold',
    severity: 'Medium',
    causes: [
      'Clogged particulate filter',
      'Faulty pressure sensor',
      'Short trips never reach regeneration',
    ],
    firstCheck: 'Check soot load, try a forced regeneration.',
  ),
];

ObdCode? findObdCode(String input) {
  final wanted = input.trim().toUpperCase().replaceAll(' ', '');
  if (wanted.isEmpty) return null;
  for (final c in kObdCodes) {
    if (c.code == wanted) return c;
  }
  // P0302 to P0304 point to the cylinder misfire entry.
  if (RegExp(r'^P030[2-4]$').hasMatch(wanted)) {
    return findObdCode('P0301');
  }
  return null;
}
