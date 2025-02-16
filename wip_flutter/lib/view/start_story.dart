import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sound_mode/permission_handler.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wip_flutter/arguments/wip_dialog_arguments.dart';
import 'package:wip_flutter/database/dao/shop_element_dao.dart';
import 'package:wip_flutter/database/dao/story_dao.dart';
import 'package:wip_flutter/utils/resource_helper.dart';
import 'package:wip_flutter/view/wip_dialog.dart';

import '../arguments/story_started_arguments.dart';
import '../database/dao/shopped_dao.dart';
import '../database/dao/user_dao.dart';
import '../database/model/shop_element.dart';
import '../database/model/shopped.dart';
import '../database/model/story.dart';
import '../database/model/user.dart';
import '../database/wip_db.dart';


class StartStory extends StatefulWidget {
  const StartStory({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<StartStory> createState() => _StartStoryState();

}

class _StartStoryState extends State<StartStory> {

  int? userId;

  String storyTitle = '';
  double? _studyTime = 50;
  double? _breakTime = 10;
  double? _maxSlider = 60;
  bool _silentMode = false;
  bool _hardcoreMode = false;

  String imagesPath = 'assets/images/start-story/';

  String backButtonPath = 'assets/images/shared/back_button.png';
  String infoButtonPath = 'assets/images/start-story/info_button.png';
  String sxButtonPath = 'assets/images/start-story/avatar_sx_arrow.png';
  String dxButtonPath = 'assets/images/start-story/avatar_dx_arrow.png';
  String startStoryButtonPath = 'assets/images/start-story/start_story_button.png';

  late Image backButtonPressed;
  late Image infoButtonPressed;
  late Image sxButtonPressed;
  late Image dxButtonPressed;
  late Image startStoryButtonPressed;

  List<String> storyNames = <String>[];

  List<String> shoppedAvatarNames = <String>[];
  List<String> shoppedBackgroundNames = <String>[];
  String avatarImage = 'assets/images/shared/frame.png';
  int avatarTag = 0;

  @override
  void initState() {
    super.initState();
    backButtonPressed = Image.asset('assets/images/shared/back_button_pressed.png');
    infoButtonPressed = Image.asset('${imagesPath}info_button_pressed.png');
    sxButtonPressed = Image.asset('${imagesPath}avatar_sx_arrow_pressed.png');
    dxButtonPressed = Image.asset('${imagesPath}avatar_dx_arrow_pressed.png');
    startStoryButtonPressed = Image.asset('${imagesPath}start_story_button_pressed.png');
    getUserSharedPreferences();
    getStoryNames();
    getShoppedElements();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(backButtonPressed.image, context);
    precacheImage(infoButtonPressed.image, context);
    precacheImage(sxButtonPressed.image, context);
    precacheImage(dxButtonPressed.image, context);
    precacheImage(startStoryButtonPressed.image, context);
    getSliderValuesFromUser();
  }

  void setBackButtonPath(String backButtonPath) {
    setState(() {
      this.backButtonPath = 'assets/images/shared/$backButtonPath';
    });
  }

  void setInfoButtonPath(String infoButtonPath) {
    setState(() {
      this.infoButtonPath = imagesPath + infoButtonPath;
    });
  }

  void setSxButtonPath(String sxButtonPath) {
    setState(() {
      this.sxButtonPath = imagesPath + sxButtonPath;
    });
  }

  void setDxButtonPath(String dxButtonPath) {
    setState(() {
      this.dxButtonPath = imagesPath + dxButtonPath;
    });
  }

  void setStartStoryButtonPath(String startStoryButtonPath) {
    setState(() {
      this.startStoryButtonPath = imagesPath + startStoryButtonPath;
    });
  }

  void getUserSharedPreferences() async {

    final sharedPreferences = await SharedPreferences.getInstance();

    userId = sharedPreferences.getInt('userId');

  }

  void getStoryNames() async {

    Database wipDb = await WIPDb.getDb();

    List<Story> stories = await StoryDao.getAllByUser(wipDb, userId!);

    setState(() {
      for(Story story in stories) {
        storyNames.add(story.storyName);
      }
    });

  }

  void getSliderValuesFromUser() async {

    Database wipDb = await WIPDb.getDb();

    User user = (await UserDao.getAllById(wipDb, userId!))[0];

    setState(() {
      _studyTime = user.studyTime.toDouble();

      _maxSlider = user.maxStudyTime.toDouble();

      _breakTime = _maxSlider! - _studyTime!;
    });

  }

  void setSilentMode(bool flag) async{

    bool? isGranted = await PermissionHandler.permissionsGranted;

    if (!isGranted!) {
      _silentMode = false;
      _hardcoreMode = false;
      await PermissionHandler.openDoNotDisturbSetting();
    } else {

      if(flag) {
        try {
          await SoundMode.setSoundMode(RingerModeStatus.silent);
        } on PlatformException {
          debugPrint('Please enable permissions required');
        }
      } else {
        try {
          await SoundMode.setSoundMode(RingerModeStatus.normal);
        } on PlatformException {
          debugPrint('Please enable permissions required');
        }
      }

    }

  }

  void getShoppedElements() async {

    Database wipDb = await WIPDb.getDb();

    List<Shopped> shoppedList = await ShoppedDao.getAllByUser(wipDb, userId!);
    List<ShopElement> shopElements = await ShopElementDao.getAll(wipDb);
    
    Map<String, String> shopElementsType = <String, String>{};
    
    for(ShopElement shopElement in shopElements) {
      shopElementsType.putIfAbsent(shopElement.elementName, () => shopElement.type);
    }

    for(Shopped shopped in shoppedList) {

      if(shopElementsType[shopped.shopElement] == 'avatar') {
        shoppedAvatarNames.add(shopped.shopElement);
      } else {
        shoppedBackgroundNames.add(shopped.shopElement);
      }

    }

    setState(() {
      avatarImage = fromShopElementAvatarToPath(shoppedAvatarNames.first);
    });

  }

  void sxButtonAction() {
    avatarTag--;
    if(avatarTag < 0) {
      avatarTag = shoppedAvatarNames.length - 1;
    }

    setState(() {
      avatarImage = fromShopElementAvatarToPath(shoppedAvatarNames[avatarTag]);
    });
  }

  void dxButtonAction() {
    avatarTag++;
    if(avatarTag + 1 > shoppedAvatarNames.length) {
      avatarTag = 0;
    }

    setState(() {
      avatarImage = fromShopElementAvatarToPath(shoppedAvatarNames[avatarTag]);
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
                image: DecorationImage(
                    image: AssetImage('assets/images/shared/background.png'),
                    fit: BoxFit.fill
                )
            ),
            padding: const EdgeInsets.only(top: 30, bottom: 30, left: 20, right: 20),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                        onTapDown: (_){
                          setBackButtonPath('back_button_pressed.png');
                        },
                        onPanDown: (_){
                          setBackButtonPath('back_button_pressed.png');
                        },
                        onTapCancel: (){
                          setBackButtonPath('back_button.png');
                        },
                        onPanEnd: (_){
                          setBackButtonPath('back_button.png');
                        },
                        onTap: () {
                          Navigator.pop(context);
                          setBackButtonPath('back_button.png');
                        },
                      child: Image.asset(backButtonPath, height: 60, width: 60, fit: BoxFit.cover)
                    )
                  ),
                  const Text(
                    'Titolo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'PressStart2P',
                        fontSize: 22
                    ),
                  ),
                  Container(
                    height: 70,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/shared/rectangular_background.png'),
                        fit: BoxFit.fill
                      )
                    ),
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    child: Center(
                        child: Autocomplete<String>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            return storyNames
                                .where((String storyName) => storyName.toLowerCase()
                                .startsWith(textEditingValue.text.toLowerCase())
                            ).toList();
                          },
                          onSelected: (String selection) {
                            setState(() {
                              storyTitle = selection;
                              FocusManager.instance.primaryFocus?.unfocus();
                            });
                          },
                          fieldViewBuilder: (
                              BuildContext context,
                              TextEditingController fieldTextEditingController,
                              FocusNode fieldFocusNode,
                              VoidCallback onFieldSubmitted) {
                            return TextField(
                                controller: fieldTextEditingController,
                                focusNode: fieldFocusNode,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Nuova storia',
                                  hintStyle: TextStyle(
                                      color: Color.fromARGB(255, 2, 119, 189),
                                      fontFamily: 'PressStart2P',
                                      fontSize: 16
                                  ),
                                ),
                                style: const TextStyle(
                                    color: Color.fromARGB(255, 2, 119, 189),
                                    fontFamily: 'PressStart2P',
                                    fontSize: 16
                                ),
                                onChanged: (value){
                                  setState(() {
                                    storyTitle = value;
                                  });
                                }
                              );
                            },
                          optionsViewBuilder: (
                              BuildContext context,
                              AutocompleteOnSelected<String> onSelected,
                              Iterable<String> options
                          ) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: SizedBox(
                                height: MediaQuery.of(context).size.height * 0.35,
                                width: MediaQuery.of(context).size.width * 0.8,
                                child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: options.length,
                                    itemBuilder: (_, index) {

                                      String option = options.elementAt(index);

                                      return GestureDetector(
                                        onTap: () {
                                          onSelected(option);
                                        },
                                        child: Material(
                                          child: ListTile(
                                            tileColor: const Color.fromARGB(255, 2, 119, 189),
                                            title: Text(
                                                option,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontFamily: 'PressStart2P',
                                                    fontSize: 16
                                                )
                                            ),
                                          )
                                        )
                                      );
                                    }
                                )
                              ),
                            );
                          },
                        ),
                    ),
                  ),
                  const Text(
                    'Tempo della storia',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'PressStart2P',
                        fontSize: 22
                    ),
                  ),
                  Container(
                    height: 70,
                    decoration: const BoxDecoration(
                        image: DecorationImage(
                            image: AssetImage('assets/images/shared/rectangular_background.png'),
                            fit: BoxFit.fill
                        )
                    ),
                    child: Center(
                        child: Slider(
                          thumbColor: const Color.fromARGB(255, 2, 119, 189),
                          min: 10.0,
                          max: _maxSlider! - 10,
                          divisions: _maxSlider!~/10 - 2, //Numero di divisioni - 1 sinistra e -1 destra
                          label: '${_studyTime!.round()} min lavoro/${_breakTime!.round()} min pausa',
                          value: _studyTime!,
                          onChanged: (newStudyTime) {
                            setState(() {
                              _studyTime = newStudyTime;
                              _breakTime = _maxSlider! - _studyTime!;
                            });
                          },
                        )
                    ),
                  ),
                  const Text(
                    'Impost. storia',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'PressStart2P',
                        fontSize: 22
                    ),
                  ),
                  Container(
                    height: 110,
                    decoration: const BoxDecoration(
                        image: DecorationImage(
                            image: AssetImage('assets/images/shared/rectangular_background.png'),
                            fit: BoxFit.fill
                        )
                    ),
                    padding: const EdgeInsets.only(left: 20),
                    child: Row(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Mod. silenzio',
                                  style: TextStyle(
                                    color: const Color.fromARGB(255, 2, 119, 189),
                                    fontFamily: 'PressStart2P',
                                    fontSize: MediaQuery.of(context).size.width * 0.041,
                                ),
                              ),
                                Switch(
                                    value: _silentMode,
                                    onChanged: (value) {
                                      setState((){
                                            if(!_hardcoreMode) {
                                              _silentMode = value;
                                              setSilentMode(value);
                                            }
                                          }
                                      );
                                    }
                                )
                              ]
                            ),
                            Row(
                              children: [
                                Text(
                                  'Mod. hardcore',
                                  style: TextStyle(
                                      color: const Color.fromARGB(255, 2, 119, 189),
                                      fontFamily: 'PressStart2P',
                                      fontSize: MediaQuery.of(context).size.width * 0.041,
                                  ),
                                ),
                                Switch(
                                    value: _hardcoreMode,
                                    onChanged: (value) {
                                      setState((){
                                        _silentMode = value;
                                        _hardcoreMode = value;
                                      }
                                      );
                                      setSilentMode(value);
                                    }
                                )
                              ],
                            )
                          ],
                        ),
                        Align(
                          alignment: Alignment.topCenter,
                          child: GestureDetector(
                              onTapDown: (_){
                                setInfoButtonPath('info_button_pressed.png');
                              },
                              onPanDown: (_){
                                setInfoButtonPath('info_button_pressed.png');
                              },
                              onTapCancel: (){
                                setInfoButtonPath('info_button.png');
                              },
                              onPanEnd: (_){
                                setInfoButtonPath('info_button.png');
                              },
                            child: IconButton(
                              icon: Image.asset(infoButtonPath),
                              onPressed: () {

                                setInfoButtonPath('info_button.png');

                                showDialog(context: context, builder: (context) {

                                  List<String> otherText = <String>[];

                                  otherText.add('Disattiva i suoni\ndelle notifiche.\nBASTA PARLARE\nCON LE PERSONE!');

                                  List<Widget> children = makeChildrenSection('Mod.\nsilenzio', '"Shhhh"', otherText, true);

                                  otherText.clear();

                                  otherText.add('Abilita la modalità\nsilenzionsa e se\nesci dall\'app la\ntua storia termina\nautomaticamente.');

                                  otherText.add('In altre parole,\npuoi solo bloccare\ne sbloccare\nil telefono, ma\nassicurati di\nattendere alcuni\nsecondi tra il\nblocco e lo\nsblocco.\n"RISATA MALEFICA"');

                                  children.addAll(makeChildrenSection('Mod.\nhardcore', '"Grrrrr"', otherText, false));

                                  var args = WIPDialogArguments(
                                    children: children,
                                    dialogHeight: 600,
                                    popUntilRoot: false
                                  );

                                  return WIPDialog(args: args);

                                });

                              }
                            )
                          )
                        )
                      ],
                    )
                  ),
                  const Text(
                    'Scegli avatar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'PressStart2P',
                        fontSize: 22
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                          onTapDown: (_){
                            setSxButtonPath('avatar_sx_arrow_pressed.png');
                          },
                          onPanDown: (_){
                            setSxButtonPath('avatar_sx_arrow_pressed.png');
                          },
                          onTapCancel: (){
                            setSxButtonPath('avatar_sx_arrow.png');
                          },
                          onPanEnd: (_){
                            setSxButtonPath('avatar_sx_arrow.png');
                          },
                          child: IconButton(
                              padding: const EdgeInsets.only(right: 30),
                              icon: Image.asset(sxButtonPath),
                              iconSize: 50,
                              onPressed: () {
                                setSxButtonPath('avatar_sx_arrow.png');
                                sxButtonAction();
                              }
                          )
                      ),
                      SizedBox(
                          height: 100,
                          width: 60,
                          child: FittedBox(
                              fit: BoxFit.cover,
                              child: Image.asset(avatarImage),
                          )
                      ),
                      GestureDetector(
                          onTapDown: (_){
                            setDxButtonPath('avatar_dx_arrow_pressed.png');
                          },
                          onPanDown: (_){
                            setDxButtonPath('avatar_dx_arrow_pressed.png');
                          },
                          onTapCancel: (){
                            setDxButtonPath('avatar_dx_arrow.png');
                          },
                          onPanEnd: (_){
                            setDxButtonPath('avatar_dx_arrow.png');
                          },
                        child: IconButton(
                            padding: const EdgeInsets.only(left: 30),
                            icon: Image.asset(dxButtonPath),
                            iconSize: 50,
                            onPressed: () {
                              setDxButtonPath('avatar_dx_arrow.png');
                              dxButtonAction();
                            }
                        )
                      )
                    ],
                  ),
                  GestureDetector(
                      onTapDown: (_){
                        setStartStoryButtonPath('start_story_button_pressed.png');
                      },
                      onPanDown: (_){
                        setStartStoryButtonPath('start_story_button_pressed.png');
                      },
                      onTapCancel: (){
                        setStartStoryButtonPath('start_story_button.png');
                      },
                      onPanEnd: (_){
                        setStartStoryButtonPath('start_story_button.png');
                      },
                    onTap: () {

                      setStartStoryButtonPath('start_story_button.png');

                      String mode = '';

                      if(_hardcoreMode) {
                        mode = 'hardcore';
                      } else if(_silentMode) {
                        mode = 'silent';
                      } else {
                        mode = 'none';
                      }

                      if(storyTitle != '') {
                        Navigator.pushNamed(
                            context,
                            '/story-started',
                            arguments: StoryStartedArguments(
                              storyTitle: storyTitle,
                              studyTime: _studyTime!.toInt(),
                              breakTime: _breakTime!.toInt(),
                              selectedAvatar: shoppedAvatarNames[avatarTag],
                              backgroundNames: shoppedBackgroundNames,
                              mode: mode
                            )
                        );
                      } else {
                        Fluttertoast.showToast(
                            msg: 'Inserire il titolo della storia',
                            toastLength: Toast.LENGTH_LONG,
                            gravity: ToastGravity.BOTTOM,
                            timeInSecForIosWeb: 1,
                            backgroundColor: Colors.white,
                            textColor: const Color.fromARGB(255, 2, 119, 189),
                            fontSize: 16
                        );
                      }
                    },
                    child: Image.asset(startStoryButtonPath)
                  )

                ]
              ),
            ),
          ),
      resizeToAvoidBottomInset: false,
    );
  }
}