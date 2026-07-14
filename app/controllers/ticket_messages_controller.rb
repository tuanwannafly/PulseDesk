class TicketMessagesController < ApplicationController
  before_action :set_ticket

  def create
    @message = @ticket.messages.new(message_params)
    @message.account_id  = Current.account_id
    @message.sender_type = 'agent'
    @message.user_id     = current_user.id

    if @message.save
      # Re-enqueue AI classification when new info arrives
      TicketClassificationJob.perform_later(@ticket.id)
      redirect_to @ticket, notice: 'Reply sent.'
    else
      redirect_to @ticket, alert: @message.errors.full_messages.to_sentence
    end
  end

  private

  def set_ticket
    @ticket = Ticket.unscoped.find(params[:ticket_id])
    raise ActiveRecord::RecordNotFound unless @ticket.account_id == Current.account_id
  end

  def message_params
    params.require(:ticket_message).permit(:body)
  end
end
