# Trained model results (for the report)

- Dataset: Kaggle "car parts 50" (50 classes, 8739 train / 250 val / 250 test images). Check and cite its licence and link.
- Model: YOLOv8s-cls (5.1 M parameters, 10.4 MB), image size 224, trained on a Kaggle Tesla T4.
- Training: stopped early after 21 epochs (best epoch 11), 0.149 h.
- Validation: top-1 94.8 %, top-5 98.0 %.
- Test (never seen): top-1 96.0 %, top-5 100 %.
- Speed: about 2 ms per image on the T4 GPU.
- Caveat: only 5 test images per class, and dataset photos are cleaner than phone photos. Re-measure with your own photos.

Classes (index: name): 0 AIR COMPRESSOR, 1 ALTERNATOR, 2 BATTERY, 3 BRAKE CALIPER, 4 BRAKE PAD, 5 BRAKE ROTOR, 6 CAMSHAFT, 7 CARBERATOR, 8 CLUTCH PLATE, 9 COIL SPRING, 10 CRANKSHAFT, 11 CYLINDER HEAD, 12 DISTRIBUTOR, 13 ENGINE BLOCK, 14 ENGINE VALVE, 15 FUEL INJECTOR, 16 FUSE BOX, 17 GAS CAP, 18 HEADLIGHTS, 19 IDLER ARM, 20 IGNITION COIL, 21 INSTRUMENT CLUSTER, 22 LEAF SPRING, 23 LOWER CONTROL ARM, 24 MUFFLER, 25 OIL FILTER, 26 OIL PAN, 27 OIL PRESSURE SENSOR, 28 OVERFLOW TANK, 29 OXYGEN SENSOR, 30 PISTON, 31 PRESSURE PLATE, 32 RADIATOR, 33 RADIATOR FAN, 34 RADIATOR HOSE, 35 RADIO, 36 RIM, 37 SHIFT KNOB, 38 SIDE MIRROR, 39 SPARK PLUG, 40 SPOILER, 41 STARTER, 42 TAILLIGHTS, 43 THERMOSTAT, 44 TORQUE CONVERTER, 45 TRANSMISSION, 46 VACUUM BRAKE BOOSTER, 47 VALVE LIFTER, 48 WATER PUMP, 49 WINDOW REGULATOR.

The model file `best.pt` is not in Git (ai_server/models/ is ignored). Keep a copy on Kaggle (Save Version) and on your PC.
