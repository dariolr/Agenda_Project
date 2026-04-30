enum OnlineBookingVisibilityOption {
  publicVisible('public', true),
  directLink('direct_link', true),
  hidden('hidden', false);

  const OnlineBookingVisibilityOption(this.apiValue, this.isBookableOnline);

  final String apiValue;
  final bool isBookableOnline;

  static OnlineBookingVisibilityOption fromValues({
    String? onlineVisibility,
    bool? isBookableOnline,
  }) {
    switch (onlineVisibility?.trim().toLowerCase()) {
      case 'public':
        return OnlineBookingVisibilityOption.publicVisible;
      case 'direct_link':
        return OnlineBookingVisibilityOption.directLink;
      case 'hidden':
        return OnlineBookingVisibilityOption.hidden;
    }

    return (isBookableOnline ?? true)
        ? OnlineBookingVisibilityOption.publicVisible
        : OnlineBookingVisibilityOption.hidden;
  }
}
