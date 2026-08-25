class MarketingController < ApplicationController
  LANDING_PAGE = Rails.public_path.join("landing", "index.html").freeze

  def home
    render html: File.read(LANDING_PAGE).html_safe, layout: false, content_type: "text/html"
  end
end
