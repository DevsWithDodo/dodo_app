import 'package:csocsort_szamla/bloc/login/login_bloc.dart';
import 'package:csocsort_szamla/bloc/status_interface.dart';
import 'package:csocsort_szamla/components/auth/pin_pad.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
import 'package:csocsort_szamla/components/request_status_dialog.dart';
import 'package:csocsort_szamla/data/repositories/authentication_repository.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static Route route() => MaterialPageRoute(builder: (_) => const LoginPage());

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginBloc(context.read<AuthenticationRepository>()),
      child: const LoginView(),
    );
  }
}

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        print(state.status);
        if (state.status == RequestStatus.loading) {
          showRequestStatusDialog<LoginBloc, LoginState, LoginEvent>(
            context: context,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('login'.tr()),
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 500),
              child: BlocBuilder<LoginBloc, LoginState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: ListView(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            shrinkWrap: true,
                            children: [
                              AnimatedSwitcher(
                                duration: Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) => FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.25),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                ),
                                child: state.page == LoginProgress.name
                                    ? NameView()
                                    : state.page == LoginProgress.pin
                                        ? PinView()
                                        : PasswordView(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (state.page == LoginProgress.name)
                              Container()
                            else
                              GradientButton(
                                child: Icon(Icons.arrow_left),
                                onPressed: () => context.read<LoginBloc>().add(LoginWentToName()),
                              ),
                            GradientButton(
                              child: Icon(Icons.arrow_right),
                              onPressed: () => context.read<LoginBloc>().add(
                                    state.page == LoginProgress.name
                                        ? LoginUsernameSubmitted()
                                        : state.page == LoginProgress.pin
                                            ? LoginPinSubmitted()
                                            : LoginPasswordSubmitted(),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NameView extends StatelessWidget {
  const NameView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        return TextFormField(
          initialValue: state.username.value,
          onChanged: (username) => context.read<LoginBloc>().add(LoginUsernameChanged(username: username)),
          decoration: InputDecoration(
            hintText: 'username'.tr(),
            helperText: !state.username.isPure ? 'username'.tr() : null,
            prefixIcon: Icon(Icons.account_circle),
          ),
          validator: state.username.validator,
          inputFormatters: [
            LengthLimitingTextInputFormatter(15),
          ],
          autovalidateMode: state.showUsernameError ? AutovalidateMode.always : AutovalidateMode.disabled,
        );
      },
    );
  }
}

class PinView extends StatelessWidget {
  const PinView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {},
      child: BlocBuilder<LoginBloc, LoginState>(
        builder: (context, state) {
          return Column(
            children: [
              PinPad(
                pin: state.pin.value,
                onPinChanged: (pin) => context.read<LoginBloc>().add(LoginPinChanged(pin: pin)),
                validationText: state.showPinError ? state.pin.displayError : null,
              ),
              SizedBox(height: 30),
              OutlinedButton(
                onPressed: () {
                  context.read<LoginBloc>().add(LoginSwitchedToPassword());
                },
                child: Text(
                  'change_to_password'.tr(),
                  style: Theme.of(context).textTheme.labelLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PasswordView extends StatelessWidget {
  const PasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {},
      child: BlocBuilder<LoginBloc, LoginState>(
        builder: (context, state) {
          return Column(
            children: [
              TextFormField(
                initialValue: state.password.value,
                validator: state.password.validator,
                decoration: InputDecoration(
                  hintText: 'password'.tr(),
                  helperText: state.password.isPure ? 'password'.tr() : null,
                  prefixIcon: Icon(Icons.password),
                ),
                obscureText: true,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                ],
                onChanged: (value) => context.read<LoginBloc>().add(LoginPasswordChanged(password: value)),
                onFieldSubmitted: (value) => context.read<LoginBloc>().add(LoginPasswordSubmitted()),
              ),
              SizedBox(height: 30),
              OutlinedButton(
                onPressed: () {
                  context.read<LoginBloc>().add(LoginSwitchedToPin());
                },
                child: Text(
                  'change_to_pin'.tr(),
                  style: Theme.of(context).textTheme.labelLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
