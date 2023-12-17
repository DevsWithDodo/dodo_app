part of 'login_bloc.dart';

enum LoginProgress { name, pin, password }

final class LoginState extends Equatable implements StatusInterface {
  const LoginState({
    this.username = const Username.pure(),
    this.password = const Password.pure(),
    this.pin = const Pin.pure(),
    this.showUsernameError = false,
    this.showPasswordError = false,
    this.showPinError = false,
    this.page = LoginProgress.name,
    this.status = const Status.initial(),
  });

  final Username username;
  final Password password;
  final Pin pin;
  final LoginProgress page;
  final bool showUsernameError;
  final bool showPasswordError;
  final bool showPinError;
  final Status status;

  @override
  List<Object> get props => [username, password, pin, showUsernameError, showPasswordError, page, status];

  LoginState copyWith({
    Username? username,
    bool? showUsernameError,
    Password? password,
    bool? showPasswordError,
    Pin? pin,
    bool? showPinError,
    LoginProgress? page,
    Status? status,
  }) {
    return LoginState(
      username: username ?? this.username,
      showUsernameError: showUsernameError ?? this.showUsernameError,
      password: password ?? this.password,
      showPasswordError: showPasswordError ?? this.showPasswordError,
      pin: pin ?? this.pin,
      showPinError: showPinError ?? this.showPinError,
      page: page ?? this.page,
      status: status ?? this.status,
    );
  }
}