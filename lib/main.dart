import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'cubits/index.dart';
import 'repositories/index.dart';
import 'services/index.dart';
import 'util/index.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HydratedCubit.storage = await HydratedStorage.build();
  Bloc.observer = CherryBlocObserver();

  final httpClient = Dio();
  final motificationsCubit = NotificationsCubit(
    FlutterLocalNotificationsPlugin(),
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        'channel.launches',
        'Launches notifications',
        'Stay up-to-date with upcoming SpaceX launches',
        importance: Importance.high,
      ),
      iOS: IOSNotificationDetails(),
    ),
    initializationSettings: InitializationSettings(
      android: AndroidInitializationSettings('notification_launch'),
      iOS: IOSInitializationSettings(),
    ),
  );
  await motificationsCubit.init();

  runApp(CherryApp(
    notificationsCubit: motificationsCubit,
    vehiclesRepository: VehiclesRepository(
      VehiclesService(httpClient),
    ),
    launchesRepository: LaunchesRepository(
      LaunchesService(httpClient),
    ),
    achievementsRepository: AchievementsRepository(
      AchievementsService(httpClient),
    ),
    companyRepository: CompanyRepository(
      CompanyService(httpClient),
    ),
    changelogRepository: ChangelogRepository(
      ChangelogService(httpClient),
    ),
  ));
}

/// Builds the neccesary cubits, as well as the home page.
class CherryApp extends StatelessWidget {
  final NotificationsCubit notificationsCubit;
  final VehiclesRepository vehiclesRepository;
  final LaunchesRepository launchesRepository;
  final AchievementsRepository achievementsRepository;
  final CompanyRepository companyRepository;
  final ChangelogRepository changelogRepository;

  const CherryApp({
    this.notificationsCubit,
    this.vehiclesRepository,
    this.launchesRepository,
    this.achievementsRepository,
    this.companyRepository,
    this.changelogRepository,
  });

  /// Calls the `NotificationsCubit` to update the scheduled notifications
  /// necessary
  static void scheduleLaunchNotification(BuildContext context) =>
      context.watch<NotificationsCubit>().updateNotifications(
            context,
            nextLaunch: LaunchUtils.getUpcomingLaunch(
              context.watch<LaunchesCubit>().state.value,
            ),
          );

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => ImageQualityCubit()),
        BlocProvider(create: (_) => notificationsCubit),
        BlocProvider(create: (_) => VehiclesCubit(vehiclesRepository)),
        BlocProvider(create: (_) => LaunchesCubit(launchesRepository)),
        BlocProvider(create: (_) => AchievementsCubit(achievementsRepository)),
        BlocProvider(create: (_) => CompanyCubit(companyRepository)),
        BlocProvider(create: (_) => ChangelogCubit(changelogRepository)),
      ],
      child: BlocConsumer<ThemeCubit, ThemeState>(
        listener: (context, state) => null,
        builder: (context, state) {
          scheduleLaunchNotification(context);
          return MaterialApp(
            title: 'SpaceX GO!',
            theme: context.watch<ThemeCubit>().lightTheme,
            darkTheme: context.watch<ThemeCubit>().darkTheme,
            themeMode: context.watch<ThemeCubit>().themeMode,
            onGenerateRoute: Routes.generateRoute,
            onUnknownRoute: Routes.errorRoute,
            localizationsDelegates: [
              FlutterI18nDelegate(
                translationLoader: FileTranslationLoader(),
              )..load(null),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate
            ],
          );
        },
      ),
    );
  }
}
