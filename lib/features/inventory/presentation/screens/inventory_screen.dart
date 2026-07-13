import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Catégories d'objets cosmétiques personnalisables.
enum CosmeticCategory { darts, boards, backgrounds, avatars, profileFrames }

class CosmeticItem {
  final String id;
  final String name;
  final bool isUnlocked;
  final bool isEquipped;

  const CosmeticItem({
    required this.id,
    required this.name,
    required this.isUnlocked,
    required this.isEquipped,
  });
}

/// Écran d'inventaire : permet d'équiper les fléchettes, cibles,
/// arrière-plans, avatars et cadres de profil débloqués.
class InventoryScreen extends StatefulWidget {
  final Map<CosmeticCategory, List<CosmeticItem>> itemsByCategory;
  final void Function(CosmeticCategory category, CosmeticItem item) onEquip;

  const InventoryScreen({super.key, required this.itemsByCategory, required this.onEquip});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _categoryLabels = {
    CosmeticCategory.darts: 'Fléchettes',
    CosmeticCategory.boards: 'Cibles',
    CosmeticCategory.backgrounds: 'Arrière-plans',
    CosmeticCategory.avatars: 'Avatars',
    CosmeticCategory.profileFrames: 'Cadres',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: CosmeticCategory.values.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightBlue,
      appBar: AppBar(
        title: const Text('Inventaire'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.lightGray,
          tabs: CosmeticCategory.values.map((c) => Tab(text: _categoryLabels[c])).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: CosmeticCategory.values.map((category) {
          final items = widget.itemsByCategory[category] ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Text('Aucun objet dans cette catégorie', style: TextStyle(color: AppColors.lightGray)),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _CosmeticCard(
                item: item,
                onTap: item.isUnlocked ? () => widget.onEquip(category, item) : null,
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

class _CosmeticCard extends StatelessWidget {
  final CosmeticItem item;
  final VoidCallback? onTap;
  const _CosmeticCard({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: item.isEquipped ? AppColors.electricBlue.withOpacity(0.25) : AppColors.darkSurface,
          borderRadius: BorderRadius.circular(16),
          border: item.isEquipped ? Border.all(color: AppColors.electricBlue, width: 2) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.isUnlocked ? Icons.style : Icons.lock,
              color: item.isUnlocked ? AppColors.gold : AppColors.lightGray,
              size: 32,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                item.name,
                textAlign: TextAlign.center,
                style: TextStyle(color: item.isUnlocked ? AppColors.white : AppColors.lightGray, fontSize: 12),
              ),
            ),
            if (item.isEquipped)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('Équipé', style: TextStyle(color: AppColors.electricBlue, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      ),
    );
  }
}
