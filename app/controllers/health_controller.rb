class HealthController < ApplicationController
  skip_before_action :authenticate!

  def show
    render json: { status: "ok", database: database_ok? }
  end

  private

  def database_ok?
    ActiveRecord::Base.connection.select_value("select 1") == 1
  rescue StandardError
    false
  end
end
