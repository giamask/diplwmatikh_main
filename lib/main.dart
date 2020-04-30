import 'dart:io';
import 'dart:ui';
import 'package:bloc/bloc.dart';
import 'package:diplwmatikh_map_test/ObjectView.dart';
import 'package:diplwmatikh_map_test/bloc/AnimatorEvent.dart';
import 'package:diplwmatikh_map_test/bloc/InitEvent.dart';
import 'package:diplwmatikh_map_test/bloc/ObjDisplayEvent.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:diplwmatikh_map_test/CustomFloatingButton.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'KeyList.dart';
import 'package:qrscan/qrscan.dart' as scanner;
import 'PopUp.dart';
import 'package:diplwmatikh_map_test/bloc/InitBloc.dart';
import 'bloc/AnimatorBloc.dart';
import 'bloc/DialogState.dart';
import 'bloc/InitState.dart';
import 'bloc/ObjDisplayBloc.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Google Maps Demo',
        theme: Theme.of(context).copyWith(accentColor: Colors.black),
        home: MultiBlocProvider(providers: [
          BlocProvider<InitBloc>(
            create: (BuildContext context) => InitBloc(),
          ),
          BlocProvider<AnimatorBloc>(
            create: (BuildContext context) => AnimatorBloc(),
          ),
          BlocProvider<ObjDisplayBloc>(
            create: (BuildContext context) => ObjDisplayBloc(),
          )
        ], child: MainWidget()));
  }
}

class MainWidget extends StatefulWidget {
  @override
  State<MainWidget> createState() => MainWidgetState();
}

class MainWidgetState extends State<MainWidget> with TickerProviderStateMixin {
  static Completer cameraIdle;
  static final CameraPosition _kGooglePlex = CameraPosition(
    //target: LatLng(37.745174, 23.427974),
    target: LatLng(39.353284, 21.0),
    zoom: 13.7746,
  );

  static final latLngBounds = LatLngBounds(
      //northeast: LatLng(37.771908, 23.464144),
      //southwest: LatLng(37.727996, 23.415847)),
      northeast: LatLng(39.653284, 21.243507),
      southwest: LatLng(39.201644, 20.8584));

  bool cfbm_opening = false;
  bool cfbm_open = false;
  Animation shrinkExpandAnimation;

  @override
  void initState() {
    super.initState();
    BlocProvider.of<AnimatorBloc>(context).animationController =
        AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    shrinkExpandAnimation = Tween(begin: 0.0, end: 0.8)
        .animate(BlocProvider.of<AnimatorBloc>(context).animationController);
  }

