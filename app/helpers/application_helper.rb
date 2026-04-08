module ApplicationHelper
  # Returns CSS classes for a sidebar nav link, adding active state when
  # the current request matches any of the given controller path prefixes.
  def sidebar_nav_class(*controller_paths)
    active = controller_paths.any? { |p| controller_path.start_with?(p) }
    "sidebar-nav-link#{" sidebar-nav-active" if active}"
  end
end
