import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/models/staff.dart';

class BookingStaffAvatar extends StatefulWidget {
  final Staff? staff;
  final IconData fallbackIcon;
  final double radius;

  const BookingStaffAvatar({
    super.key,
    required this.staff,
    required this.fallbackIcon,
    this.radius = 24,
  });

  @override
  State<BookingStaffAvatar> createState() => _BookingStaffAvatarState();
}

class _BookingStaffAvatarState extends State<BookingStaffAvatar> {
  static const _minimumShimmerDuration = Duration(milliseconds: 350);
  static const _squareAspectRatioTolerance = 0.25;

  String? _activeImageKey;
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;
  Timer? _minimumShimmerTimer;
  bool _minimumShimmerDone = true;
  bool _imageLoaded = false;
  Size? _decodedImageSize;
  Object? _imageError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncImageResolution();
  }

  @override
  void didUpdateWidget(covariant BookingStaffAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncImageResolution();
  }

  @override
  void dispose() {
    _removeImageListener();
    _minimumShimmerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final staff = widget.staff;
    final imageUrl = staff?.avatarUrl?.trim() ?? '';

    if (staff == null) {
      return _AnyStaffAvatar(
        fallbackIcon: widget.fallbackIcon,
        radius: widget.radius,
      );
    }

    if (imageUrl.isEmpty) {
      return _InitialsAvatar(staff: staff, radius: widget.radius);
    }

    _ensureMinimumShimmer('${staff.id}:$imageUrl');

    final size = widget.radius * 2;

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: _buildImageState(staff, imageUrl),
      ),
    );
  }

  Widget _buildImageState(Staff staff, String imageUrl) {
    if (_imageError != null) {
      return _InitialsAvatar(staff: staff, radius: widget.radius);
    }

    if (!_imageLoaded || !_minimumShimmerDone) {
      return _AvatarShimmer(radius: widget.radius);
    }

    final theme = Theme.of(context);
    final isSquare = _isSquareImage(_decodedImageSize);
    final imageSize = isSquare
        ? Size.square(widget.radius * 2)
        : _containedSizeInCircle(_decodedImageSize);

    return ColoredBox(
      color: theme.colorScheme.secondary.withValues(alpha: 0.1),
      child: Center(
        child: SizedBox(
          width: imageSize.width,
          height: imageSize.height,
          child: Image.network(
            imageUrl,
            fit: isSquare ? BoxFit.cover : BoxFit.contain,
            semanticLabel: staff.displayName,
            errorBuilder: (context, error, stackTrace) =>
                _InitialsAvatar(staff: staff, radius: widget.radius),
          ),
        ),
      ),
    );
  }

  void _ensureMinimumShimmer(String imageKey) {
    if (_activeImageKey == imageKey) return;
    _activeImageKey = imageKey;
    _minimumShimmerTimer?.cancel();
    _minimumShimmerDone = false;
    _minimumShimmerTimer = Timer(_minimumShimmerDuration, () {
      if (!mounted || _activeImageKey != imageKey) return;
      setState(() {
        _minimumShimmerDone = true;
      });
    });
  }

  void _syncImageResolution() {
    final staff = widget.staff;
    final imageUrl = staff?.avatarUrl?.trim() ?? '';
    if (staff == null || imageUrl.isEmpty) {
      _removeImageListener();
      _activeImageKey = null;
      _imageLoaded = false;
      _decodedImageSize = null;
      _imageError = null;
      return;
    }

    final imageKey = '${staff.id}:$imageUrl';
    if (_activeImageKey == imageKey && _imageStreamListener != null) return;

    _removeImageListener();
    _activeImageKey = imageKey;
    _imageLoaded = false;
    _decodedImageSize = null;
    _imageError = null;
    _minimumShimmerTimer?.cancel();
    _minimumShimmerDone = false;
    _minimumShimmerTimer = Timer(_minimumShimmerDuration, () {
      if (!mounted || _activeImageKey != imageKey) return;
      setState(() {
        _minimumShimmerDone = true;
      });
    });

    final size = widget.radius * 2;
    final provider = NetworkImage(imageUrl);
    final stream = provider.resolve(
      createLocalImageConfiguration(context, size: Size(size, size)),
    );
    final listener = ImageStreamListener(
      (imageInfo, synchronousCall) {
        if (!mounted || _activeImageKey != imageKey) return;
        setState(() {
          _imageLoaded = true;
          _decodedImageSize = Size(
            imageInfo.image.width.toDouble(),
            imageInfo.image.height.toDouble(),
          );
        });
      },
      onError: (error, stackTrace) {
        if (!mounted || _activeImageKey != imageKey) return;
        setState(() {
          _imageError = error;
        });
      },
    );

    _imageStream = stream;
    _imageStreamListener = listener;
    stream.addListener(listener);
  }

  void _removeImageListener() {
    final stream = _imageStream;
    final listener = _imageStreamListener;
    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }
    _imageStream = null;
    _imageStreamListener = null;
  }

  Size _containedSizeInCircle(Size? sourceSize) {
    final diameter = widget.radius * 2;
    if (sourceSize == null || sourceSize.width <= 0 || sourceSize.height <= 0) {
      final squareSide = diameter / math.sqrt2;
      return Size.square(squareSide);
    }

    final aspectRatio = sourceSize.width / sourceSize.height;
    final height = diameter / math.sqrt((aspectRatio * aspectRatio) + 1);
    final width = height * aspectRatio;
    return Size(width, height);
  }

  bool _isSquareImage(Size? sourceSize) {
    if (sourceSize == null || sourceSize.width <= 0 || sourceSize.height <= 0) {
      return false;
    }
    final aspectRatio = sourceSize.width / sourceSize.height;
    return (aspectRatio - 1).abs() <= _squareAspectRatioTolerance;
  }
}

class _AnyStaffAvatar extends StatelessWidget {
  final IconData fallbackIcon;
  final double radius;

  const _AnyStaffAvatar({required this.fallbackIcon, required this.radius});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      child: Icon(fallbackIcon, color: theme.colorScheme.primary),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final Staff staff;
  final double radius;

  const _InitialsAvatar({required this.staff, required this.radius});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
      child: Text(
        staff.initials,
        style: TextStyle(
          color: theme.colorScheme.secondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _AvatarShimmer extends StatefulWidget {
  final double radius;

  const _AvatarShimmer({required this.radius});

  @override
  State<_AvatarShimmer> createState() => _AvatarShimmerState();
}

class _AvatarShimmerState extends State<_AvatarShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.onSurface.withValues(alpha: 0.08);
    final highlightColor = colorScheme.onSurface.withValues(alpha: 0.16);
    final size = widget.radius * 2;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment(-1.0 + (_controller.value * 2), -0.4),
              end: Alignment(0.2 + (_controller.value * 2), 0.4),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.2, 0.5, 0.8],
            ),
          ),
        );
      },
    );
  }
}