  @override
  void dispose(){
    super.dispose();
    BlocProvider.of<AnimatorBloc>(context).animationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: BlocBuilder<InitBloc, InitState>(builder: (context, state) {
      if (state is InitializeInProgress)
        return Builder(builder: (context) {
          BlocProvider.of<InitBloc>(context).add(GameInitialized());
          return Container(child: Center(child: CircularProgressIndicator()));
        });

      return Stack(
        children: <Widget>[
          ObjectView(BlocProvider.of<ObjDisplayBloc>(context)),
          AnimatedBuilder(
              animation:
                  BlocProvider.of<AnimatorBloc>(context).animationController,
              builder: (context, widget) {
                Animation animationController = shrinkExpandAnimation;
                final double ratio = 1 - animationController.value;
                final double doubleRatio =
                     1 - animationController.value * 1.1;
                final double interRatio =
                    animationController.value > 0.55 ? ratio / 0.45 : 1;
                final double doubleInterRatio =
                    animationController.value > 0.55 ? doubleRatio / 0.4 : 1;
                return Stack(
                  children: <Widget>[
                    Transform(
                      alignment: Alignment.lerp(
                          Alignment.centerRight, Alignment.bottomRight, 0.4),
                      transform:
                          Matrix4.diagonal3Values(ratio, doubleRatio, 1.0),
                      child: Opacity(
                        opacity: () {
                          if (animationController.value >= 0.8) {
                            return 0.0;
                          } else if (animationController.value >= 0.6) {
                            return ((0.8 - animationController.value) / 0.2);
                          }
                          return 1.0;
                        }(),
                        child: GoogleMap(
                          onCameraIdle: () => (cameraIdle != null
                              ? cameraIdle.complete()
                              : null),
                          markers: state.props[0],
                          rotateGesturesEnabled: false,
                          tiltGesturesEnabled: false,
                          mapType: MapType.normal,
                          initialCameraPosition: _kGooglePlex,
                          onMapCreated: (GoogleMapController controller) {
                            final Completer<GoogleMapController> _controller =
                                state.props[1];
                            _controller.complete(controller);
                          },
                          myLocationEnabled: true,
                          compassEnabled: false,
                          cameraTargetBounds: CameraTargetBounds(latLngBounds),
                          //hardcoded limits
                          minMaxZoomPreference: MinMaxZoomPreference(10, 30),
                          myLocationButtonEnabled: false,
                        ),
                      ),
                    ),
                    (animationController.value > 0.55)
                        ? Container(
                            child: Transform(
                                alignment: Alignment.centerRight,
                                transform: Matrix4.diagonal3Values(1.3, 2, 1.0),
                                child: Transform(
                                    alignment: Alignment.lerp(
                                        Alignment.centerRight,
                                        Alignment.bottomRight,
                                        0.3),
                                    transform: Matrix4.diagonal3Values(
                                        interRatio, doubleInterRatio, 1.0),
                                    child: Opacity(
                                        opacity: () {
                                          if (animationController.value >=
                                              0.8) {
                                            return 1.0;
                                          } else if (animationController
                                                  .value >= 0.6) {
                                            return (1 -
                                                (0.8 -
                                                        animationController
                                                            .value) /
                                                    0.2);
                                          }
                                          return 0.0;
                                        }(),
                                        child: GestureDetector(
                                          child: Image.asset(
                                            "assets/map_icon.png",
                                            height: 150,
                                          ),
                                          onTap: ()=> BlocProvider.of<AnimatorBloc>(context).add(AnimatorMapExpanded()),
                                        )))),
                            alignment: Alignment.lerp(Alignment.centerRight,
                                Alignment.bottomRight, 0.33),
                          )
                        : Container()
                  ],
                );
              }),
          Positioned(
              top: MediaQuery.of(context).size.height * 0.758,
              child: KeyList()),
          AnimatedPositioned(
            right: 18,
            top: cfbm_opening ? 83 : 43,
            duration: Duration(milliseconds: 160),
            onEnd: () {
              if (cfbm_opening) {
                cfbm_open = true;
                setState(() {});
              }
            },
            child: CustomFloatingButton(
                onTap: () {
                  cfbm_opening = !cfbm_opening;
                  if (cfbm_open) cfbm_open = false;

                  setState(() {});
                },
                icon: Icons.category,
                color: cfbm_open ? Colors.grey[600] : Colors.blue[900],
                size: 40),
          ),
          BlocListener(
              bloc: BlocProvider.of<InitBloc>(context).dialogBloc,
              listener: (context, state) {
                ObjDisplayBloc displayBloc = BlocProvider.of<ObjDisplayBloc>(context);
                AnimatorBloc animatorBloc = BlocProvider.of<AnimatorBloc>(context);
                if (state is Ready) {
                  showGeneralDialog(
                      context: context,
                      barrierLabel: "Label",
                      transitionDuration: Duration(milliseconds: 100),
                      barrierDismissible: true,
                      pageBuilder: (context, anim1, anim2) {
                        return Stack(
                          children: <Widget>[
                            Positioned(
                              top: MediaQuery.of(context).size.height / 2 - 210,
                              left: MediaQuery.of(context).size.width / 2 -
                                  PopUp.WIDTH / 2,
                              child: GestureDetector(
                                  onTapUp: (details) =>
                                      details.localPosition.dy > 130
                                          ? Navigator.of(context).pop()
                                          : null,
                                  child: Container(
                                      height: PopUp.HEIGHT,
                                      width: PopUp.WIDTH,
                                      child: Material(
                                          color: Colors.transparent,
                                          child: PopUp(
                                              3,
                                              state.props[2],
                                              () {
                                                Navigator.of(context).pop();
                                                displayBloc.add(ObjDisplayChanged(id:state.props[0]));
                                                animatorBloc.add(AnimatorMapShrunk());
                                                },
                                              state.props[1],
                                              state.props[4],
                                              state.props[3])))),
                            )
                          ],
                        );
                      });
                }

              },
              child: Container()),
          cfbm_open
              ? Positioned(
                  top: 30,
                  right: 30,
                  child: CustomFloatingButton(
                    onTap:()=> BlocProvider.of<ObjDisplayBloc>(context).add(ObjDisplayChanged(id: "4")),
                      icon: Icons.score, color: Colors.purple[700], size: 50),
                )
              : Container(),
          cfbm_open
              ? Positioned(
                  top: 78,
                  right: 65,
                  child: CustomFloatingButton(
                    onTap: () => BlocProvider.of<AnimatorBloc>(context)
                        .add(AnimatorMapShrunk()),
                    icon: Icons.people,
                    color: Colors.purple[700],
                    size: 50,
                  ),
                )
              : Container(),
          cfbm_open
              ? Positioned(
                  top: 125,
                  right: 30,
                  child: CustomFloatingButton(
                    image: "assets/QRicon.png",
                    color: Colors.purple[700],
                    size: 50,
                    onTap: qrScan,
                  ),
                )
              : Container(),
        ],
      );
    }));
  }

  void qrScan() async {
    String photoScanResult = await scanner.scan();
  }

// Asks permission to use location, returns true if given.
// import 'package:permission_handler/permission_handler.dart';
  /* Future<bool> permissionManager() async {
    Map<PermissionGroup, PermissionStatus> permission =
        await PermissionHandler().requestPermissions([PermissionGroup.locationWhenInUse]);
    if (permission[PermissionGroup.locationWhenInUse]== PermissionStatus.granted){
      return true;
    }
    return false;
  }*/

}
