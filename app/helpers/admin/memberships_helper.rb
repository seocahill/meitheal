module Admin::MembershipsHelper
  PAYMENT_STATUS_BADGES = {
    paid: [ "Paid", "bg-green-100 text-green-800" ],
    lapsed: [ "Lapsed", "bg-red-100 text-red-800" ],
    unpaid: [ "Unpaid", "bg-rose-100 text-rose-800" ]
  }.freeze

  # Paid, lapsed, unpaid, or a plain "No fee" for associates.
  def payment_status_badge(membership)
    status = membership.payment_status
    label, colours = PAYMENT_STATUS_BADGES[status]

    if label
      tag.span label, class: "px-2 inline-flex text-xs leading-5 font-semibold rounded-full #{colours}", data: { payment_status: status }
    else
      tag.span "No fee", class: "text-xs text-gray-400", data: { payment_status: status }
    end
  end
end
