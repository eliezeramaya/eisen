
class ImportanceFeatures {
  final String taskId;
  final bool inTop3;
  final double deadlineSoon;
  final double focus7d;
  final double snoozePenalty;
  final double editsNorm;
  final double recencyView;
  final double textHint;
  final double contextFit;
  final bool isQ2;
  double sampledScore = 0;
  ImportanceFeatures({
    required this.taskId,
    this.inTop3=false,
    this.deadlineSoon=0,
    this.focus7d=0,
    this.snoozePenalty=0,
    this.editsNorm=0,
    this.recencyView=0,
    this.textHint=0,
    this.contextFit=0,
    this.isQ2=false,
  });
}
