library location;

import 'package:triton_note/model/value_unit.dart';

class Location {
  String name;
  GeoInfo geoinfo;
  
  Location(this.name, this.geoinfo);
}

class GeoInfo {
  double latitude;
  double longitude;
  
  GeoInfo(this.latitude, this.longitude);
}

class Condition {
  int moon;
  Tide tide;
  Weather weather;
  
  Condition(this.moon, this.tide, this.weather);
}

enum Tide {
  Flood, High, Ebb, Low
}

class Weather {
  String nominal;
  String iconUrl;
  Temperature temp;
  
  Weather(this.nominal, this.iconUrl, this.temp);
}
