class GeographicData {
  static const Map<String, Map<String, List<String>>> indiaData = {
    'Maharashtra': {
      'Pune': ['Pune City', 'Pimpri-Chinchwad', 'Haveli', 'Maval'],
      'Mumbai': ['Mumbai City', 'Mumbai Suburban'],
      'Nagpur': ['Nagpur City', 'Kamptee', 'Hingna'],
      'Nashik': ['Nashik City', 'Igatpuri', 'Sinnar'],
    },
    'Karnataka': {
      'Bangalore': ['Bangalore North', 'Bangalore South', 'Bangalore East'],
      'Mysore': ['Mysore City', 'Nanjangud', 'T.Narsipura'],
      'Hubli': ['Hubli City', 'Dharwad'],
    },
    'Delhi': {
      'New Delhi': ['Connaught Place', 'Chanakyapuri'],
      'South Delhi': ['Saket', 'Hauz Khas'],
    },
    'Gujarat': {
      'Ahmedabad': ['Ahmedabad City', 'Daskroi'],
      'Surat': ['Surat City', 'Choryasi'],
      'Vadodara': ['Vadodara City', 'Padra'],
    }
  };

  static List<String> getCountries() => ['India', 'USA', 'UK', 'Canada'];
  
  static List<String> getStates(String country) {
    if (country == 'India') return indiaData.keys.toList();
    return ['State 1', 'State 2'];
  }

  static List<String> getDistricts(String country, String state) {
    if (country == 'India' && indiaData.containsKey(state)) {
      return indiaData[state]!.keys.toList();
    }
    return ['District 1', 'District 2'];
  }

  static List<String> getCities(String country, String state, String district) {
    if (country == 'India' && indiaData.containsKey(state) && indiaData[state]!.containsKey(district)) {
      return indiaData[state]![district]!;
    }
    return ['City 1', 'City 2'];
  }
}
