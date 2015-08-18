library triton_note.util.distributions_filters;

import 'package:logging/logging.dart';

import 'package:triton_note/model/location.dart';

final _logger = new Logger('DistributionsFilters');

abstract class DistributionsFilter {
  bool get isIncludeOthers;
  DistributionsFilter_Fish get fish;
  DistributionsFilter_Conditions get cond;
  DistributionsFilter_Term get term;
}

abstract class DistributionsFilter_Fish {
  String get name;
  /**
   * 単位は cm に統一
   */
  double get lengthMin;
  /**
   * 単位は cm に統一
   */
  double get lengthMax;
  /**
   * 単位は g に統一
   */
  double get weightMin;
  /**
   * 単位は g に統一
   */
  double get weightMax;

  bool get isActiveName;

  bool get isActiveLengthMin;
  bool get isActiveLengthMax;
  bool get isActiveLength;

  bool get isActiveWeightMin;
  bool get isActiveWeightMax;
  bool get isActiveWeight;
}

abstract class DistributionsFilter_Conditions {
  String get weatherNominal;

  /**
   * 単位は °C に統一
   */
  double get temperatureMin;
  /**
   * 単位は °C に統一
   */
  double get temperatureMax;

  Tide get tide;
  int get moon;

  bool get isActiveTemperatureMin;
  bool get isActiveTemperatureMax;

  bool get isActiveWeather;
  bool get isActiveTemperature;
  bool get isActiveTide;
}

abstract class DistributionsFilter_Term {
  bool get isActiveInterval;
  bool get isActiveRecent;
  bool get isActiveSeason;

  int get recentValue;
  DistributionsFilter_Term_RecentUnit get recentUnit;

  int get seasonBegin;
  int get seasonEnd;

  DateTime get intervalFrom;
  DateTime get intervalTo;
}

enum DistributionsFilter_Term_RecentUnit { days, weeks, months }
