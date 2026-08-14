import 'package:cached_network_image/cached_network_image.dart';
import 'package:eSellify/app/models/user_model.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/common_ui.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../routes/app_pages.dart';

enum FollowListMode { followers, following }

class FollowListView extends StatefulWidget {
  final String uid;
  final FollowListMode mode;

  const FollowListView({super.key, required this.uid, required this.mode});

  @override
  State<FollowListView> createState() => _FollowListViewState();
}

class _FollowListViewState extends State<FollowListView> {
  List<UserModel>? _users;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = widget.mode == FollowListMode.followers ? await FireStoreUtils.getFollowers(widget.uid) : await FireStoreUtils.getFollowing(widget.uid);
    if (!mounted) return;
    setState(() => _users = list);
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();
    final isFollowers = widget.mode == FollowListMode.followers;
    final title = isFollowers ? 'Followers'.tr : 'Following'.tr;

    return Scaffold(
      backgroundColor: isDark ? AppThemeData.grey10 : AppThemeData.grey1,
      appBar: UiInterface.customAppBar(context, themeChange, isBack: true, title),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppThemeData.primary4,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(isDark, isFollowers)),
            if (_users == null)
              SliverFillRemaining(hasScrollBody: false, child: _buildSkeleton(isDark))
            else if (_users!.isEmpty)
              SliverFillRemaining(hasScrollBody: false, child: _buildEmpty(isDark, isFollowers))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                sliver: SliverToBoxAdapter(child: _buildListCard(isDark)),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Header banner ──────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark, bool isFollowers) {
    final count = _users?.length ?? 0;
    final accent = AppThemeData.primary4;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [accent.withValues(alpha: 0.14), accent.withValues(alpha: 0.04)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.18), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(isFollowers ? Icons.people_alt_rounded : Icons.person_add_alt_1_rounded, color: accent, size: 22),
          ),
          spaceW(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextCustom(
                  title: _users == null ? (isFollowers ? 'Followers'.tr : 'Following'.tr) : '$count ${_pluralLabel(count, isFollowers)}',
                  fontSize: 16,
                  fontFamily: FontFamily.bold,
                  color: isDark ? AppThemeData.grey1 : AppThemeData.grey10,
                ),
                spaceH(height: 2),
                TextCustom(
                  title: isFollowers ? 'People who follow this account'.tr : 'People this account follows'.tr,
                  fontSize: 12,
                  color: isDark ? AppThemeData.grey4 : AppThemeData.grey6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _pluralLabel(int count, bool isFollowers) {
    if (isFollowers) return count == 1 ? 'Follower'.tr : 'Followers'.tr;
    return 'Following'.tr;
  }

  // ─── List card (rounded container with internal dividers) ───────────────
  Widget _buildListCard(bool isDark) {
    final divider = isDark ? AppThemeData.grey8 : AppThemeData.grey2;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppThemeData.grey9 : AppThemeData.grey2, width: 0.8),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _users!.length,
        separatorBuilder: (_, _) => Padding(
          padding: const EdgeInsets.only(left: 72),
          child: Divider(height: 1, thickness: 0.6, color: divider),
        ),
        itemBuilder: (_, i) => _buildUserRow(_users![i], isDark),
      ),
    );
  }

  Widget _buildUserRow(UserModel user, bool isDark) {
    final pic = user.profilePic ?? '';
    return InkWell(
      onTap: (user.id == null || user.id!.isEmpty) ? null : () => Get.toNamed(Routes.SELLER_PROFILE, arguments: {'sellerId': user.id, 'sellerName': user.fullNameString()}),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Avatar with subtle ring
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppThemeData.primary4.withValues(alpha: 0.25), width: 1.2),
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: isDark ? AppThemeData.grey8 : AppThemeData.grey2,
                backgroundImage: pic.isNotEmpty ? CachedNetworkImageProvider(pic) : null,
                child: pic.isEmpty ? Icon(Icons.person, color: AppThemeData.grey5, size: 22) : null,
              ),
            ),
            spaceW(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextCustom(title: user.fullNameString(), fontSize: 15, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10, maxLine: 1),
                  if ((user.email ?? '').isNotEmpty) ...[
                    spaceH(height: 3),
                    TextCustom(title: user.email!, fontSize: 12, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6, maxLine: 1),
                  ],
                ],
              ),
            ),
            spaceW(width: 8),
            if ((user.id ?? '').isNotEmpty)
              widget.mode == FollowListMode.followers
                  ? _FollowerActions(targetUid: user.id!, onRemoved: () => _removeUserLocally(user.id!))
                  : _UnfollowButton(targetUid: user.id!, onUnfollowed: () => _removeUserLocally(user.id!)),
          ],
        ),
      ),
    );
  }

  void _removeUserLocally(String uid) {
    if (_users == null) return;
    setState(() => _users = _users!.where((u) => u.id != uid).toList());
  }

  // ─── Empty state ────────────────────────────────────────────────────────
  Widget _buildEmpty(bool isDark, bool isFollowers) {
    final title = isFollowers ? 'No followers yet'.tr : 'Not following anyone yet'.tr;
    final subtitle = isFollowers ? "When someone follows this account, they'll show up here.".tr : 'Discover sellers and follow them to see updates here.'.tr;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppThemeData.primary4.withValues(alpha: 0.1)),
            child: Icon(isFollowers ? Icons.people_outline_rounded : Icons.person_search_rounded, size: 44, color: AppThemeData.primary4),
          ),
          spaceH(height: 18),
          TextCustom(title: title, fontSize: 17, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
          spaceH(height: 8),
          TextCustom(title: subtitle, fontSize: 13, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6),
        ],
      ),
    );
  }

  // ─── Skeleton placeholders during load ──────────────────────────────────
  Widget _buildSkeleton(bool isDark) {
    final bg = isDark ? AppThemeData.grey9 : AppThemeData.grey2;
    final highlight = isDark ? AppThemeData.grey8 : AppThemeData.grey1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppThemeData.grey9 : AppThemeData.grey2, width: 0.8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: List.generate(6, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
                  ),
                  spaceW(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 12,
                          width: 140,
                          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
                        ),
                        spaceH(height: 8),
                        Container(
                          height: 10,
                          width: 100,
                          decoration: BoxDecoration(color: highlight, borderRadius: BorderRadius.circular(4)),
                        ),
                      ],
                    ),
                  ),
                  spaceW(width: 12),
                  Container(
                    height: 28,
                    width: 92,
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─── Action: Unfollow (Following list) ───────────────────────────────────────
class _UnfollowButton extends StatefulWidget {
  final String targetUid;
  final VoidCallback onUnfollowed;

  const _UnfollowButton({required this.targetUid, required this.onUnfollowed});

  @override
  State<_UnfollowButton> createState() => _UnfollowButtonState();
}

class _UnfollowButtonState extends State<_UnfollowButton> {
  bool _busy = false;

  Future<void> _onTap() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await FireStoreUtils.unfollowUser(widget.targetUid);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) widget.onUnfollowed();
  }

  @override
  Widget build(BuildContext context) {
    return _ActionPill(label: 'Unfollow'.tr, icon: Icons.person_remove_alt_1_outlined, filled: false, busy: _busy, onTap: _onTap);
  }
}

