import 'package:async_executor/async_executor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:user_route_tracking/tracking_route/models/tracked_route.dart';
import 'package:user_route_tracking/tracking_route/utils/messages/error_message.dart';
import 'package:user_route_tracking/tracking_route/utils/messages/loading_message.dart';
import 'package:user_route_tracking/tracking_route/widgets/tracking_manager.dart';
import 'package:user_route_tracking/user_route_tracking.dart';

import '../trufi_configuration.dart';
import '../widgets/map_type_button.dart';
import '../widgets/your_location_button.dart';
import '../widgets/trufi_map.dart';
import '../widgets/trufi_online_map.dart';

class PlanEmptyPage extends StatefulWidget {
  PlanEmptyPage({this.initialPosition, this.onLongPress});

  final LatLng initialPosition;
  final LongPressCallback onLongPress;

  @override
  PlanEmptyPageState createState() => PlanEmptyPageState();
}

class PlanEmptyPageState extends State<PlanEmptyPage>
    with TickerProviderStateMixin {
  final _trufiMapController = TrufiMapController();

  @override
  Widget build(BuildContext context) {
    final cfg = TrufiConfiguration();
    return Stack(children: <Widget>[
      TrufiOnlineMap(
        key: ValueKey("PlanEmptyMap"),
        controller: _trufiMapController,
        onLongPress: widget.onLongPress,
        layerOptionsBuilder: (context) {
          return <LayerOptions>[
            _trufiMapController.yourLocationLayer,
          ];
        },
      ),
      if (cfg.map.satelliteMapTypeEnabled || cfg.map.terrainMapTypeEnabled)
        Positioned(
          top: 16.0,
          right: 16.0,
          child: _buildUpperActionButtons(context),
        ),
      Positioned(
        bottom: 16.0,
        right: 16.0,
        child: _buildLowerActionButtons(context),
      ),
      Positioned(
        bottom: 16.0,
        right: 16.0,
        child: RaisedButton(
          onPressed: () {
            AsyncExecutor(
              loadingMessage: showLoadingMessage,
              errorMessage: showErrorMessage,
            ).run<bool>(
                context: context,
                onExecute: () async {
                  bool baseinit = TrackingManager().currentTrack.value == null;
                  await TrackingManager().startTracking();
                  return baseinit;
                },
                onFinish: (value) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserRouteTracking(
                        trackingOnInit: value,
                        userTrackingUri: Uri(
                          host:
                              "us-central1-usertracking-d3b97.cloudfunctions.net",
                          scheme: "https",
                          path: "/routeNew",
                        ),
                      ),
                    ),
                  );
                });
          },
          child: StreamBuilder<TrackedRoute>(
              stream: TrackingManager().currentTrack,
              builder: (context, snapshot) {
                return Text(snapshot.data != null
                    ? "Continue Tracking"
                    : "Start Tracking");
              }),
        ),
      ),
    ]);
  }

  Widget _buildUpperActionButtons(BuildContext context) {
    return SafeArea(
      child: MapTypeButton(),
    );
  }

  Widget _buildLowerActionButtons(BuildContext context) {
    return SafeArea(
      child: YourLocationButton(onPressed: () {
        _trufiMapController.moveToYourLocation(
          context: context,
          tickerProvider: this,
        );
      }),
    );
  }
}
