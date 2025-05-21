import 'package:flutter/material.dart';
import 'package:native_splash_screen/native_splash_screen.dart' as nss;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // // Close splash screen after the first frame renders
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   nss.close(animation: nss.CloseAnimation.fade);
    // });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Native Splash Screen')),
        body: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                runAlignment: WrapAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: MaterialButton(
                      clipBehavior: Clip.antiAlias,
                      padding: const EdgeInsets.all(20),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(7)),
                      ),
                      color: Theme.of(context).colorScheme.primary,
                      textColor: Theme.of(context).colorScheme.onPrimary,
                      child: const Center(
                        child: Text(
                          "Close without animation",
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                      onPressed: () {
                        nss.close(animation: nss.CloseAnimation.none);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: MaterialButton(
                      clipBehavior: Clip.antiAlias,
                      padding: const EdgeInsets.all(20),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(7)),
                      ),
                      color: Theme.of(context).colorScheme.primary,
                      textColor: Theme.of(context).colorScheme.onPrimary,
                      child: const Center(
                        child: Text(
                          "Close with Fading",
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                      onPressed: () {
                        nss.close(animation: nss.CloseAnimation.fade);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: MaterialButton(
                      clipBehavior: Clip.antiAlias,
                      padding: const EdgeInsets.all(20),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(7)),
                      ),
                      color: Theme.of(context).colorScheme.primary,
                      textColor: Theme.of(context).colorScheme.onPrimary,
                      child: const Center(
                        child: Text(
                          "Close with Slide Up Fading",
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                      onPressed: () {
                        nss.close(animation: nss.CloseAnimation.slideUpFade);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: MaterialButton(
                      clipBehavior: Clip.antiAlias,
                      padding: const EdgeInsets.all(20),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(7)),
                      ),
                      color: Theme.of(context).colorScheme.primary,
                      textColor: Theme.of(context).colorScheme.onPrimary,
                      child: const Center(
                        child: Text(
                          "Close with Slide Down Fading",
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                      onPressed: () {
                        nss.close(animation: nss.CloseAnimation.slideDownFade);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
