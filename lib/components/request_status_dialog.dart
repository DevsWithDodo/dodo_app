import 'package:bloc/bloc.dart';
import 'package:csocsort_szamla/bloc/status_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RequestStatusDialog<B extends Bloc<Event, State>, State extends StatusInterface, Event> extends StatelessWidget {
  RequestStatusDialog({required this.key}): super(key: key);

  final GlobalKey key;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: BlocBuilder<B, State>(
        builder: (context, state) {
          return SizedBox();
        },
      ),
    );
  }
}

void showRequestStatusDialog<B extends Bloc<Event, State>, State extends StatusInterface, Event>({
  required BuildContext context,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => RequestStatusDialog<B, State, Event>(
      key: GlobalObjectKey('request_status_dialog'),
    ),
  );
}