module ApplicationHelper
  # Returns the path to switch to the other language.
  def switch_locale_path_for_other_language
    switch_locale_path(I18n.locale == :ga ? :en : :ga)
  end

  # Successful SumUp payments from the last 60 days that no payment or ticket
  # here records, newest first, so owners notice money taken but not booked.
  # Nil when the f216 flag is off for the current user.
  def unrecorded_sumup_transactions
    return @unrecorded_sumup_transactions if defined?(@unrecorded_sumup_transactions)

    @unrecorded_sumup_transactions =
      if Flipper.enabled?(:f216_unrecorded_sumup_payments, Current.user)
        SumupTransaction.unmatched.recent.order(occurred_at: :desc)
      end
  end

  # Returns CSS classes for a sidebar nav link, adding active state when
  # the current request matches any of the given controller path prefixes.
  def sidebar_nav_class(*controller_paths)
    active = controller_paths.any? { |p| controller_path.start_with?(p) }
    "sidebar-nav-link#{" sidebar-nav-active" if active}"
  end

  # Returns an inline SVG QR code for the given URL.
  def qr_code_svg(url, size: 6)
    RQRCode::QRCode.new(url).as_svg(
      module_size: size,
      use_path: true,
      standalone: true
    ).html_safe
  end
end
