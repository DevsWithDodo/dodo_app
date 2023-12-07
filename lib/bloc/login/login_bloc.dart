import 'package:bloc/bloc.dart';
import 'package:csocsort_szamla/bloc/login/form_fields/password.dart';
import 'package:csocsort_szamla/bloc/login/form_fields/username.dart';
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
      emit(state.copyWith(page: LoginProgress.password, showUsernameError: true));
    } else {
      emit(state.copyWith(showUsernameError: true));
    }
  }

  void _onPasswordChanged(LoginPasswordChanged event, Emitter<LoginState> emit) {
    emit(state.copyWith(password: Password.dirty(event.password)));
  }

  void _onPasswordSubmitted(LoginPasswordSubmitted event, Emitter<LoginState> emit) {
    if (state.isValid) {
      _authenticationRepository.login(state.username.value, state.password.value);
    } else {
      emit(state.copyWith(showPasswordError: true));
    }
  }
}
