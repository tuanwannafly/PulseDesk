module Api
  class CustomersController < Api::BaseController
    before_action :set_customer, only: %i[show update destroy]

    # GET /api/customers
    def index
      customers = Customer.left_joins(:tickets).group(:id)
                          .order(created_at: :desc).limit(200)
                          .select('customers.*, COUNT(tickets.id) AS tickets_count')

      render json: {
        customers: customers.map { |c|
          { id: c.id, name: c.name, email: c.email, tickets_count: c.tickets_count.to_i }
        }
      }
    end

    # GET /api/customers/:id
    def show
      tickets = @customer.tickets.order(created_at: :desc).limit(50).map { |t|
        { id: t.id, subject: t.subject, status: t.status, priority: t.priority }
      }
      render json: {
        id: @customer.id, name: @customer.name, email: @customer.email, notes: @customer.notes,
        tickets: tickets
      }
    end

    # POST /api/customers
    def create
      attrs = params.require(:customer).permit(:name, :email, :notes)
      c = Customer.new(attrs)
      if c.save
        render json: { id: c.id, name: c.name, email: c.email, tickets_count: 0 }, status: :created
      else
        render json: { error: c.errors.full_messages.to_sentence }, status: :unprocessable_entity
      end
    end

    private

    def set_customer
      @customer = Customer.unscoped.find(params[:id])
      raise ActiveRecord::RecordNotFound unless @customer.account_id == Current.account_id
    end
  end
end
