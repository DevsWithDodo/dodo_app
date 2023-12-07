import 'package:csocsort_szamla/bloc/login/login_bloc.dart';
import 'package:csocsort_szamla/components/auth/pin_pad.dart';
import 'package:csocsort_szamla/components/helpers/gradient_button.dart';
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
      child: Scaffold(
        appBar: AppBar(
          title: Text('login'.tr()),
        ),
        body: const LoginView(),
      ),
    );
  }
}

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 500),
          child: BlocBuilder<LoginBloc, LoginState>(
            builder: (context, state) {
              switch (state.page) {
                case LoginProgress.name:
                  return NameView();
                case LoginProgress.password:
                  return PinView();
              }
            },
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
        return Column(
          children: [
            Expanded(
              child: Center(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  shrinkWrap: true,
                  children: <Widget>[
                    TextFormField(
                      onChanged: (username) => context.read<LoginBloc>().add(LoginUsernameChanged(username: username)),
                      decoration: InputDecoration(
                        hintText: 'username'.tr(),
                        helperText: !state.username.isPure ? 'username'.tr() : null,
                        prefixIcon: Icon(
                          Icons.account_circle,
                        ),
                      ),
                      validator: state.username.validator,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(15),
                      ],
                      autovalidateMode: state.showUsernameError ? AutovalidateMode.always : AutovalidateMode.disabled,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(30),
              child: Align(
                alignment: Alignment.centerRight,
                child: GradientButton(
                  child: Icon(Icons.arrow_right),
                  onPressed: () => context.read<LoginBloc>().add(LoginUsernameSubmitted()),
                ),
              ),
            ),
          ],
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
      listener: (context, state) {
        
      },
      child: BlocBuilder<LoginBloc, LoginState>(
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                child: Center(
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    shrinkWrap: true,
                    children: <Widget>[
                      PinPad(
                        pin: state.password.value,
                        onPinChanged: (pin) => context.read<LoginBloc>().add(LoginPasswordChanged(password: pin)),
                        validationText: state.showPasswordError ? state.password.displayError : null,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(30),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GradientButton(
                    child: Icon(Icons.arrow_right),
                    onPressed: () => context.read<LoginBloc>().add(LoginPasswordSubmitted()),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
