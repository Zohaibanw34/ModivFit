class OnboardingData {
  OnboardingData._();

  static final OnboardingData instance = OnboardingData._();

  String? gender;
  String? goal;
  String? fitnessLevel;
  int? birthYear;
  int? age;
  num? heightValue;
  String? heightUnit;
  num? weightValue;
  String? weightUnit;

  Map<String, dynamic> toMap() {
    return {
      if (gender != null) 'gender': gender,
      if (goal != null) 'goal': goal,
      if (fitnessLevel != null) 'fitness_level': fitnessLevel,
      if (birthYear != null) 'birth_year': birthYear,
      if (age != null) 'age': age,
      if (heightValue != null) 'height_value': heightValue,
      if (heightUnit != null) 'height_unit': heightUnit,
      if (weightValue != null) 'weight_value': weightValue,
      if (weightUnit != null) 'weight_unit': weightUnit,
    };
  }

  Map<String, dynamic> toRegistrationApiMap() {
    final map = <String, dynamic>{};

    if (gender != null && gender!.trim().isNotEmpty) {
      map['gender'] = gender!.trim().toLowerCase();
    }

    if (goal != null && goal!.trim().isNotEmpty) {
      final normalizedGoal = goal!.trim().toLowerCase();
      if (normalizedGoal == 'lose fat') {
        map['goal'] = 'lose_fat';
      } else if (normalizedGoal == 'stay fit') {
        map['goal'] = 'stay_fit';
      } else if (normalizedGoal == 'build muscle') {
        map['goal'] = 'build_muscle';
      } else {
        map['goal'] = normalizedGoal.replaceAll(' ', '_');
      }
    }

    if (fitnessLevel != null && fitnessLevel!.trim().isNotEmpty) {
      map['fitness_level'] = fitnessLevel!.trim().toLowerCase();
    }

    if (birthYear != null) {
      map['birth_year'] = birthYear;
    }

    if (heightValue != null) {
      final unit = (heightUnit ?? '').toLowerCase();
      if (unit == 'cm') {
        map['height_cm'] = heightValue;
      } else if (unit == 'in') {
        map['height_cm'] = ((heightValue as num) * 2.54).round();
      }
    }

    if (weightValue != null) {
      final unit = (weightUnit ?? '').toLowerCase();
      if (unit == 'kg') {
        map['weight_kg'] = weightValue;
      } else if (unit == 'lb') {
        map['weight_kg'] = ((weightValue as num) * 0.453592).round();
      }
    }

    map['is_ready'] = true;
    return map;
  }

  void clear() {
    gender = null;
    goal = null;
    fitnessLevel = null;
    birthYear = null;
    age = null;
    heightValue = null;
    heightUnit = null;
    weightValue = null;
    weightUnit = null;
  }
}
