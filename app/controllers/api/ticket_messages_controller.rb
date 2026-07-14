module Api
  class TicketMessagesController < Api::BaseController
    before_action :set_ticket

    # POST /api/tickets/:ticket_id/messages
    # Body: { body: "..." }
    def create
      body = params[:body].to_s
      if body.strip.empty?
        return render json: { error: 'Body cannot be blank' }, status: :unprocessable_entity
      end

      message = @ticket.messages.new(
        body: body,
        sender_type: 'agent',
        user_id: current_user.id
      )
      if message.save
        TicketClassificationJob.perform_later(@ticket.id)
        render json: {
          id: message.id,
          sender_type: message.sender_type,
          body: message.body,
          created_at: message.created_at,
          user: { name: current_user.name }
        }, status: :created
      else
        render json: { error: message.errors.full_messages.to_sentence }, status: :unprocessable_entity
      end
    end

    private

    def set_ticket
      @ticket = Ticket.unscoped.find(params[:ticket_id])
      raise ActiveRecord::RecordNotFound unless @ticket.account_id == Current.account_id
    end
  end
end
