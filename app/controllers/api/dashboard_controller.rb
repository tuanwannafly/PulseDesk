module Api
  class DashboardController < Api::BaseController
    # GET /api/dashboard
    def index
      account_id = Current.account_id
      raise 'No tenant context' unless account_id

      analytics = AnalyticsQuery.new(account_id: account_id)
      render json: {
        avg_response_time_per_agent: analytics.average_response_time_per_agent.to_h,
        sentiment_trend_by_week:     analytics.sentiment_trend_by_week.to_h,
        top_tags:                    analytics.top_tags(limit: 10).to_h
      }
    end
  end
end
