module ApplicationHelper
  # Pagy pagination helpers
  def pagy_nav(pagy)
    # Simple pagination helper - can be customized later
    return "" if pagy.pages <= 1

    html = %(<nav class="pagination flex justify-center space-x-4 mt-8">)

    if pagy.prev
      html << link_to("&laquo; Previous".html_safe, request.path + "?page=#{pagy.prev}", class: "text-indigo-600 hover:text-indigo-800")
    end

    html << %(<span class="text-gray-600">Page #{pagy.page} of #{pagy.pages}</span>)

    if pagy.next
      html << link_to("Next &raquo;".html_safe, request.path + "?page=#{pagy.next}", class: "text-indigo-600 hover:text-indigo-800")
    end

    html << %(</nav>)
    html.html_safe
  end
end
