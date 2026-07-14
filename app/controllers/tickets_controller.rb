class TicketsController < ApplicationController
  before_action :set_ticket, only: %i[show edit update destroy claim resolve reopen]

  def index
    @status_filter   = params[:status]
    @priority_filter = params[:priority]

    @tickets = Ticket
               .includes(:customer, :assigned_to, :tags)
               .by_status(@status_filter)
               .by_priority(@priority_filter)
               .order(created_at: :desc)
               .limit(200)

    @stats = {
      open: Ticket.open.count,
      pending: Ticket.pending.count,
      resolved: Ticket.resolved.count
    }
  end

  def show
    @message = @ticket.messages.new
    @messages = @ticket.messages.includes(:user, :customer).order(:created_at)
  end

  def new
    @ticket = Ticket.new
  end

  def create
    @ticket = Ticket.new(ticket_params)
    initial_body = params.dig(:ticket, :body).to_s

    if @ticket.save
      # Persist initial message as the customer's first reply
      @ticket.messages.create!(
        body: initial_body,
        sender_type: 'customer',
        customer_id: @ticket.customer_id,
        account_id: @ticket.account_id
      )

      TicketClassificationJob.perform_later(@ticket.id)
      redirect_to @ticket, notice: 'Ticket created. AI classification queued.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @ticket.update(ticket_params)
      redirect_to @ticket, notice: 'Ticket updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @ticket.destroy
    redirect_to tickets_path, notice: 'Ticket deleted.'
  end

  # POST /tickets/:id/claim
  def claim
    result = AssignmentService.new(@ticket, current_user).call
    if result.success?
      redirect_to @ticket, notice: 'Ticket claimed.'
    else
      redirect_to @ticket, alert: result.error
    end
  end

  # POST /tickets/:id/resolve
  def resolve
    @ticket.update!(status: 'resolved', resolved_at: Time.current)
    redirect_to @ticket, notice: 'Ticket resolved.'
  end

  # POST /tickets/:id/reopen
  def reopen
    @ticket.update!(status: 'open', resolved_at: nil)
    redirect_to @ticket, notice: 'Ticket reopened.'
  end

  private

  def set_ticket
    @ticket = Ticket.find(params[:id])
  end

  def ticket_params
    params.require(:ticket).permit(
      :subject, :customer_id, :priority, :status, :assigned_to_id,
      tag_ids: []
    )
  end
end
