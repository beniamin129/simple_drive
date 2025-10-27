class DashboardController < ApplicationController
  skip_before_action :authenticate_request!

  def index
    send_file Rails.root.join("public", "ui", "index.html"), type: "text/html; charset=utf-8", disposition: "inline"
  end
end
