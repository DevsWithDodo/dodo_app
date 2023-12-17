import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:csocsort_szamla/bloc/login/form_fields/password.dart';
import 'package:csocsort_szamla/bloc/login/form_fields/pin.dart';
import 'package:csocsort_szamla/bloc/login/form_fields/username.dart';
import 'package:csocsort_szamla/bloc/status_interface.dart';
import 'package:csocsort_szamla/data/repositories/authentication_repository.dart';
import 'package:equatable/equatable.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc(AuthenticationRepository authenticationRepository)
      : _authenticationRepository = authenticationRepository,
        super(const LoginState()) {
    on<LoginUsernameChanged>(_onUsernameChanged);
    on<LoginUsernameSubmitted>(_onUsernameSubmitted);
    on<LoginPasswordChanged>(_onPasswordChanged);
    on<LoginPasswordSubmitted>(_onPasswordSubmitted);
    on<LoginWentToName>(_onBackToName);
    on<LoginSwitchedToPassword>(_onSwitchedToPassword);
    on<LoginSwitchedToPin>(_onSwitchedToPin);
    on<LoginPinChanged>(_onPinChanged);
    on<LoginPinSubmitted>(_onPinSubmitted);
    on<LoginStatusChangedToInitial>(_onStatusChangedToInitial);
  }

  final AuthenticationRepository _authenticationRepository;


  @override
  void onTransition(Transition<LoginEvent, LoginState> transition) {
    super.onTransition(transition);
    print(transition);
  }

  void _onUsernameChanged(LoginUsernameChanged event, Emitter<LoginState> emit) {
    emit(state.copyWith(username: Username.dirty(event.username)));
  }

  void _onUsernameSubmitted(LoginUsernameSubmitted event, Emitter<LoginState> emit) {
    if (state.username.isValid) {
      emit(state.copyWith(page: LoginProgress.pin, showUsernameError: true));
    } else {
      emit(state.copyWith(showUsernameError: true));
    }
  }

  void _onPasswordChanged(LoginPasswordChanged event, Emitter<LoginState> emit) {
    emit(state.copyWith(password: Password.dirty(event.password)));
  }

  Future<void> _onPasswordSubmitted(LoginPasswordSubmitted event, Emitter<LoginState> emit) async {
    if (state.password.isValid && state.username.isValid) {
      try {
        emit(state.copyWith(status: RequestStatus.loading));
        await _authenticationRepository.login(state.username.value, state.password.value);
      } catch (e) {
        emit(state.copyWith(status: RequestStatus.failure));
      }
    } else {
      emit(state.copyWith(showPasswordError: true));
    }
  }

  void _onPinChanged(LoginPinChanged event, Emitter<LoginState> emit) {
    emit(state.copyWith(pin: Pin.dirty(event.pin)));
  }

  void _onPinSubmitted(LoginPinSubmitted event, Emitter<LoginState> emit) {
    if (state.pin.isValid && state.username.isValid) {
      _authenticationRepository.login(state.username.value, state.pin.value);
    } else {
      emit(state.copyWith(showPinError: true));
    }
  }

  void _onBackToName(LoginWentToName event, Emitter<LoginState> emit) {
    emit(state.copyWith(page: LoginProgress.name));
  }

  void _onSwitchedToPassword(LoginSwitchedToPassword event, Emitter<LoginState> emit) {
    emit(state.copyWith(page: LoginProgress.password));
  }

  void _onSwitchedToPin(LoginSwitchedToPin event, Emitter<LoginState> emit) {
    emit(state.copyWith(page: LoginProgress.pin));
  }

  void _onStatusChangedToInitial(LoginStatusChangedToInitial event, Emitter<LoginState> emit) {
    emit(state.copyWith(status: RequestStatus.initial));
  }
}
