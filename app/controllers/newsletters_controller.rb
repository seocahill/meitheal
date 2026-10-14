# Public pages for archived newsletters. The list of newsletters is on the
# newsletter page (NewsletterSubscriptionsController).
class NewslettersController < ApplicationController
  allow_unauthenticated_access only: :show

  def show
    @newsletter = Newsletter.sent.find_by(id: params[:id])
    redirect_to newsletter_page_path, alert: "Newsletter not found." unless @newsletter
  end
end
