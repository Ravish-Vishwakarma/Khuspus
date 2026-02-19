// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:khuspus/Pages/memory.dart';
import 'package:khuspus/Pages/setting.dart';
import 'package:khuspus/Pages/user.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            CustomNavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              items: const [
                CustomRailItem(
                  icon: Icons.person_outline_rounded,
                  label: 'User',
                ),
                CustomRailItem(icon: Icons.window_rounded, label: 'Memory'),
                CustomRailItem(icon: Icons.settings_outlined, label: 'Third'),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: Column(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onPanStart: (_) {
                      WindowManagerPlus.current.startDragging();
                    },
                    child: Container(
                      width: double.infinity,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey, width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                _selectedIndex == 0
                                    ? "User"
                                    : _selectedIndex == 1
                                    ? "Memory"
                                    : "Setting",
                              ),
                            ),
                          ),
                          Text(
                            "Khuspus",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  onPressed: () async {
                                    final url = Uri.parse(
                                      'https://ravishvish.gumroad.com/coffee',
                                    );
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(
                                        url,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    }
                                  },
                                  tooltip: "Support",
                                  icon: Icon(
                                    Icons.favorite_rounded,
                                    color: Colors.pink[100],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(0, 5, 0, 5),
                                  child: VerticalDivider(),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    // border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          tooltip: "Minimize",
                                          onPressed: () async {
                                            await WindowManagerPlus.current
                                                .minimize();
                                          },
                                          icon: Icon(Icons.minimize_rounded),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          iconSize: 25,
                                        ),
                                        SizedBox(width: 5),
                                        IconButton(
                                          tooltip: "Maximize",
                                          onPressed: () async {
                                            if (await WindowManagerPlus.current
                                                .isMaximized()) {
                                              await WindowManagerPlus.current
                                                  .restore();
                                            } else {
                                              await WindowManagerPlus.current
                                                  .maximize();
                                            }
                                          },
                                          icon: Icon(
                                            Icons
                                                .check_box_outline_blank_rounded,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          iconSize: 25,
                                        ),
                                        SizedBox(width: 5),

                                        IconButton(
                                          tooltip: "Close",
                                          onPressed: () async {
                                            await WindowManagerPlus.current
                                                .close();
                                          },
                                          icon: Icon(Icons.close_rounded),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          iconSize: 25,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(width: 5),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: _selectedIndex == 0
                        ? UserPage()
                        : _selectedIndex == 1
                        ? MemoryPage()
                        : SettingPage(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomRailItem {
  final IconData icon;
  final String label;

  const CustomRailItem({required this.icon, required this.label});
}

class CustomNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<CustomRailItem> items;

  const CustomNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 48,
      child: Column(
        children: [
          const SizedBox(height: 8),
          for (int i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  splashColor: colorScheme.primary.withOpacity(0.12),
                  onTap: () => onDestinationSelected(i),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: i == selectedIndex
                          ? colorScheme.primary.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      items[i].icon,
                      size: 20,
                      color: i == selectedIndex
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
