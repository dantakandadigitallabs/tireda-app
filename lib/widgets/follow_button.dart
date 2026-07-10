import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Compact pill button that toggles follow/unfollow for [targetUid].
/// Renders nothing when there's no signed-in user or when targetUid is the
/// current user.
class FollowButton extends StatefulWidget {
  final String targetUid;

  /// Optional compact mode for placement on dense cards.
  final bool dense;

  /// Called after a successful follow/unfollow with the new state.
  final ValueChanged<bool>? onChanged;

  const FollowButton({super.key, required this.targetUid, this.dense = false, this.onChanged});

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  bool? _following;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant FollowButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetUid != widget.targetUid) {
      _following = null;
      _load();
    }
  }

  Future<void> _load() async {
    final v = await FireStoreUtils.isFollowing(widget.targetUid);
    if (!mounted) return;
    setState(() => _following = v);
  }

  Future<void> _toggle() async {
    if (_busy || _following == null) return;
    setState(() => _busy = true);
    final next = !_following!;
    // Optimistic update
    setState(() => _following = next);
    final ok = next
        ? await FireStoreUtils.followUser(widget.targetUid)
        : await FireStoreUtils.unfollowUser(widget.targetUid);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!ok) _following = !next; // revert on failure
    });
    if (ok) widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    // Hide while unauthenticated, self, or first load resolving.
    final myUid = FireStoreUtils.getCurrentUid();
    if (myUid == null || myUid.isEmpty || myUid == widget.targetUid) {
      return const SizedBox.shrink();
    }
    if (_following == null) {
      return SizedBox(
        height: widget.dense ? 28 : 34,
        width: widget.dense ? 28 : 34,
        child: const Center(
          child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.6)),
        ),
      );
    }

    final following = _following!;
    final padH = widget.dense ? 12.0 : 16.0;
    final padV = widget.dense ? 6.0 : 8.0;
    final fontSize = widget.dense ? 12.0 : 13.0;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: _busy ? null : _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
        decoration: BoxDecoration(
          color: following ? Colors.transparent : AppThemeData.primary4,
          border: Border.all(color: AppThemeData.primary4, width: 1.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_busy)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.6,
                  valueColor: AlwaysStoppedAnimation(following ? AppThemeData.primary4 : Colors.white),
                ),
              )
            else
              Icon(
                following ? Icons.check_rounded : Icons.person_add_alt_1,
                size: widget.dense ? 14 : 16,
                color: following ? AppThemeData.primary4 : Colors.white,
              ),
            const SizedBox(width: 6),
            Text(
              following ? 'Following'.tr : 'Follow'.tr,
              style: TextStyle(
                fontSize: fontSize,
                fontFamily: FontFamily.bold,
                color: following ? AppThemeData.primary4 : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
