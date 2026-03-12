abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class CameraFailure extends Failure {
  const CameraFailure(super.message);
}

class ScanFailure extends Failure {
  const ScanFailure(super.message);
}
