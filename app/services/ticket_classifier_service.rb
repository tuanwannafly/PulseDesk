require 'faraday'
require 'faraday/retry'
require 'json'

# Calls an external LLM (OpenRouter or Groq) to classify a support ticket.
#
# Returns a Hash with :summary, :sentiment, :priority — or raises
# LLMUnavailableError on transient failure (timeout / 5xx / parse error).
#
# The service is **stateless**; only the ticket is passed in. The caller
# (TicketClassificationJob) decides what to do with the result, so the same
# service can be reused from a console, a rake task, or the dashboard.
class TicketClassifierService
  class LLMUnavailableError < StandardError; end

  SYSTEM_PROMPT = <<~PROMPT.freeze
    You are a customer support triage assistant.
    Given the conversation of a support ticket, output a single JSON object
    with exactly three keys:
      - "summary": a 1-2 sentence plain English summary of the issue
      - "sentiment": a float between -1.0 (very negative) and 1.0 (very positive)
      - "priority": one of "low", "normal", "high", "urgent"
    Output ONLY the JSON object, no markdown fences, no commentary.
  PROMPT

  def initialize(ticket)
    @ticket = ticket
  end

  def call
    return fallback('AI skipped (empty conversation)') if @ticket.messages_text.strip.empty?

    response = http_client.post(chat_endpoint, request_body)
    raise LLMUnavailableError, "HTTP #{response.status}" unless response.success?

    parse_response(response.body)
  rescue Faraday::TimeoutError, Faraday::ConnectionFailed, JSON::ParserError,
         LLMUnavailableError => e
    Rails.logger.warn("[TicketClassifierService] #{e.class}: #{e.message}")
    fallback(e.message)
  end

  private

  def fallback(reason)
    {
      summary: "AI unavailable (#{reason})",
      sentiment: 0.0,
      priority: @ticket.priority || 'normal'
    }
  end

  def chat_endpoint
    case ENV.fetch('LLM_PROVIDER', 'openrouter')
    when 'groq' then 'https://api.groq.com/openai/v1/chat/completions'
    when 'openrouter' then 'https://openrouter.ai/api/v1/chat/completions'
    else raise LLMUnavailableError, 'Unknown LLM_PROVIDER'
    end
  end

  def request_body
    {
      model: ENV.fetch('LLM_MODEL', 'meta-llama/llama-3.1-8b-instruct:free'),
      temperature: 0.2,
      response_format: { type: 'json_object' },
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        { role: 'user',   content: @ticket.messages_text }
      ]
    }
  end

  def http_client
    Faraday.new do |f|
      f.request :retry,
                max: 2,
                interval: 0.5,
                interval_randomness: 0.5,
                backoff_factor: 2,
                exceptions: [Faraday::TimeoutError, Faraday::ConnectionFailed]
      f.headers['Authorization'] = "Bearer #{ENV.fetch('LLM_API_KEY', '')}"
      f.headers['Content-Type']  = 'application/json'
      f.options.timeout      = ENV.fetch('LLM_TIMEOUT', 20).to_i
      f.options.open_timeout = 5
    end
  end

  def parse_response(body)
    outer = body.is_a?(String) ? JSON.parse(body) : body
    inner = JSON.parse(outer.dig('choices', 0, 'message', 'content').to_s)

    {
      summary: inner['summary'].to_s[0, 280],
      sentiment: inner['sentiment'].to_f.clamp(-1.0, 1.0),
      priority: inner['priority'].to_s
    }
  rescue JSON::ParserError => e
    raise LLMUnavailableError, "JSON parse error: #{e.message}"
  end
end
