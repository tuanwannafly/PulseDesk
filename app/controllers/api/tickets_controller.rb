module Api
  class TicketsController < Api::BaseController
    before_action :set_ticket, only: %i[show claim resolve reopen destroy]

    # GET /api/tickets?status=&priority=
    def index
      scope = Ticket.includes(:customer, :assigned_to, :tags).order(created_at: :desc)
      scope = scope.where(status:   params[:status])   if params[:status].present?
      scope = scope.where(priority: params[:priority]) if params[:priority].present?

      tickets = scope.limit(200).map { |t| ticket_payload(t) }
      stats = {
        open:     Ticket.open.count,
        pending:  Ticket.pending.count,
        resolved: Ticket.resolved.count
      }
      render json: { tickets: tickets, stats: stats }
    end

    # GET /api/tickets/:id
    def show
      render json: ticket_payload(@ticket, include_messages: true)
    end

    # POST /api/tickets
    def create
      body = params.require(:ticket).permit(:subject, :customer_id, :priority, :status).to_h
      ticket = Ticket.new(body)
      ticket.assigned_to ||= current_user

      initial_body = params.dig(:ticket, :body).to_s

      if ticket.save
        if initial_body.present?
          ticket.messages.create!(
            body: initial_body,
            sender_type: 'customer',
            customer_id: ticket.customer_id
          )
        end
        TicketClassificationJob.perform_later(ticket.id)
        render json: ticket_payload(ticket), status: :created
      else
        render json: { error: ticket.errors.full_messages.to_sentence, details: ticket.errors.as_json },
               status: :unprocessable_entity
      end
    end

    # POST /api/tickets/:id/claim
    def claim
      result = AssignmentService.new(@ticket, current_user).call
      if result.success?
        render json: ticket_payload(result.ticket)
      else
        render json: { error: result.error }, status: :conflict
      end
    end

    # POST /api/tickets/:id/resolve
    def resolve
      @ticket.update!(status: 'resolved', resolved_at: Time.current)
      render json: ticket_payload(@ticket)
    end

    # POST /api/tickets/:id/reopen
    def reopen
      @ticket.update!(status: 'open', resolved_at: nil)
      render json: ticket_payload(@ticket)
    end

    # DELETE /api/tickets/:id
    def destroy
      @ticket.destroy
      head :no_content
    end

    private

    def set_ticket
      @ticket = Ticket.unscoped.find(params[:id])
      raise ActiveRecord::RecordNotFound unless @ticket.account_id == Current.account_id
    end

    def ticket_payload(t, include_messages: false)
      h = {
        id:           t.id,
        subject:      t.subject,
        status:       t.status,
        priority:     t.priority,
        ai_summary:   t.ai_summary,
        ai_suggested_priority: t.ai_suggested_priority,
        sentiment_score: t.sentiment_score,
        first_response_at: t.first_response_at,
        resolved_at:  t.resolved_at,
        created_at:   t.created_at,
        escalated_at: t.escalated_at,
        customer:     { id: t.customer_id, name: t.customer&.name, email: t.customer&.email },
        assigned_to:  t.assigned_to ? { id: t.assigned_to.id, name: t.assigned_to.name } : nil,
        tags:         t.tags.map { |tg| { id: tg.id, name: tg.name, color: tg.color } },
        messages_count: t.messages.count
      }
      h[:messages] = t.messages.order(:created_at).map { |m|
        {
          id: m.id,
          sender_type: m.sender_type,
          body: m.body,
          created_at: m.created_at,
          user:     m.user     ? { name: m.user.name }     : nil,
          customer: m.customer ? { name: m.customer.name, email: m.customer.email } : nil
        }
      } if include_messages
      h
    end
  end
end
