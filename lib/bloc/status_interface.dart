enum RequestStatus { initial, loading, success, failure }

class Status {
  final RequestStatus status;
  final String? message;

  const Status(this.status, [this.message]);

  const Status.initial() : this(RequestStatus.initial);
  const Status.loading() : this(RequestStatus.loading);
  const Status.success([String? message]) : this(RequestStatus.success, message);
  const Status.failure([String? message]) : this(RequestStatus.failure, message);
}

abstract class StatusInterface {
  Status get status;
}