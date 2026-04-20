import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/screener_models.dart';
import '../../domain/usecases/compute_decision_matrix.dart';

part 'decision_matrix_provider.g.dart';

/// Computes the post-tax decision matrix for given input parameters.
@riverpod
DecisionMatrixResult decisionMatrix(
  DecisionMatrixRef ref,
  DecisionMatrixInput input,
) {
  return DecisionMatrixCalculator.compute(input);
}
