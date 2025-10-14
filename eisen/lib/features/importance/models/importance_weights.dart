
class ImportanceWeights {
  final String userId;
  List<double> mu;
  List<List<double>> sigma;
  double alpha;
  double beta;
  double gamma;
  ImportanceWeights({
    required this.userId,
    this.mu=const[0.6,0.3,0.1],
    this.sigma=const[[1,0,0],[0,1,0],[0,0,1]],
    this.alpha=0.6,
    this.beta=0.3,
    this.gamma=0.1,
  });
}
