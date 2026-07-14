# All SQL queries that power the analytics dashboard.
#
# Every public method takes `account_id` as the **first positional argument**
# and embeds it via parameterized binding — never string interpolation — so
# data leakage between tenants is impossible even if the caller passes the
# wrong account by mistake.
#
# Supports both PostgreSQL (full SQL with LATERAL, window functions) and
# SQLite3 (simplified fallback without LATERAL) transparently.
class AnalyticsQuery
  Result = Struct.new(:rows, :columns, keyword_init: true)

  def initialize(account_id:)
    @account_id = account_id
    raise ArgumentError, 'account_id required' if @account_id.blank?
  end

  # 1) Average response time per agent.
  #    "Response" = first agent reply after each ticket creation, in hours.
  def average_response_time_per_agent
    sql = if postgres?
            avg_response_time_sql
          else
            avg_response_time_sql_sqlite
          end

    rows = ActiveRecord::Base.connection.exec_query(
      ActiveRecord::Base.sanitize_sql_array([sql, { account_id: @account_id }])
    ).to_a

    Result.new(rows: rows, columns: %w[agent_name avg_response_hours tickets_handled])
  end

  # 2) Sentiment trend by week (window function: weekly avg + 4-week moving avg).
  def sentiment_trend_by_week
    sql = if postgres?
            sentiment_sql_postgres
          else
            sentiment_sql_sqlite
          end

    rows = ActiveRecord::Base.connection.exec_query(
      ActiveRecord::Base.sanitize_sql_array([sql, { account_id: @account_id }])
    ).to_a

    Result.new(rows: rows, columns: %w[week avg_sentiment moving_avg_4w ticket_count])
  end

  # 3) Top tags by usage within the account.
  def top_tags(limit: 10)
    sql = <<~SQL
      SELECT
        tg.id    AS tag_id,
        tg.name  AS tag_name,
        tg.color AS tag_color,
        COUNT(tt.ticket_id) AS usage_count
      FROM tags tg
      LEFT JOIN ticket_tags tt ON tt.tag_id = tg.id AND tt.account_id = :account_id
      WHERE tg.account_id = :account_id
      GROUP BY tg.id, tg.name, tg.color
      HAVING COUNT(tt.ticket_id) > 0
      ORDER BY usage_count DESC, tg.name ASC
      LIMIT :lim
    SQL

    rows = ActiveRecord::Base.connection.exec_query(
      ActiveRecord::Base.sanitize_sql_array([sql, { account_id: @account_id, lim: limit }])
    ).to_a

    Result.new(rows: rows, columns: %w[tag_name usage_count tag_color])
  end

  private

  def postgres?
    ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
  end

  # ---- PostgreSQL (full LATERAL + window functions) ----

  def avg_response_time_sql
    <<~SQL
      SELECT
        u.id                                AS user_id,
        u.name                              AS agent_name,
        AVG(EXTRACT(EPOCH FROM (first_reply.first_reply_at - t.created_at)) / 3600.0) AS avg_response_hours,
        COUNT(t.id)                         AS tickets_handled
      FROM users u
      LEFT JOIN tickets t
        ON t.assigned_to_id = u.id
       AND t.account_id     = :account_id
       AND t.first_response_at IS NOT NULL
      LEFT JOIN LATERAL (
        SELECT MIN(tm.created_at) AS first_reply_at
        FROM ticket_messages tm
        WHERE tm.ticket_id    = t.id
          AND tm.account_id   = :account_id
          AND tm.sender_type  = 'agent'
      ) AS first_reply ON TRUE
      WHERE u.account_id = :account_id
        AND u.role       = 'agent'
      GROUP BY u.id, u.name
      HAVING COUNT(t.id) > 0
      ORDER BY avg_response_hours ASC NULLS LAST
    SQL
  end

  def sentiment_sql_postgres
    <<~SQL
      WITH weekly AS (
        SELECT
          date_trunc('week', t.created_at)::date AS week,
          AVG(t.sentiment_score)                 AS avg_sentiment,
          COUNT(*)                               AS ticket_count
        FROM tickets t
        WHERE t.account_id      = :account_id
          AND t.sentiment_score IS NOT NULL
        GROUP BY 1
      )
      SELECT
        week,
        avg_sentiment,
        ticket_count,
        AVG(avg_sentiment) OVER (
          ORDER BY week
          ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
        ) AS moving_avg_4w
      FROM weekly
      ORDER BY week ASC
    SQL
  end

  # ---- SQLite3 (fallback without LATERAL / window functions) ----

  def avg_response_time_sql_sqlite
    <<~SQL
      SELECT
        u.id    AS user_id,
        u.name  AS agent_name,
        AVG((julianday(t.first_response_at) - julianday(t.created_at)) * 24.0) AS avg_response_hours,
        COUNT(t.id) AS tickets_handled
      FROM users u
      LEFT JOIN tickets t
        ON t.assigned_to_id = u.id
       AND t.account_id     = :account_id
       AND t.first_response_at IS NOT NULL
      LEFT JOIN (
        SELECT tm.ticket_id, MIN(tm.created_at) AS first_reply_at
        FROM ticket_messages tm
        WHERE tm.account_id  = :account_id
          AND tm.sender_type = 'agent'
        GROUP BY tm.ticket_id
      ) AS fr ON fr.ticket_id = t.id
      WHERE u.account_id = :account_id
        AND u.role       = 'agent'
      GROUP BY u.id, u.name
      HAVING COUNT(t.id) > 0
      ORDER BY avg_response_hours ASC
    SQL
  end

  def sentiment_sql_sqlite
    <<~SQL
      SELECT
        strftime('%Y-%m-%d', date(t.created_at, 'weekday 0', '-6 days')) AS week,
        AVG(t.sentiment_score) AS avg_sentiment,
        COUNT(*) AS ticket_count
      FROM tickets t
      WHERE t.account_id      = :account_id
        AND t.sentiment_score IS NOT NULL
      GROUP BY 1
      ORDER BY week ASC
    SQL
  end
end
