module Api
  class TagsController < Api::BaseController
    before_action :set_tag, only: %i[update destroy]

    # GET /api/tags
    def index
      tags = Tag.left_joins(:tickets).group(:id)
                .order(:name)
                .select('tags.*, COUNT(ticket_tags.ticket_id) AS tickets_count')

      render json: {
        tags: tags.map { |t|
          { id: t.id, name: t.name, color: t.color, tickets_count: t.tickets_count.to_i }
        }
      }
    end

    # POST /api/tags
    def create
      attrs = params.require(:tag).permit(:name, :color)
      tag = Tag.new(attrs)
      if tag.save
        render json: { id: tag.id, name: tag.name, color: tag.color, tickets_count: 0 },
               status: :created
      else
        render json: { error: tag.errors.full_messages.to_sentence }, status: :unprocessable_entity
      end
    end

    # DELETE /api/tags/:id
    def destroy
      @tag.destroy
      head :no_content
    end

    private

    def set_tag
      @tag = Tag.unscoped.find(params[:id])
      raise ActiveRecord::RecordNotFound unless @tag.account_id == Current.account_id
    end
  end
end
