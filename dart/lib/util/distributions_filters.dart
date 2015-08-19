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

  bool get isActive_Any => isActiveWeight || isActiveLength || isActiveName;
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

  bool get isActive_Any => isActiveWeather || isActiveTemperature || isActiveTide;
}

abstract class DistributionsFilter_Term {
  bool get isActive_Any => isActiveInterval || isActiveRecent || isActiveSeason;

  bool get isActiveInterval;
  bool get isActiveRecent;
  bool get isActiveSeason;

  int get recentValue;
  DistributionsFilter_Term_RecentUnit get recentUnit;
  int get recentUnitValue {
    switch (recentUnit) {
      case DistributionsFilter_Term_RecentUnit.days:
        return 1000 * 60 * 60 * 24;
      case DistributionsFilter_Term_RecentUnit.weeks:
        return 1000 * 60 * 60 * 24 * 7;
      case DistributionsFilter_Term_RecentUnit.months:
        return 1000 * 60 * 60 * 24 * 30;
    }
  }

  int get seasonBegin;
  int get seasonEnd;

  DateTime get intervalFrom;
  DateTime get intervalTo;
}

enum DistributionsFilter_Term_RecentUnit { days, weeks, months }
