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

class LoginPinChanged extends LoginEvent {
  final String pin;

  const LoginPinChanged({required this.pin});

  @override
  List<Object> get props => [pin];
}

class LoginPinSubmitted extends LoginEvent {
  const LoginPinSubmitted();
}

class LoginWentToName extends LoginEvent {
  const LoginWentToName();
}

class LoginSwitchedToPassword extends LoginEvent {
  const LoginSwitchedToPassword();
}

class LoginSwitchedToPin extends LoginEvent {
  const LoginSwitchedToPin();
}

class LoginStatusChangedToInitial extends LoginEvent {
  const LoginStatusChangedToInitial();
}