// ─── Actions: Follow Back + Remove (Followers list) ──────────────────────────
class _FollowerActions extends StatefulWidget {
  final String targetUid;
  final VoidCallback onRemoved;

  const _FollowerActions({required this.targetUid, required this.onRemoved});

  @override
  State<_FollowerActions> createState() => _FollowerActionsState();
}

class _FollowerActionsState extends State<_FollowerActions> {
  bool? _isFollowing; // null while loading
  bool _followBusy = false;
  bool _removeBusy = false;

  @override
  void initState() {
    super.initState();
    _loadIsFollowing();
  }

  Future<void> _loadIsFollowing() async {
    final v = await FireStoreUtils.isFollowing(widget.targetUid);
    if (!mounted) return;
    setState(() => _isFollowing = v);
  }

  Future<void> _toggleFollow() async {
    if (_followBusy || _isFollowing == null) return;
    setState(() => _followBusy = true);
    final next = !_isFollowing!;
    setState(() => _isFollowing = next);
    final ok = next ? await FireStoreUtils.followUser(widget.targetUid) : await FireStoreUtils.unfollowUser(widget.targetUid);
    if (!mounted) return;
    setState(() {
      _followBusy = false;
      if (!ok) _isFollowing = !next;
    });
  }

  Future<void> _remove() async {
    if (_removeBusy) return;
    setState(() => _removeBusy = true);
    final ok = await FireStoreUtils.removeFollower(widget.targetUid);
    if (!mounted) return;
    setState(() => _removeBusy = false);
    if (ok) widget.onRemoved();
  }

  @override
  Widget build(BuildContext context) {
    final following = _isFollowing;
    if (following == null) {
      return const SizedBox(
        width: 28,
        height: 28,
        child: Center(child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.6))),
      );
    }
    // Mutually exclusive: Follow Back when not following, Remove once following.
    return following
        ? _ActionPill(label: 'Remove'.tr, icon: Icons.close_rounded, filled: false, danger: true, busy: _removeBusy, onTap: _remove)
        : _ActionPill(label: 'Follow Back'.tr, icon: Icons.person_add_alt_1, filled: true, busy: _followBusy, onTap: _toggleFollow);
  }
}

// ─── Reusable pill button used by the row actions ────────────────────────────
class _ActionPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final bool busy;
  final bool danger;
  final VoidCallback onTap;

  const _ActionPill({required this.label, required this.icon, required this.filled, required this.busy, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final accent = danger ? AppThemeData.danger300 : AppThemeData.primary4;
    final fg = filled ? Colors.white : accent;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: busy ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: filled ? accent : Colors.transparent,
          border: Border.all(color: accent, width: 1.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy)
              SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.6, valueColor: AlwaysStoppedAnimation(fg)))
            else
              Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontFamily: FontFamily.bold, color: fg),
            ),
          ],
        ),
      ),
    );
  }
}
