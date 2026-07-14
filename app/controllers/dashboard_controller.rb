class DashboardController < ApplicationController
  def show
    return redirect_to root_path, alert: 'No workspace in context.' unless Current.account

    @analytics    = AnalyticsQuery.new(account_id: Current.account.id)
    @response_q   = @analytics.average_response_time_per_agent
    @sentiment_q  = @analytics.sentiment_trend_by_week
    @tags_q       = @analytics.top_tags(limit: 10)

    @open_count     = Ticket.open.count
    @resolved_count = Ticket.resolved.count
    @pending_count  = Ticket.pending.count
  end
end
