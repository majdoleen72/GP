
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'rider_backdrop.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.form,
    required this.switchPrompt,
    required this.switchAction,
    required this.onSwitch,
  });

  final String title;
  final String subtitle;
  final Widget form;
  final String switchPrompt;
  final String switchAction;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    final keyboardVisible =
        MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const RiderBackdrop(auth: true),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final height = constraints.maxHeight;
                final width = constraints.maxWidth;

                final compact =
                    height < 690 || keyboardVisible;

                final horizontalPadding =
                    width < 360 ? 18.0 : 22.0;

                final topPadding =
                    compact ? 8.0 : 14.0;

                final bottomPadding =
                    keyboardVisible ? 24.0 : 14.0;

                final minContentHeight = math.max(
                  0.0,
                  height - topPadding - bottomPadding,
                );

                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    topPadding,
                    horizontalPadding,
                    bottomPadding,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: minContentHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Material(
                            color: Colors.white.withValues(
                              alpha: 0.10,
                            ),
                            borderRadius:
                                BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius:
                                  BorderRadius.circular(14),
                              onTap: () =>
                                  Navigator.of(context).pop(),
                              child: const SizedBox(
                                width: 44,
                                height: 44,
                                child: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: RSColors.white,
                                  size: 19,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(
                            height: compact ? 18 : 30,
                          ),

                          Text(
                            title.replaceAll('\n', ' '),
                            maxLines: 2,
                            style: TextStyle(
                              fontSize: width < 360 ? 29 : 33,
                              height: 1.1,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1.1,
                              color: RSColors.white,
                            ),
                          ),

                          const SizedBox(height: 9),

                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: Color(0xFFD7E4F1),
                              fontSize: 13,
                              height: 1.45,
                              fontWeight: FontWeight.w400,
                            ),
                          ),

                          const Spacer(),

                          SizedBox(
                            height: compact ? 18 : 26,
                          ),

                          form,

                          if (!keyboardVisible) ...[
                            const SizedBox(height: 12),

                            Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment:
                                    WrapCrossAlignment.center,
                                spacing: 0,
                                children: [
                                  Text(
                                    switchPrompt,
                                    style: const TextStyle(
                                      color: RSColors.muted,
                                      fontSize: 12.5,
                                    ),
                                  ),

                                  TextButton(
                                    style: TextButton.styleFrom(
                                      minimumSize:
                                          const Size(50, 44),
                                      tapTargetSize:
                                          MaterialTapTargetSize.padded,
                                      padding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 7,
                                      ),
                                    ),
                                    onPressed: onSwitch,
                                    child: Text(
                                      switchAction,
                                      style: const TextStyle(
                                        color: RSColors.accent,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
