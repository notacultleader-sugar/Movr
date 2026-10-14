import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/mock_data.dart';
import '../models/move.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/live_trucks.dart';
import '../widgets/movr_map.dart';
import 'driver/driver_home_screen.dart';
import 'plan_move_sheet.dart';
import 'quote_screen.dart';

/// Stage 1: The Request. Full-screen live map, floating search bar and
/// three quick actions. The goal is speed.
class RequestScreen extends StatelessWidget {
  const RequestScreen({super.key});

  Future<void> _plan(
    BuildContext context, {
    Place? pickup,
    Place? dropoff,
    List<MoveItem> items = const [],
  }) async {
    final plan = await showPlanMoveSheet(
      context,
      pickup: pickup,
      dropoff: dropoff,
      items: items,
    );
    if (plan == null || !context.mounted) return;
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => QuoteScreen(plan: plan)));
  }

  Future<void> _marketplace(BuildContext context) async {
    final listing = await showModalBottomSheet<MarketplaceListing>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _MarketplaceSheet(),
    );
    if (listing != null && context.mounted) {
      _plan(context, pickup: listing.place, items: [listing.item]);
    }
  }

  Future<void> _store(BuildContext context) async {
    final store = await showModalBottomSheet<PartnerStore>(
      context: context,
      builder: (_) => const _StoreSheet(),
    );
    if (store != null && context.mounted) _plan(context, pickup: store.place);
  }

  void _profile(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.credit_card),
                title: Text('Visa ****4242'),
                subtitle: Text('Payment method'),
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.receipt_long_outlined),
                title: Text('3 past moves'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.local_shipping),
                label: const Text('Switch to driver mode'),
                onPressed: () {
                  Navigator.pop(sheet);
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
                    (_) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: MovrMap(
              fit: [
                currentLocation.pos,
                const LatLng(48.7930, -123.7230),
                const LatLng(48.7660, -123.6930),
              ],
              padding: const EdgeInsets.only(top: 120, bottom: 220),
              layers: [
                const LiveTrucksLayer(),
                MarkerLayer(
                  markers: [
                    mapMarker(
                      currentLocation.pos,
                      const _YouAreHere(),
                      size: 26,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: MovrColors.surface,
                          borderRadius: kBorderRadius,
                          boxShadow: kFloatingShadow,
                        ),
                        child: const MovrLogo(height: 26),
                      ),
                      const Spacer(),
                      Material(
                        color: MovrColors.surface,
                        shape: const CircleBorder(),
                        elevation: 4,
                        shadowColor: Colors.black26,
                        child: IconButton(
                          tooltip: 'Profile',
                          icon: const Icon(Icons.person_outline),
                          onPressed: () => _profile(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: MovrColors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 4,
                            backgroundColor: MovrColors.orange,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '$liveTruckCount trucks nearby · 4 min away',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _QuickAction(
                        icon: Icons.history,
                        label: 'Recent',
                        onTap: () => _plan(context, dropoff: recentDropoff),
                      ),
                      _QuickAction(
                        icon: Icons.storefront_outlined,
                        label: 'Marketplace',
                        onTap: () => _marketplace(context),
                      ),
                      _QuickAction(
                        icon: Icons.local_mall_outlined,
                        label: 'Store',
                        onTap: () => _store(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Material(
                    color: MovrColors.surface,
                    borderRadius: kBorderRadius,
                    elevation: 8,
                    shadowColor: Colors.black26,
                    child: InkWell(
                      borderRadius: kBorderRadius,
                      onTap: () => _plan(context),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 20,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search,
                              color: MovrColors.orange,
                              size: 26,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Where are we moving to?',
                              style: TextStyle(
                                fontFamily: kHeadingFont,
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _YouAreHere extends StatelessWidget {
  const _YouAreHere();
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: MovrColors.orange.withValues(alpha: 0.25),
      shape: BoxShape.circle,
    ),
    alignment: Alignment.center,
    child: Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: MovrColors.orange,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
      ),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: MovrColors.surface,
              shape: BoxShape.circle,
              boxShadow: kFloatingShadow,
            ),
            child: Icon(icon, color: MovrColors.black, size: 26),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: MovrColors.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketplaceSheet extends StatelessWidget {
  const _MarketplaceSheet();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pick up a Marketplace find', style: text.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Paste a Facebook Marketplace or Craigslist link and we fill in the pickup.',
              style: text.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Paste listing link',
                prefixIcon: Icon(Icons.link),
              ),
              onSubmitted: (_) =>
                  Navigator.pop(context, marketplaceListings.first),
            ),
            const SizedBox(height: 16),
            Text('Saved listings', style: text.titleLarge),
            const SizedBox(height: 8),
            for (final l in marketplaceListings)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: MovrColors.orangeTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(l.item.icon, color: MovrColors.orange),
                ),
                title: Text(l.title, style: text.titleMedium),
                subtitle: Text('${l.source} · ${l.price} · ${l.place.address}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(context, l),
              ),
          ],
        ),
      ),
    );
  }
}

class _StoreSheet extends StatelessWidget {
  const _StoreSheet();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Partner stores', style: text.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Bought something big? We\'ll meet you at the counter.',
              style: text.bodySmall,
            ),
            const SizedBox(height: 12),
            for (final s in partnerStores)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: MovrColors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.storefront, color: Colors.white),
                ),
                title: Text(s.place.name, style: text.titleMedium),
                subtitle: Text('${s.place.address} · ${s.blurb}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(context, s),
              ),
          ],
        ),
      ),
    );
  }
}
