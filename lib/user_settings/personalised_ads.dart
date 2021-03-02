import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/essentials/http_handler.dart';
class PersonalisedAds extends StatefulWidget {

  @override
  _PersonalisedAdsState createState() => _PersonalisedAdsState();
}

class _PersonalisedAdsState extends State<PersonalisedAds> {

  bool _personalisedAds = personalisedAds;

  Future<bool> _updatePersonalisedAds() async {
    try{
      if(personalisedAds!=_personalisedAds){
        Map<String, dynamic> body = {
          "personalised_ads":_personalisedAds?"on":"off"
        };
        await httpPut(context: context, uri: '/user', body: body);
        personalisedAds=_personalisedAds;
        Future.delayed(delayTime()).then((value) => _onUpdatePersonalisedAds());
        return true;
      }else{
        return Future.value(true);
      }

    } catch(_){
      throw _;
    }
  }

  void _onUpdatePersonalisedAds(){
    Navigator.pop(context);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Text(
                  'use_personalised_ads'.tr(),
                  style: Theme.of(context).textTheme.headline6,
                )
            ),
            SizedBox(
              height: 10,
            ),
            Center(
              child: Text(
                'use_personalised_ads_explanation'.tr(),
                style: Theme.of(context).textTheme.subtitle2,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              height: 20,
            ),
            SwitchListTile(
              value: _personalisedAds,
              secondary: Icon(Icons.update, color: Theme.of(context).colorScheme.primary,),
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (value){
                setState(() {
                  _personalisedAds=value;
                });
                showDialog(
                    context: context,
                    barrierDismissible: false,
                    child: FutureSuccessDialog(
                      future: _updatePersonalisedAds(),
                      onDataTrue: (){
                        _onUpdatePersonalisedAds();
                      },
                      onDataFalse: (){
                        Navigator.pop(context);
                        setState(() {
                          _personalisedAds=!_personalisedAds;
                        });
                      },
                      onNoData: (){
                        Navigator.pop(context);
                        setState(() {
                          _personalisedAds=!_personalisedAds;
                        });
                      },
                      dataTrueText: 'update_personalised_ads_scf',
                    )
                );
              },

              title: Text('use_personalised_ads'.tr(), style: Theme.of(context).textTheme.subtitle2,),
              dense: true,
            ),
          ],
        ),
      ),
    );
  }
}
