class FaqsController < ApplicationController
  allow_unauthenticated_access

  def index
    @faqs = Faq.active.by_order
  end
end
