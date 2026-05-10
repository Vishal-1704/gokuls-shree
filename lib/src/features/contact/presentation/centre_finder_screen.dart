import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_spacing.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';

class CentreFinderScreen extends ConsumerStatefulWidget {
  const CentreFinderScreen({super.key});

  @override
  ConsumerState<CentreFinderScreen> createState() => _CentreFinderScreenState();
}

class _CentreFinderScreenState extends ConsumerState<CentreFinderScreen> {
  final _searchController = TextEditingController();
  final _districtController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();
    final district = _districtController.text.trim();

    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        title: Text(
          'Centre Finder',
          style: AppTypography.headingMd.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search by centre name or code',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _districtController,
                  decoration: const InputDecoration(
                    labelText: 'Filter by district',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: ref
                  .read(supabaseServiceProvider)
                  .findBranches(search: query, district: district),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.goldCta),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Failed to load centres: ${snapshot.error}',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.danger,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final centres = snapshot.data ?? const <Map<String, dynamic>>[];
                if (centres.isEmpty) {
                  return Center(
                    child: Text(
                      'No centres found for your search.',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    0,
                    AppSpacing.screenPadding,
                    AppSpacing.screenPadding,
                  ),
                  itemCount: centres.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final c = centres[index];
                    final name = (c['name'] ?? 'Unnamed Centre').toString();
                    final code = (c['code'] ?? 'N/A').toString();
                    final districtValue = (c['district'] ?? 'N/A').toString();
                    final mobile = (c['mobile'] ?? 'Not available').toString();
                    final address = (c['address'] ?? 'Address not available')
                        .toString();

                    return Container(
                      padding: const EdgeInsets.all(AppSpacing.cardPadding),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: AppTypography.headingSm.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.inkNavy700,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusSm,
                                  ),
                                ),
                                child: Text(
                                  code,
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.goldCta,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'District: $districtValue',
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            address,
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mobile: $mobile',
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
