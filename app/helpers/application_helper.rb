module ApplicationHelper
  # Returns a page path that respects the current locale.
  # /ga/slug in Irish, /slug in English.
  def localized_page_path(slug)
    I18n.locale == :ga ? ga_page_path(slug) : page_path(slug)
  end

  # Returns the URL for the alternate-language version of the current page.
  # On a page with an Irish translation, links directly to it.
  # Falls back to the other locale's home.
  def alternate_locale_path
    if I18n.locale == :ga
      if params[:slug].present? && Page.exists?(slug: params[:slug], locale: "en")
        page_path(params[:slug])
      else
        root_path
      end
    else
      if params[:slug].present? && Page.exists?(slug: params[:slug], locale: "ga")
        ga_page_path(params[:slug])
      else
        ga_root_path
      end
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
