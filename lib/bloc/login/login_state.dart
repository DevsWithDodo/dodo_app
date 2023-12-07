part of 'login_bloc.dart';

enum LoginProgress { name, password }

final class LoginState extends Equatable {
  const LoginState({
    this.username = const Username.pure(),
    this.password = const Password.pure(),
    this.showUsernameError = false,
    this.showPasswordError = false,
    this.page = LoginProgress.name,
  });

  final Username username;
  final Password password;
  final LoginProgress page;
  final bool showUsernameError;
  final bool showPasswordError;

  bool get isValid => username.isValid && password.isValid;

  @override
  List<Object> get props => [username, password, showUsernameError, showPasswordError, page];

  LoginState copyWith({
    Username? username,
    bool? showUsernameError,
    Password? password,
    bool? showPasswordError,
    LoginProgress? page,
  }) {
    return LoginState(
      username: username ?? this.username,
      showUsernameError: showUsernameError ?? this.showUsernameError,
      password: password ?? this.password,
      showPasswordError: showPasswordError ?? this.showPasswordError,
      page: page ?? this.page,
    );
  }
}