import 'package:get/get.dart';

import '../models/random_challenge.dart';

class RandomChallengeRepository extends GetxController {
  RandomChallengeRepository();

  final RxList<RandomChallenge> _challenges = <RandomChallenge>[].obs;

  List<RandomChallenge> get challenges => List.unmodifiable(_challenges);
  RxList<RandomChallenge> get observableChallenges => _challenges;
  bool get hasChallenges => _challenges.isNotEmpty;

  void addChallenge(RandomChallenge challenge) {
    _challenges.insert(0, challenge);
    update();
  }
}
