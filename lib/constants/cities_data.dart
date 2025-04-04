class CityManager {
  // Singleton instance
  static final CityManager _instance = CityManager._internal();
  
  // Factory constructor to return the same instance
  factory CityManager() => _instance;
  
  // Private constructor
  CityManager._internal() {
    // Sort the cities list during initialization
    _cities.sort((a, b) => a.compareTo(b));
  }
  
  // List of cities (will be sorted alphabetically during initialization)
  final List<String> _cities = [
    'Karachi',
    'Lahore',
    'Faisalabad',
    'Rawalpindi',
    'Multan',
    'Hyderabad',
    'Gujranwala',
    'Peshawar',
    'Quetta',
    'Islamabad',
    'Bahawalpur',
    'Sargodha',
    'Sialkot',
    'Sukkur',
    'Larkana',
    'Sheikhupura',
    'Jhang',
    'Rahim Yar Khan',
    'Gujrat',
    'Mardan',
    'Kasur',
    'Mingora',
    'Dera Ghazi Khan',
    'Sahiwal',
    'Nawabshah',
    'Okara',
    'Mirpur Khas',
    'Chiniot',
    'Kamoke',
    'Sadiqabad',
    'Burewala',
    'Jacobabad',
    'Muzaffargarh',
    'Muridke',
    'Jhelum',
    'Shikarpur',
    'Hafizabad',
    'Kohat',
    'Khanpur',
    'Khuzdar',
    'Dadu',
    'Gojra',
    'Mandi Bahauddin',
    'Tando Allahyar',
    'Daska',
    'Pakpattan',
    'Bahawalnagar',
    'Tando Adam',
    'Khairpur',
    'Chishtian',
    'Abbottabad',
    'Jaranwala',
    'Ahmadpur East',
    'Vihari',
    'Kamalia',
    'Kot Addu',
    'Khushab',
    'Wazirabad',
    'Dera Ismail Khan',
    'Chakwal',
    'Swabi',
    'Lodhran',
    'Nowshera',
  ];
  
  // Get all cities (now always in alphabetical order)
  List<String> get cities => List.unmodifiable(_cities);
  
  // For compatibility with existing code, sortedCities now just returns cities
  // as they are already sorted
  List<String> get sortedCities => cities;
  
  // Add a new city and maintain alphabetical order
  void addCity(String city) {
    if (!_cities.contains(city)) {
      _cities.add(city);
      // Re-sort to maintain alphabetical order
      _cities.sort((a, b) => a.compareTo(b));
    }
  }
  
  // Add multiple cities and maintain alphabetical order
  void addCities(List<String> newCities) {
    bool changed = false;
    for (String city in newCities) {
      if (!_cities.contains(city)) {
        _cities.add(city);
        changed = true;
      }
    }
    if (changed) {
      // Re-sort to maintain alphabetical order
      _cities.sort((a, b) => a.compareTo(b));
    }
  }
  
  // Remove a city
  void removeCity(String city) {
    if (_cities.contains(city)) {
      _cities.remove(city);
      // No need to resort after removal
    }
  }
  
  // Search cities by query
  List<String> searchCities(String query) {
    if (query.isEmpty) return cities;
    
    final lowercaseQuery = query.toLowerCase();
    return cities.where(
      (city) => city.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }
}

// For backward compatibility
class PakistanCities {
  static List<String> get cities => CityManager().cities;
  static List<String> get sortedCities => CityManager().cities; // Both return same sorted list
}
