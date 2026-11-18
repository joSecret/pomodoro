import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

class NavItem {
  const NavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

/// Draws mock window buttons in design previews (web build). On real macOS
/// the native buttons sit in the same spot.
const previewChrome = bool.fromEnvironment('PREVIEW_CHROME');

/// Space to leave at the top-left for the native macOS window buttons.
bool get reserveTrafficLights =>
    previewChrome || (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS);

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelect,
    required this.collapsed,
    required this.onToggle,
  });

  final List<NavItem> items;
  final int selected;
  final ValueChanged<int> onSelect;
  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final toggle = IconButton(
      tooltip: collapsed ? 'Show sidebar' : 'Hide sidebar',
      onPressed: onToggle,
      icon: const Icon(Icons.view_sidebar_outlined),
      color: AppColors.textSecondary,
      iconSize: 22,
    );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: collapsed ? 84 : 250,
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A2456), Color(0xFF1E1C33), Color(0xFF1C2140)],
        ),
        border: Border.all(color: const Color(0x557A6CF0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 52,
            child: Row(children: [
              if (previewChrome) const _MockTrafficLights(),
              const Spacer(),
              if (!collapsed) toggle,
              if (!collapsed) const SizedBox(width: 6),
            ]),
          ),
          if (collapsed) Center(child: toggle),
          const SizedBox(height: 16),
          for (var i = 0; i < items.length; i++)
            _NavTile(
              item: items[i],
              active: i == selected,
              collapsed: collapsed,
              onTap: () => onSelect(i),
            ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.active,
    required this.collapsed,
    required this.onTap,
  });
  final NavItem item;
  final bool active;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tile = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 14),
          decoration: BoxDecoration(
            color: active ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment:
                collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(item.icon,
                  size: 24,
                  color: active ? Colors.white : AppColors.textPrimary),
              if (!collapsed) ...[
                const SizedBox(width: 14),
                Flexible(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return collapsed ? Tooltip(message: item.label, child: tile) : tile;
  }
}

class _MockTrafficLights extends StatelessWidget {
  const _MockTrafficLights();

  @override
  Widget build(BuildContext context) {
    Widget dot(Color c) => Container(
          width: 13,
          height: 13,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        );
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Row(children: [
        dot(const Color(0xFFFF5F57)),
        dot(const Color(0xFFFEBC2E)),
        dot(const Color(0xFF28C840)),
      ]),
    );
  }
}
