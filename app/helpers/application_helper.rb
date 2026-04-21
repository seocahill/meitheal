module ApplicationHelper
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
