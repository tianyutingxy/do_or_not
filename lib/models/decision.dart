enum Decision { doIt, notIt }

extension DecisionX on Decision {
  bool get isDo => this == Decision.doIt;

  String get label => isDo ? 'DO' : 'NOT';

  String get subtitle => isDo ? '做' : '不做';
}
