part of 'login_bloc.dart';

sealed class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object> get props => [];
}

class LoginUsernameChanged extends LoginEvent {
  final String username;

  const LoginUsernameChanged({required this.username});

  @override
  List<Object> get props => [username];
}

class LoginUsernameSubmitted extends LoginEvent {
  const LoginUsernameSubmitted();
}

class LoginPasswordChanged extends LoginEvent {
  final String password;

  const LoginPasswordChanged({required this.password});

  @override
  List<Object> get props => [password];
}

class LoginPasswordSubmitted extends LoginEvent {
  const LoginPasswordSubmitted();
}
